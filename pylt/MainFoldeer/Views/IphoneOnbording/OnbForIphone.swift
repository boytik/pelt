import SwiftUI
import StoreKit
import UIKit

// MARK: - Public API

struct OnboardingView: View {
  var onFinish: () -> Void

  @Environment(\.openURL) private var openURL
  @State private var page: Int = 0 // 0..3

  // Линки для финального экрана
  private let termsURL   = URL(string: "https://example.com/terms")!
  private let privacyURL = URL(string: "https://example.com/privacy")!

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      VStack(spacing: 20) {
        // Картинка
          // Картинка — во всю ширину + обрезаем внутренние поля (если есть)
          Image(current.imageName)
            .resizable()
            .scaledToFit()                           // сохраняем пропорции
            .frame(maxWidth: .infinity, alignment: .center)
            .modifier(CropTransparentPadding(horizontal: 24, vertical: 0)) // ← подстрой!
            .padding(.top, 24)



        // Заголовок (жирный, белый, 28)
        Text(current.title)
          .font(.system(size: 28, weight: .bold))
          .foregroundColor(.white)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)

        // Подзаголовок (серый, 16)
        Text(current.subtitle)
          .font(.system(size: 16, weight: .regular))
          .foregroundColor(.white.opacity(0.7))
          .multilineTextAlignment(.center)
          .padding(.horizontal, 24)
          .fixedSize(horizontal: false, vertical: true)

        // 5 точек (активная = текущей странице)
        DotsView(total: 5, filledIndex: page)
          .padding(.top, 6)

        Spacer(minLength: 0)

        // Кнопка действия: full width, MainRed, radius 12
        Button {
          withAnimation(.easeInOut) { advance() }
        } label: {
          Text(current.primaryButtonTitle)
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
              RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.mainRed)
            )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, current.isFinal ? 8 : 24)

        // Низ — только на финале
        if current.isFinal {
          termsFooter
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
      }
    }
    // Крестик на 4-м экране
    .safeAreaInset(edge: .top) {
      if page == 3 {
        ZStack {
          Color.black.opacity(1.0).frame(height: 52)
          HStack {
            Spacer()
            Button {
              withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                onFinish()
              }
            } label: {
              Image(systemName: "xmark.circle.fill")
                .font(.title3)
                .foregroundColor(.mainRed)
            }
            .padding(.trailing, 16)
            .contentShape(Rectangle())
          }
        }
      }
    }
    // Показ оценки при переходе на 2-й экран
    .onChange(of: page) { newValue in
      if newValue == 1 { requestAppReview() }
    }
  }

  // MARK: - Content model for current page

  private var current: PageContent {
    switch page {
    case 0:
      return .init(
        imageName: "FirstOnb",
        title: "All TV control\nis in your hands",
        subtitle: "Control the volume, channels,\nand apps with just one touch.",
        primaryButtonTitle: "Let’s start",
        isFinal: false
      )
    case 1:
      return .init(
        imageName: "SecondOnbUp",
        title: "Full control over\nnavigation and input",
        subtitle: "Navigate through the menu and type\nwith incredible ease.",
        primaryButtonTitle: "Next",
        isFinal: false
      )
    case 2:
      return .init(
        imageName: "ThirdOnb",
        title: "Favorite apps and media\non the big screen",
        subtitle: "Manage applications in a couple\nof clicks from your iPhone",
        primaryButtonTitle: "Continue",
        isFinal: false
      )
    default: // 3
      return .init(
        imageName: "ForthOnb",
        title: "All TV control\nis in your hands",
        subtitle: "Control the volume, channels, and apps\nwith no limits just for $6.99/week",
        primaryButtonTitle: "Continue for $6.99/week",
        isFinal: true
      )
    }
  }

  // MARK: - Footer (final page)

  private var termsFooter: some View {
    VStack(spacing: 6) {
      Text("By continue you agree to")
        .font(.footnote)
        .foregroundColor(.white.opacity(0.7))

      HStack(spacing: 6) {
        Button {
          openURL(termsURL)
        } label: {
          Text("Terms of Service")
            .font(.footnote.weight(.semibold))
            .foregroundColor(.white)
            .underline()
        }

        Text("and")
          .font(.footnote)
          .foregroundColor(.white.opacity(0.7))

        Button {
          openURL(privacyURL)
        } label: {
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

  /// Корректный способ вызвать оценку на iOS 14+
  private func requestAppReview() {
    if let scene = UIApplication.shared.connectedScenes
      .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
      SKStoreReviewController.requestReview(in: scene)
    } else {
      SKStoreReviewController.requestReview() // fallback
    }
  }
}
// Обрезает «внутренние» прозрачные поля у растровых ассетов
struct CropTransparentPadding: ViewModifier {
  let horizontal: CGFloat
  let vertical: CGFloat

  init(horizontal: CGFloat = 0, vertical: CGFloat = 0) {
    self.horizontal = max(0, horizontal)
    self.vertical = max(0, vertical)
  }

  func body(content: Content) -> some View {
    content
      .mask(
        Rectangle()
          .padding(.horizontal, horizontal) // положительное значение — меньше маска → кадрируем края
          .padding(.vertical, vertical)
      )
  }
}


// MARK: - Page content model

private struct PageContent {
  let imageName: String
  let title: String
  let subtitle: String
  let primaryButtonTitle: String
  let isFinal: Bool
}

// MARK: - Dots

private struct DotsView: View {
  let total: Int
  let filledIndex: Int // 0..n-1

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
