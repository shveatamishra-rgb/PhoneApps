package app.bhaktiangan.core.audio

import android.annotation.SuppressLint
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Handler
import android.os.Looper
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlin.concurrent.thread
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sqrt

/**
 * Hands-free japa counting, a 1:1 port of the iOS `VoiceJapaCounter` onset detector.
 *
 * Reads the mic with [AudioRecord], measures short-time loudness (RMS), and counts each
 * voiced burst (one mantra repetition separated by a breath). An adaptive noise floor +
 * hysteresis + a refractory window prevent double-counting and room-noise triggers. A
 * short calibration ("chant a few times") learns the devotee's level.
 *
 * Audio is processed live and is NEVER recorded or transmitted, so the Play Data-safety
 * "no data collected" holds. Foreground only. Detection constants mirror iOS and must be
 * tuned on a real device with real chanting.
 */
class VoiceJapaCounter {

    enum class Phase { IDLE, CALIBRATING, LISTENING, PAUSED, DENIED }

    private val _count = MutableStateFlow(0)
    val count: StateFlow<Int> = _count
    private val _phase = MutableStateFlow(Phase.IDLE)
    val phase: StateFlow<Phase> = _phase
    private val _level = MutableStateFlow(0f)
    val level: StateFlow<Float> = _level
    private val _calibProgress = MutableStateFlow(0f)
    val calibProgress: StateFlow<Float> = _calibProgress

    /** 0 (loud clear chanting only) ... 1 (soft murmur). Written on main, read on audio thread. */
    @Volatile var sensitivity: Float = 0.55f
    @Volatile var target: Int = 108

    var onCount: ((Int) -> Unit)? = null
    var onTargetReached: (() -> Unit)? = null

    // Detection state (audio thread only)
    private var noiseFloor = 0.015f
    private var isVoiced = false
    private var lastCountAtMs = 0L
    private var reachedTarget = false

    // Calibration
    private var calibrating = false
    private var calibPeak = 0f
    private var calibStartMs = 0L
    private var calibCompletion: (() -> Unit)? = null

    private val refractoryMs = 340L      // min gap between counts (iOS 0.34s)
    private val floorAdapt = 0.05f
    private val calibDurationMs = 6000L

    @Volatile private var running = false
    private var worker: Thread? = null
    private val main = Handler(Looper.getMainLooper())

    private val sampleRate = 16000
    private val minBuf = AudioRecord.getMinBufferSize(
        sampleRate, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT,
    ).let { if (it <= 0) 4096 else it }

    fun startListening() {
        reachedTarget = false
        beginTap(calibrate = false, onCalibDone = null)
    }

    fun calibrate(onDone: () -> Unit) {
        calibPeak = 0f
        _calibProgress.value = 0f
        beginTap(calibrate = true, onCalibDone = onDone)
    }

    fun pause() { if (_phase.value == Phase.LISTENING) _phase.value = Phase.PAUSED }
    fun resume() { if (_phase.value == Phase.PAUSED) _phase.value = Phase.LISTENING }

    fun stop() {
        running = false
        worker?.join(400)
        worker = null
        if (_phase.value != Phase.DENIED) _phase.value = Phase.IDLE
    }

    fun reset() { _count.value = 0; reachedTarget = false }

    fun adjust(delta: Int) { _count.value = max(0, _count.value + delta) }

    /** QA-only: preload a lifelike listening state for Play screenshots (starts no audio). */
    fun loadDemoState(count: Int, target: Int) {
        this.target = target
        _count.value = count
        _level.value = 0.42f
        _phase.value = Phase.LISTENING
    }

    @SuppressLint("MissingPermission") // caller (screen) requests RECORD_AUDIO before starting
    private fun beginTap(calibrate: Boolean, onCalibDone: (() -> Unit)?) {
        if (running) stop()
        calibrating = calibrate
        calibCompletion = onCalibDone
        val record = try {
            AudioRecord(
                MediaRecorder.AudioSource.MIC, sampleRate,
                AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT, minBuf * 2,
            )
        } catch (t: Throwable) { _phase.value = Phase.DENIED; return }
        if (record.state != AudioRecord.STATE_INITIALIZED) { _phase.value = Phase.DENIED; runCatching { record.release() }; return }

        running = true
        _phase.value = if (calibrate) Phase.CALIBRATING else Phase.LISTENING
        calibStartMs = System.currentTimeMillis()
        val buf = ShortArray(2048)

        worker = thread(name = "voice-japa") {
            try {
                record.startRecording()
                while (running) {
                    if (_phase.value == Phase.PAUSED) { Thread.sleep(60); continue }
                    val n = record.read(buf, 0, buf.size)
                    if (n <= 0) continue
                    process(buf, n)
                }
            } catch (_: Throwable) {
                main.post { if (_phase.value != Phase.DENIED) _phase.value = Phase.DENIED }
            } finally {
                runCatching { record.stop() }
                runCatching { record.release() }
            }
        }
    }

    private fun process(buf: ShortArray, n: Int) {
        var sumSq = 0.0
        for (i in 0 until n) { val s = buf[i] / 32768f; sumSq += (s * s).toDouble() }
        val rms = sqrt(sumSq / n).toFloat()
        val now = System.currentTimeMillis()

        if (calibrating) {
            calibPeak = max(calibPeak, rms)
            val p = min(1f, (now - calibStartMs) / calibDurationMs.toFloat())
            _level.value = min(1f, rms * 10)
            _calibProgress.value = p
            if (p >= 1f) finishCalibration()
            return
        }

        // Adaptive threshold: noise floor + a sensitivity-scaled margin (higher sensitivity
        // => smaller margin => softer chanting still counts).
        val margin = 0.006f + (1 - sensitivity) * 0.055f
        val threshold = noiseFloor + margin
        if (rms < threshold) noiseFloor = (1 - floorAdapt) * noiseFloor + floorAdapt * rms

        var counted = false
        if (!isVoiced && rms > threshold) {
            isVoiced = true
            if (now - lastCountAtMs > refractoryMs) { lastCountAtMs = now; counted = true }
        } else if (isVoiced && rms < threshold * 0.6f) {
            isVoiced = false
        }

        _level.value = min(1f, rms * 10)
        if (counted) {
            val c = _count.value + 1
            _count.value = c
            main.post { onCount?.invoke(c) }
            if (!reachedTarget && c >= target) {
                reachedTarget = true
                main.post { onTargetReached?.invoke() }
            }
        }
    }

    private fun finishCalibration() {
        if (!calibrating) return
        calibrating = false
        running = false
        // Seed the noise floor under a fraction of the measured chant peak so listening
        // starts already tuned to this voice.
        if (calibPeak > 0) noiseFloor = max(0.008f, calibPeak * 0.12f)
        _phase.value = Phase.IDLE
        val done = calibCompletion
        calibCompletion = null
        main.post { done?.invoke() }
    }
}
