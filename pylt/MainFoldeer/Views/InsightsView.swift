import SwiftUI

// MARK: - Модель

enum Insight: String, CaseIterable, Identifiable {
  case universalLG      = "Universal remote control for LG"
  case noSignalLoss     = "No signal loss with Wi-Fi connection"
  case allRemotes       = "All remotes in one place"
  case saveResources    = "Save your TV resources"
  case perfectImage     = "Perfect image without dust and streaks"

  var id: String { rawValue }

  var navTitle: String {
    // «Insight 1/2/3/4/5» как просили
    let idx = (Self.allCases.firstIndex(of: self) ?? 0) + 1
    return "Insight \(idx)"
  }

  var bodyText: String {
    switch self {
    case .universalLG:
      return """
      Your phone is a universal remote control for LG. \
      Forget about looking for a remote control. Your smartphone is already a powerful remote control for your LG TV. \
      Just download the app, connect to your TV via Wi-Fi and get full control right in your hand.
      """
    case .noSignalLoss:
      return "No signal loss with Wi-Fi connection Unlike infrared remotes (IR), which require direct visibility from the TV, this app uses Wi-Fi. This means you can control your LG even from another room or when the TV is covered by a cabinet.."
    case .allRemotes:
      return "All remotes in one place If you have a media set-top box, soundbar, or other device connected to LG, you can forget about their remotes. By setting up control through the app, you can control your entire entertainment system from one screen.."
    case .saveResources:
      return "Save your TV resources even from a distance Did you accidentally fall asleep in front of the TV? It doesn't matter. Using the remote in your phone, you can easily turn off LG or exit the app without getting out of bed. This is not only convenient, but also prolongs the life of the panel and saves electricity."
    case .perfectImage:
      return "Perfect image without dust and streaks Use only soft microfiber cloths to clean your LG's screen (like for glasses or lenses). No abrasive materials, alcohol or household chemicals — they can damage the anti-glare and oleophobic coating of the screen.."
    }
  }
}

// MARK: - Экран

import SwiftUI

import SwiftUI

struct InsightsView: View {
  @State private var selected: Insight? = nil

  var body: some View {
    ZStack {
      Color("Bg").ignoresSafeArea()

      if let item = selected {
        // ---------- Экран контента (без скролла) ----------
        VStack(spacing: 0) {
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(white: 0.16))
            .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 6)
            .overlay(
              Text(item.bodyText)
                .foregroundStyle(.white)
                .font(.body)
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        // «липкая» шапка с центрированным заголовком и крестиком
        .safeAreaInset(edge: .top) {
          ZStack {
            Color("Bg").opacity(1.0).frame(height: 52)
            HStack {
              Spacer()
              Text(item.navTitle)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.9))
              Spacer()
              Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                  selected = nil
                }
              } label: {
                Image(systemName: "xmark.circle.fill")
                  .font(.title3)
                  .foregroundStyle(Color.mainRed) // ваш MainRed из ассетов
              }
              .padding(.trailing, 16)
              .contentShape(Rectangle())
            }
          }
        }
        // ✅ Анимация появления/ухода карточки
        .transition(.asymmetric(
          insertion: .scale(scale: 0.92).combined(with: .opacity),
          removal: .scale(scale: 0.90).combined(with: .opacity)
        ))

      } else {
        // ---------- Список кнопок ----------
        VStack(spacing: 16) {
          HStack {
            Spacer()
            Text("Insights")
              .font(.title2.weight(.semibold))
              .foregroundStyle(.white)
            Spacer()
          }
          .padding(.top, 24)

          VStack(spacing: 12) {
            ForEach(Insight.allCases) { item in
              Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                  selected = item
                }
              } label: {
                HStack {
                  Text(item.rawValue)
                    .font(.body)
                    .foregroundStyle(.white)
                  Spacer()
                  Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.gray)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                  RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(white: 0.16))
                )
              }
              .buttonStyle(.plain)
            }
          }
          .padding(.horizontal, 16)

          Spacer()
        }
        .transition(.opacity.combined(with: .move(edge: .leading)))
      }
    }
    // Глобальная анимация на переключение состояния
    .animation(.spring(response: 0.35, dampingFraction: 0.9), value: selected)
  }
}
