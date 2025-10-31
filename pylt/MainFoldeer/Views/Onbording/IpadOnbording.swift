import SwiftUI
import StoreKit
import UIKit

struct OnboardingPadView: View {
  var onFinish: () -> Void

  @Environment(\.openURL) private var openURL
  @State private var page: Int = 0 // 0..3

  // Ограничиваем ширину контента на iPad для аккуратного вида
  private let maxContentWidth: CGFloat = 700

  // Линки финального экрана
  private let termsURL   = URL(string: "https://example.com/terms")!
  private let privacyURL = URL(string: "https://example.com/privacy")!

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      VStack(spacing: 20) {
        // --- Картинка ---
        Group {
          switch current.imageMode {
          case .intrinsic:
            // Натуральный размер: НЕ resizable
            Image(current.imageName)
              .renderingMode(.original)
              .padding(.top, 32)
          case .fullWidth:
            // На всю ширину контейнера
            Image(current.imageName)
              .resizable()
              .scaledToFit()
              .frame(maxWidth: .infinity, alignment: .center)
              .padding(.top, 24)
          }
        }
        .frame(maxWidth: maxContentWidth) // центрируем внутри ограничителя

        // --- Тексты ---
        VStack(spacing: 10) {
          Text(current.title)
            .font(.system(size: 28, weight: .bold))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)

          Text(current.subtitle)
            .font(.system(size: 16, weight: .regular))
            .foregroundColor(.white.opacity(0.7))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: maxContentWidth)

        // --- Точки прогресса (всегда 5) ---
        DotsView(total: 5, filledIndex: page)
          .padding(.top, 6)

        Spacer(minLength: 0)

        // --- Кнопка действия ---
        Button {
          withAnimation(.easeInOut) { advance() }
        } label: {
          Text(current.primaryButtonTitle)
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56) // чуть выше на iPad
            .background(
              RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.mainRed)
            )
        }
        .frame(maxWidth: maxContentWidth)
        .padding(.horizontal, 20)
        .padding(.bottom, current.isFinal ? 8 : 28)

        // --- Низ — только на финале ---
        if current.isFinal {
          termsFooter
            .frame(maxWidth: maxContentWidth)
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
      }
    }
    // Крестик на 4-м экране
    .safeAreaInset(edge: .top) {
      if page == 3 {
        ZStack {
          Color.black.opacity(1.0).frame(height: 60)
          HStack {
            Spacer()
            Button {
              withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                onFinish()
              }
            } label: {
              Image(systemName: "xmark.circle.fill")
                .font(.title2)
                .foregroundColor(.mainRed)
            }
            .padding(.trailing, 24)
            .contentShape(Rectangle())
          }
        }
      }
    }
    // Показ рейтинга при переходе на 2-й экран
    .onChange(of: page) { newValue in
      if newValue == 1 { requestAppReview() }
    }
  }

  // MARK: - Content model

  private var current: PageContent {
    switch page {
    case 0:
      return .init(
        imageName: "FirstView",
        imageMode: .intrinsic, // ← натуральный размер
        title: "All TV control\nis in your hands",
        subtitle: "Control the volume, channels,\nand apps with just one touch.",
        primaryButtonTitle: "Let’s start",
        isFinal: false
      )
    case 1:
      return .init(
        imageName: "SecondView",
        imageMode: .fullWidth, // ← на всю ширину
        title: "Full control over\nnavigation and input",
        subtitle: "Navigate through the menu and type\nwith incredible ease.",
        primaryButtonTitle: "Next",
        isFinal: false
      )
    case 2:
      return .init(
        imageName: "ThirdView",
        imageMode: .fullWidth,
        title: "Favorite apps and media\non the big screen",
        subtitle: "Manage applications in a couple\nof clicks from your iPhone",
        primaryButtonTitle: "Continue",
        isFinal: false
      )
    default: // 3
      return .init(
        imageName: "ForthView",
        imageMode: .fullWidth,
        title: "All TV control\nis in your hands",
        subtitle: "Control the volume, channels, and apps\nwith no limits just for $6.99/week",
        primaryButtonTitle: "Continue for $6.99/week",
        isFinal: true
      )
    }
  }

  // MARK: - Footer

  private var termsFooter: some View {
    VStack(spacing: 6) {
      Text("By continue you agree to")
        .font(.footnote)
        .foregroundColor(.white.opacity(0.7))

      HStack(spacing: 6) {
        Button { openURL(termsURL) } label: {
          Text("Terms of Service")
            .font(.footnote.weight(.semibold))
            .foregroundColor(.white)
            .underline()
        }
        Text("and")
          .font(.footnote)
          .foregroundColor(.white.opacity(0.7))
        Button { openURL(privacyURL) } label: {
          Text("Privacy Policy")
            .font(.footnote.weight(.semibold))
            .foregroundColor(.white)
            .underline()
        }
      }
    }
    .multilineTextAlignment(.center)
  }

  // MARK: - Actions

  private func advance() {
    if page < 3 {
      UIImpactFeedbackGenerator(style: .light).impactOccurred()
      page += 1
    } else {
      UIImpactFeedbackGenerator(style: .medium).impactOccurred()
      onFinish()
    }
  }

  private func requestAppReview() {
    if let scene = UIApplication.shared.connectedScenes
      .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
      SKStoreReviewController.requestReview(in: scene)
    } else {
      SKStoreReviewController.requestReview()
    }
  }
}

// MARK: - Models & helpers

private struct PageContent {
  enum ImageMode { case intrinsic, fullWidth }
  let imageName: String
  let imageMode: ImageMode
  let title: String
  let subtitle: String
  let primaryButtonTitle: String
  let isFinal: Bool
}

private struct DotsView: View {
  let total: Int
  let filledIndex: Int
  var body: some View {
    HStack(spacing: 8) {
      ForEach(0..<total, id: \.self) { i in
        Circle()
          .fill(i == filledIndex ? Color.mainRed : Color.white.opacity(0.25))
          .frame(width: 8, height: 8)
      }
    }
    .padding(.vertical, 4)
  }
}

// MARK: - MainRed helper



// MARK: - Preview

#Preview {
  OnboardingPadView { }
    .background(Color.black)
}
