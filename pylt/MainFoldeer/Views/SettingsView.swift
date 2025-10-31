import SwiftUI
import StoreKit
import MessageUI
import UIKit

struct SettingsView: View {
  // 🔗 Подставь реальные ссылки и адрес почты
  private let privacyURL   = URL(string: "https://example.com/privacy")!
  private let termsURL     = URL(string: "https://example.com/terms")!
  private let appShareURL  = URL(string: "https://apps.apple.com/app/id000000000")!
  private let feedbackEmail = "support@example.com"

  @Environment(\.openURL) private var openURL
  @State private var showMail = false
  @State private var showShare = false
  @State private var copiedAlert = false

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      VStack(spacing: 16) {
        // Центрированный заголовок
        HStack {
          Spacer()
          Text("Settings")
            .font(.title2.weight(.semibold))
            .foregroundStyle(.white)
          Spacer()
        }
        .padding(.top, 24)

        VStack(spacing: 12) {
          SettingsRow(
            icon: "envelope",
            title: "Feedback",
            iconColor: .mainRed
          ) { feedbackTapped() }

            SettingsRow(
              icon: "star",
              title: "Rate us",
              iconColor: .mainRed
            ) { requestAppReview() }


          SettingsRow(
            icon: "doc.text",
            title: "Privacy Policy",
            iconColor: .mainRed
          ) { openURL(privacyURL) }

          SettingsRow(
            icon: "doc.plaintext",
            title: "Terms of use",
            iconColor: .mainRed
          ) { openURL(termsURL) }

          SettingsRow(
            icon: "square.and.arrow.up",
            title: "Share app",
            iconColor: .mainRed
          ) { showShare = true }
        }
        .padding(.horizontal, 16)

        Spacer()
      }
    }
    // Share sheet
    .sheet(isPresented: $showShare) {
      ActivityView(activityItems: [appShareURL])
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    // Встроенный Mail-композер (если доступен)
    .sheet(isPresented: $showMail) {
      MailView(
        recipients: [feedbackEmail],
        subject: "Feedback",
        body: defaultFeedbackBody()
      )
      .ignoresSafeArea()
    }
    // Алерт при отсутствии почтовых клиентов — скопирован адрес
    .alert("Email copied", isPresented: $copiedAlert) {
      Button("OK", role: .cancel) { }
    } message: {
      Text("No mail app found. The address \(feedbackEmail) has been copied to the clipboard.")
    }
  }
    /// Корректный способ показать системное окно оценки приложения
    private func requestAppReview() {
      if let scene = UIApplication.shared.connectedScenes
          .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
        SKStoreReviewController.requestReview(in: scene)
      } else {
        SKStoreReviewController.requestReview() // fallback на случай отсутствия сцены
      }
    }


  // MARK: - Actions

  private func feedbackTapped() {
    // 1) Встроенный Apple Mail композер
    if MFMailComposeViewController.canSendMail() {
      showMail = true
      return
    }

    // 2) Сторонние клиенты
    let subject = "Feedback"
    let body = defaultFeedbackBody()
    if openThirdPartyMailClients(to: feedbackEmail, subject: subject, body: body) {
      return
    }

    // 3) Фолбэк: копируем адрес и показываем алерт
    UIPasteboard.general.string = feedbackEmail
    copiedAlert = true
  }

  private func defaultFeedbackBody() -> String {
    let app = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "App"
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
    let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "-"
    return """

    Hi team,

    [Write your feedback here]

    —
    App: \(app)
    Version: \(version) (\(build))
    iOS: \(UIDevice.current.systemVersion)
    Device: \(UIDevice.current.model)
    """
  }

  /// Пытается открыть Gmail / Outlook / Spark / Yahoo / mailto.
  /// Вернёт true, если какой-то клиент открыт.
  private func openThirdPartyMailClients(to: String, subject: String, body: String) -> Bool {
    let esc: (String) -> String = {
      $0.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0
    }

    // Порядок — от самых распространённых
    let candidates: [URL?] = [
      // Gmail
      URL(string: "googlegmail://co?to=\(esc(to))&subject=\(esc(subject))&body=\(esc(body))"),
      // Outlook
      URL(string: "ms-outlook://compose?to=\(esc(to))&subject=\(esc(subject))&body=\(esc(body))"),
      // Spark
      URL(string: "readdle-spark://compose?recipient=\(esc(to))&subject=\(esc(subject))&body=\(esc(body))"),
      // Yahoo Mail
      URL(string: "ymail://mail/compose?to=\(esc(to))&subject=\(esc(subject))&body=\(esc(body))"),
      // Стандартный mailto (на случай если кем-то обрабатывается)
      URL(string: "mailto:\(esc(to))?subject=\(esc(subject))&body=\(esc(body))")
    ]

    for url in candidates {
      if let url, UIApplication.shared.canOpenURL(url) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        return true
      }
    }
    return false
  }
}

// MARK: - Row (radius 24, height 52, icon 20x20, без фона у иконки)

private struct SettingsRow: View {
  let icon: String
  let title: String
  let iconColor: Color
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 12) {
        Image(systemName: icon)
          .resizable()
          .scaledToFit()
          .frame(width: 20, height: 20)     // 20×20
          .foregroundStyle(iconColor)

        Text(title)
          .foregroundStyle(.white)
          .font(.body)

        Spacer()

        Image(systemName: "chevron.right")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(.gray)
      }
      .padding(.horizontal, 16)
      .frame(height: 52)                    // высота 52
      .background(
        RoundedRectangle(cornerRadius: 24, style: .continuous) // радиус 24
          .fill(Color(white: 0.16))
      )
    }
    .buttonStyle(.plain)
  }
}

// MARK: - UIKit bridges

private struct ActivityView: UIViewControllerRepresentable {
  let activityItems: [Any]
  let applicationActivities: [UIActivity]? = nil

  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
  }
  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private struct MailView: UIViewControllerRepresentable {
  var recipients: [String] = []
  var subject: String = ""
  var body: String = ""

  func makeUIViewController(context: Context) -> MFMailComposeViewController {
    let vc = MFMailComposeViewController()
    vc.setToRecipients(recipients)
    vc.setSubject(subject)
    vc.setMessageBody(body, isHTML: false)
    vc.mailComposeDelegate = context.coordinator
    return vc
  }

  func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
  func makeCoordinator() -> Coordinator { Coordinator() }

  final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?) {
      controller.dismiss(animated: true)
    }
  }
}

// MARK: - Color helper (MainRed из ассетов с безопасным фолбэком)

extension Color {


  init(_ name: String, bundle: Bundle = .main, default fallback: Color) {
    if let uiColor = UIColor(named: name, in: bundle, compatibleWith: nil) {
      self = Color(uiColor)
    } else {
      self = fallback
    }
  }
}

// MARK: - Preview

#Preview {
  SettingsView()
}
