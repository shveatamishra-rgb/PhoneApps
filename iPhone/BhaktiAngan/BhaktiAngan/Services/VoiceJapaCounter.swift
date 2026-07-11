import AVFoundation
import Accelerate
import Combine

/// Hands-free japa counting (Voice Japa v1, approach 1 in Docs/VOICE_JAPA.md).
///
/// Taps the microphone with `AVAudioEngine`, measures short-time loudness (RMS),
/// and counts each *utterance burst* (one mantra repetition = one voiced burst
/// separated by a breath). An adaptive noise floor + hysteresis + a refractory
/// window keep it from double-counting syllables or triggering on room noise.
/// A short calibration ("chant 3 times") learns the devotee's level and rhythm.
///
/// Audio is processed live on the device and is **never recorded or transmitted**,
/// so the App Privacy "Data Not Collected" label holds. Foreground only (the
/// devotee is actively chanting), so no background-audio entitlement is needed.
///
/// NOTE: microphone counting cannot be validated in the iOS Simulator (no mic).
/// The detection constants below are sensible defaults that must be tuned on a
/// real device with real chanting.
final class VoiceJapaCounter: ObservableObject {

    enum Phase: Equatable { case idle, calibrating, listening, paused, denied }

    @Published private(set) var count = 0
    @Published private(set) var phase: Phase = .idle
    @Published private(set) var level: Float = 0        // 0...1, for the live meter
    @Published private(set) var calibrationProgress: Double = 0   // 0...1
    /// 0 (only loud, clear chanting) ... 1 (very sensitive, soft murmur). Default mid.
    @Published var sensitivity: Double = 0.55 { didSet { sensSnapshot = Float(sensitivity) } }

    /// Fired on the main thread each time a repetition is counted (for haptics/pulse).
    var onCount: ((Int) -> Void)?
    /// Fired once when `count` first reaches `target`.
    var onTargetReached: (() -> Void)?
    var target: Int = 108

    // MARK: - Audio-thread state (touched only inside the tap callback)
    private let engine = AVAudioEngine()
    private var noiseFloor: Float = 0.015
    private var isVoiced = false
    private var lastCountAt: CFTimeInterval = 0
    private var reachedTarget = false
    private var sensSnapshot: Float = 0.55        // main writes, audio reads (benign)

    // Calibration accumulators
    private var calibrating = false
    private var calibPeak: Float = 0
    private var calibStartAt: CFTimeInterval = 0
    private let calibDuration: CFTimeInterval = 6.0

    // Detection tuning (device-tuned later)
    private let refractory: CFTimeInterval = 0.34   // min seconds between counts
    private let floorAdapt: Float = 0.05            // how fast the noise floor tracks quiet

    var isRunning: Bool { phase == .listening || phase == .calibrating }

    // MARK: - Permission

    /// Requests mic permission and calls back on the main thread.
    func requestPermission(_ done: @escaping (Bool) -> Void) {
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async {
                if !granted { self.phase = .denied }
                done(granted)
            }
        }
    }

    // MARK: - Session lifecycle

    func startListening() {
        requestPermission { ok in
            guard ok else { return }
            self.reachedTarget = false
            self.beginTap(calibrate: false)
            self.phase = .listening
        }
    }

    /// Runs the "chant 3 times" calibration, then calls `completion` on the main thread.
    func calibrate(_ completion: @escaping () -> Void) {
        requestPermission { ok in
            guard ok else { completion(); return }
            self.calibPeak = 0
            self.calibStartAt = CACurrentMediaTime()
            self.calibrationProgress = 0
            self.beginTap(calibrate: true)
            self.phase = .calibrating
            self.calibCompletion = completion
        }
    }
    private var calibCompletion: (() -> Void)?

    func pause() {
        guard phase == .listening else { return }
        engine.pause()
        phase = .paused
    }

    func resume() {
        guard phase == .paused else { return }
        try? engine.start()
        phase = .listening
    }

    func stop() {
        if engine.isRunning || !engine.inputNode.inputFormat(forBus: 0).sampleRate.isZero {
            engine.inputNode.removeTap(onBus: 0)
        }
        engine.stop()
        deactivateSession()
        if phase != .denied { phase = .idle }
    }

    func reset() {
        count = 0
        reachedTarget = false
    }

    func adjust(by delta: Int) {
        count = max(0, count + delta)
    }

    /// QA-only: preload a lifelike listening state for App Store screenshots.
    /// Only ever called behind the --voicejapa-demo launch argument (never in production);
    /// it starts no audio engine, so the sim needs no microphone.
    func loadDemoState(count demoCount: Int, target demoTarget: Int) {
        target = demoTarget
        count = demoCount
        level = 0.42
        phase = .listening
    }

    // MARK: - Engine

    private func beginTap(calibrate: Bool) {
        calibrating = calibrate
        configureSession()
        let input = engine.inputNode
        let format = input.inputFormat(forBus: 0)
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, _ in
            self?.process(buffer)
        }
        engine.prepare()
        do { try engine.start() }
        catch { DispatchQueue.main.async { self.phase = .denied } }
    }

    private func configureSession() {
        let s = AVAudioSession.sharedInstance()
        try? s.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        try? s.setActive(true, options: [])
    }

    private func deactivateSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    // MARK: - Detection (audio thread)

    private func process(_ buffer: AVAudioPCMBuffer) {
        guard let ch = buffer.floatChannelData?[0] else { return }
        let n = vDSP_Length(buffer.frameLength)
        guard n > 0 else { return }

        var meanSquare: Float = 0
        vDSP_measqv(ch, 1, &meanSquare, n)
        let rms = sqrtf(meanSquare)

        let now = CACurrentMediaTime()

        if calibrating {
            calibPeak = max(calibPeak, rms)
            let p = min(1, (now - calibStartAt) / calibDuration)
            DispatchQueue.main.async {
                self.level = min(1, rms * 10)
                self.calibrationProgress = p
                if p >= 1 { self.finishCalibration() }
            }
            return
        }

        // Adaptive threshold from the learned noise floor + a sensitivity-scaled margin.
        // Higher sensitivity => smaller margin => softer chanting still counts.
        let margin = 0.006 + (1 - sensSnapshot) * 0.055
        let threshold = noiseFloor + margin

        // Track the noise floor only while quiet.
        if rms < threshold { noiseFloor = (1 - floorAdapt) * noiseFloor + floorAdapt * rms }

        var counted = false
        if !isVoiced && rms > threshold {
            isVoiced = true
            if now - lastCountAt > refractory {
                lastCountAt = now
                counted = true
            }
        } else if isVoiced && rms < threshold * 0.6 {   // hysteresis: clear well below
            isVoiced = false
        }

        DispatchQueue.main.async {
            self.level = min(1, rms * 10)
            if counted {
                self.count += 1
                self.onCount?(self.count)
                if !self.reachedTarget && self.count >= self.target {
                    self.reachedTarget = true
                    self.onTargetReached?()
                }
            }
        }
    }

    private func finishCalibration() {
        guard calibrating else { return }
        calibrating = false
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        // Seed the noise floor a little under a fraction of the measured chant peak
        // so listening starts already tuned to this voice.
        if calibPeak > 0 { noiseFloor = max(0.008, calibPeak * 0.12) }
        phase = .idle
        let done = calibCompletion
        calibCompletion = nil
        deactivateSession()
        done?()
    }

    deinit {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
    }
}
