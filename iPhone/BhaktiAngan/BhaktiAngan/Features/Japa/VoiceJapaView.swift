import SwiftUI
import UIKit
import AudioToolbox

/// Voice Japa ships LIVE in v1.2 (owner call, 2026-07-11). The in-app calibration +
/// sensitivity slider let devotees tune detection to their own voice and room; the
/// teaser path below stays for any future gated feature. QA hook: --open-voicejapa.
enum VoiceJapaFeature { static let isLive = true }

/// Hands-free Voice Japa (Pro). The devotee chants; the counter ticks on its own
/// via the microphone, the ring fills, and a chime + haptic sound at the target.
/// Each detected repetition also feeds `appState.dailyJapaCount`, so the daily
/// streak grows exactly as it does with tap counting. Audio never leaves the
/// device. Presented as a full-screen cover from the Japa screen.
struct VoiceJapaView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var loc: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    @StateObject private var counter = VoiceJapaCounter()
    @AppStorage("japaGoal") private var goal = 108
    @AppStorage("voiceJapaCalibrated") private var calibrated = false
    @AppStorage("voiceJapaChime") private var chimeOn = true

    @State private var showCompletion = false

    let choice: MantraChoice

    private var progress: Double { min(Double(counter.count) / Double(max(goal, 1)), 1) }

    var body: some View {
        ZStack {
            AppTheme.paper.ignoresSafeArea()
            VStack(spacing: 20) {
                header
                mantra
                ring
                statusLine
                Spacer(minLength: 0)
                controls
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 16)

            if counter.phase == .calibrating { calibrationOverlay }
            if showCompletion { completionBanner }
        }
        .onAppear {
            counter.target = goal
            UIApplication.shared.isIdleTimerDisabled = true   // keep-awake for eyes-closed japa
            counter.onCount = { _ in
                appState.incrementJapa()
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            }
            counter.onTargetReached = { complete() }
            if ProcessInfo.processInfo.arguments.contains("--voicejapa-demo")
                || ProcessInfo.processInfo.environment["QA_DEMO"] == "1"
                || UserDefaults.standard.bool(forKey: "qaVoiceDemo") {
                counter.loadDemoState(count: 27, target: goal)   // App Store screenshot
            }
        }
        .onChange(of: goal) { _, new in counter.target = new }
        .onDisappear {
            counter.stop()
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    // MARK: - Pieces

    private var header: some View {
        HStack {
            Text(loc.s("Voice Japa", "वाणी जप"))
                .font(.headline).foregroundStyle(AppTheme.plum)
            Spacer()
            Button {
                counter.stop()
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(AppTheme.muted)
            }
        }
    }

    private var mantra: some View {
        VStack(spacing: 6) {
            Text(choice.mantra(loc.lang))
                .font(.title3.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.plum)
            Text(loc.s("Chant aloud. Keep your eyes closed.", "मन से जप करें। आँखें बंद रखें।"))
                .font(.footnote)
                .foregroundStyle(AppTheme.muted)
        }
    }

    private var ring: some View {
        ZStack {
            // Live level pulse behind the ring.
            Circle()
                .fill(AppTheme.marigold.opacity(0.16))
                .scaleEffect(1 + CGFloat(counter.level) * 0.18)
                .animation(.easeOut(duration: 0.12), value: counter.level)
                .frame(width: 250, height: 250)

            Circle().stroke(AppTheme.marigold.opacity(0.2), lineWidth: 15)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(AppTheme.marigold, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.25), value: counter.count)

            VStack(spacing: 4) {
                Text(counter.count.formatted())
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                    .minimumScaleFactor(0.5).lineLimit(1)
                    .foregroundStyle(AppTheme.ink)
                Text(loc.s("of \(goal.formatted())", "\(goal.formatted()) में से"))
                    .font(.headline).foregroundStyle(AppTheme.muted)
            }
        }
        .frame(width: 260, height: 260)
    }

    private var statusLine: some View {
        Group {
            switch counter.phase {
            case .denied:
                Label(loc.s("Microphone access is off. Enable it in Settings to use Voice Japa.",
                            "माइक्रोफ़ोन बंद है। वाणी जप हेतु सेटिंग्स में चालू करें।"),
                      systemImage: "mic.slash.fill")
                    .font(.footnote).foregroundStyle(AppTheme.vermilion)
                    .multilineTextAlignment(.center)
            case .listening:
                Label(loc.s("Listening…", "सुन रहे हैं…"), systemImage: "waveform")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.teal)
            case .paused:
                Text(loc.s("Paused", "रुका हुआ")).font(.subheadline).foregroundStyle(AppTheme.muted)
            default:
                Text(loc.s("Press start, then begin chanting.", "आरंभ दबाएँ, फिर जप शुरू करें।"))
                    .font(.subheadline).foregroundStyle(AppTheme.muted)
            }
        }
        .frame(minHeight: 22)
    }

    private var controls: some View {
        VStack(spacing: 16) {
            // Primary start / pause / resume
            HStack(spacing: 12) {
                Button {
                    counter.adjust(by: -1)
                } label: { stepLabel("minus") }
                    .disabled(counter.count == 0)

                primaryButton

                Button {
                    counter.adjust(by: 1)
                } label: { stepLabel("plus") }
            }

            if counter.phase == .listening || counter.phase == .paused {
                Button {
                    counter.stop()
                    counter.reset()
                } label: {
                    Label(loc.s("End session", "सत्र समाप्त करें"), systemImage: "stop.circle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.muted)
                }
            }

            // Sensitivity
            VStack(spacing: 4) {
                HStack {
                    Text(loc.s("Sensitivity", "संवेदनशीलता")).font(.caption).foregroundStyle(AppTheme.muted)
                    Spacer()
                    Toggle(loc.s("Chime at target", "पूर्ण होने पर ध्वनि"), isOn: $chimeOn)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .tint(AppTheme.teal)
                        .scaleEffect(0.8)
                }
                Slider(value: $counter.sensitivity, in: 0...1)
                    .tint(AppTheme.marigold)
            }
            Text(loc.s("If it miscounts, calibrate again or adjust sensitivity.",
                       "गिनती गलत हो तो पुनः कैलिब्रेट करें या संवेदनशीलता बदलें।"))
                .font(.caption2).foregroundStyle(AppTheme.muted)
                .multilineTextAlignment(.center)
            Button {
                calibrated = false
                start()
            } label: {
                Text(loc.s("Recalibrate", "पुनः कैलिब्रेट करें"))
                    .font(.caption.weight(.semibold)).foregroundStyle(AppTheme.teal)
            }
        }
    }

    @ViewBuilder private var primaryButton: some View {
        switch counter.phase {
        case .listening:
            controlButton(loc.s("Pause", "रोकें"), "pause.fill", AppTheme.plum) { counter.pause() }
        case .paused:
            controlButton(loc.s("Resume", "जारी रखें"), "play.fill", AppTheme.teal) { counter.resume() }
        default:
            controlButton(loc.s("Start", "आरंभ"), "mic.fill", AppTheme.vermilion) { start() }
        }
    }

    private func controlButton(_ title: String, _ icon: String, _ color: Color, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(color, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func stepLabel(_ icon: String) -> some View {
        Image(systemName: icon)
            .font(.headline).foregroundStyle(AppTheme.plum)
            .frame(width: 52, height: 52)
            .background(AppTheme.paper, in: Circle())
            .overlay(Circle().stroke(AppTheme.marigold.opacity(0.4), lineWidth: 1.5))
    }

    private var calibrationOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: "waveform.badge.mic")
                    .font(.system(size: 40)).foregroundStyle(.white)
                Text(loc.s("Learning your rhythm", "आपकी लय सीख रहे हैं"))
                    .font(.title3.bold()).foregroundStyle(.white)
                Text(loc.s("Chant your mantra a few times, at your natural pace.",
                           "अपने मंत्र का कुछ बार, अपनी सहज गति से जप करें।"))
                    .font(.subheadline).foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                ProgressView(value: counter.calibrationProgress)
                    .tint(AppTheme.marigold)
                    .frame(width: 200)
            }
            .padding(30)
        }
        .transition(.opacity)
    }

    private var completionBanner: some View {
        VStack {
            Label(loc.s("Mala complete · \(goal) names 🙏", "माला पूर्ण · \(goal) नाम 🙏"),
                  systemImage: "checkmark.seal.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16).padding(.vertical, 11)
                .background(AppTheme.teal, in: Capsule())
                .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
                .padding(.top, 8)
            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Actions

    private func start() {
        if calibrated {
            counter.startListening()
        } else {
            counter.calibrate {
                calibrated = true
                counter.startListening()
            }
        }
    }

    private func complete() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        if chimeOn { AudioServicesPlaySystemSound(1013) }
        withAnimation { showCompletion = true }
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation { showCompletion = false }
        }
    }
}

/// Informational "coming soon" teaser for Voice Japa, shown from the Japa screen while
/// `VoiceJapaFeature.isLive` is false. Purely informational: it makes no claim of Pro
/// entitlement and offers no action that fails, so it stays clear of App Review 2.3.x/3.1.
struct VoiceJapaTeaserSheet: View {
    @EnvironmentObject private var loc: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [AppTheme.plum, AppTheme.vermilion],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 84, height: 84)
                Image(systemName: "mic.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .padding(.top, 36)

            Text(loc.s("Coming soon", "जल्द आ रहा है"))
                .font(.caption.weight(.bold))
                .tracking(1.6)
                .textCase(.uppercase)
                .foregroundStyle(AppTheme.vermilion)

            Text(loc.s("Voice Japa", "वाणी जप"))
                .font(.title.weight(.bold))
                .foregroundStyle(AppTheme.ink)

            Text(loc.s(
                "Chant aloud and let the app count your mala for you, hands-free. It all happens on your device, and your voice never leaves it. We are perfecting it now, and it will arrive in a future update.",
                "बस मंत्र का उच्चारण करें और ऐप आपकी माला अपने आप गिनेगा, बिना छुए। सब कुछ आपके फोन पर ही होता है, आपकी आवाज़ कहीं नहीं जाती। हम इसे और बेहतर बना रहे हैं, यह जल्द ही एक आगामी अपडेट में आएगा।"))
                .font(.callout)
                .foregroundStyle(AppTheme.ink.opacity(0.75))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 8)

            Spacer(minLength: 8)

            Button { dismiss() } label: {
                Text(loc.s("Got it", "ठीक है"))
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(AppTheme.teal, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(28)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
