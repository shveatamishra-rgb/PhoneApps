import MessageUI
import SwiftUI
import UIKit

/// A simple in-app support form. On send it opens the system mail composer
/// pre-filled to support@bhaktiangan.com (topic + the message + device
/// diagnostics), so the email is sent through the devotee's own mail account.
///
/// This deliberately uses the system composer rather than posting to a server,
/// so the app's "no account, no data collected, no tracking" privacy posture
/// stays accurate — nothing is transmitted to our backend. If no mail account
/// is set up, it falls back to a `mailto:` link, then to showing the address.
struct SupportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var loc: LocalizationManager

    static let supportEmail = "support@bhaktiangan.com"

    enum Topic: String, CaseIterable, Identifiable {
        case question = "Question"
        case image = "Report an image"
        case billing = "Subscription & billing"
        case feedback = "Feedback & ideas"
        case other = "Something else"
        var id: String { rawValue }
    }

    @State private var topic: Topic = .question
    @State private var message = ""
    @State private var showMailComposer = false
    @State private var showNoMailAlert = false

    private var trimmedMessage: String {
        message.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        Form {
            Section {
                Picker(loc.s("Topic", "विषय"), selection: $topic) {
                    ForEach(Topic.allCases) { Text(topicLabel($0)).tag($0) }
                }
            } header: {
                Text(loc.s("How can we help?", "हम कैसे सहायता करें?"))
            }

            Section {
                ZStack(alignment: .topLeading) {
                    if trimmedMessage.isEmpty {
                        Text(loc.s("Write your message here…", "अपना संदेश यहाँ लिखें…"))
                            .foregroundStyle(AppTheme.muted)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $message)
                        .frame(minHeight: 160)
                        .scrollContentBackground(.hidden)
                }
            } header: {
                Text(loc.s("Message", "संदेश"))
            } footer: {
                Text(loc.s(
                    "This opens your mail app with everything ready to send to \(Self.supportEmail). We usually reply within 2–3 days.",
                    "यह आपके मेल ऐप को खोलता है, सब कुछ \(Self.supportEmail) पर भेजने के लिए तैयार। हम आमतौर पर 2–3 दिनों में उत्तर देते हैं।"
                ))
            }

            Section {
                Button {
                    sendTapped()
                } label: {
                    Label(loc.s("Compose email", "ईमेल लिखें"), systemImage: "paperplane.fill")
                }
                .disabled(trimmedMessage.isEmpty)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.ivory)
        .navigationTitle(loc.s("Contact Support", "सहायता से संपर्क करें"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showMailComposer) {
            MailComposeView(
                recipients: [Self.supportEmail],
                subject: subject,
                body: composedBody
            ) { sent in
                if sent { dismiss() }
            }
        }
        .alert(loc.s("Set up Mail to send", "भेजने के लिए मेल सेट करें"), isPresented: $showNoMailAlert) {
            Button(loc.s("Copy address", "पता कॉपी करें")) { UIPasteboard.general.string = Self.supportEmail }
            Button(loc.s("OK", "ठीक है"), role: .cancel) {}
        } message: {
            Text(loc.s(
                "No mail account is set up on this device. You can email us directly at \(Self.supportEmail).",
                "इस डिवाइस पर कोई मेल खाता सेट नहीं है। आप हमें सीधे \(Self.supportEmail) पर ईमेल कर सकते हैं।"
            ))
        }
    }

    private func topicLabel(_ topic: Topic) -> String {
        switch topic {
        case .question: return loc.s("Question", "प्रश्न")
        case .image: return loc.s("Report an image", "चित्र की शिकायत")
        case .billing: return loc.s("Subscription & billing", "सदस्यता और बिलिंग")
        case .feedback: return loc.s("Feedback & ideas", "सुझाव और विचार")
        case .other: return loc.s("Something else", "अन्य")
        }
    }

    private var subject: String {
        "[Bhakti Angan] \(topic.rawValue)"
    }

    private var composedBody: String {
        """
        \(message)


        ——————————————
        Sent from Bhakti Angan
        \(Self.diagnostics)
        """
    }

    private static var diagnostics: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        let device = UIDevice.current
        return "App \(version) (\(build)) · iOS \(device.systemVersion) · \(device.model)"
    }

    private func sendTapped() {
        if MFMailComposeViewController.canSendMail() {
            showMailComposer = true
            return
        }
        // No Mail account: hand off to the default mail app via mailto:, then alert.
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = Self.supportEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: composedBody)
        ]
        if let url = components.url, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            dismiss()
        } else {
            showNoMailAlert = true
        }
    }
}

/// UIKit bridge for the system mail composer.
struct MailComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let subject: String
    let body: String
    var onFinish: (_ sent: Bool) -> Void = { _ in }

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setToRecipients(recipients)
        controller.setSubject(subject)
        controller.setMessageBody(body, isHTML: false)
        return controller
    }

    func updateUIViewController(_ controller: MFMailComposeViewController, context: Context) {}

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onFinish: (Bool) -> Void
        init(onFinish: @escaping (Bool) -> Void) { self.onFinish = onFinish }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            controller.dismiss(animated: true)
            onFinish(result == .sent)
        }
    }
}
