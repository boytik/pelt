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

struct InsightsView: View {
  @State private var selected: Insight? = nil  

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      if let item = selected {
        // ---------- Экран контента ----------
        VStack(spacing: 16) {
          HStack {
            Spacer()
            Text(item.navTitle)
              .font(.headline)
              .foregroundStyle(.white.opacity(0.9))
            Spacer()
            Button {
              withAnimation(.easeInOut) { selected = nil }
            } label: {
              Image(systemName: "xmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.8))
            }
            .contentShape(Rectangle())
          }
          .padding(.horizontal, 8)

          ScrollView {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
              .fill(Color(white: 0.16))
              .overlay(
                Text(item.bodyText)
                  .foregroundStyle(.white)
                  .padding(18)
                  .frame(maxWidth: .infinity, alignment: .leading)
              )
          }
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .transition(.opacity.combined(with: .move(edge: .trailing)))
      } else {
        // ---------- Список кнопок ----------
        VStack(alignment: .leading, spacing: 16) {
          Text("Insights")
            .font(.title2.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 4)

          VStack(spacing: 12) {
            ForEach(Insight.allCases) { item in
              Button {
                withAnimation(.easeInOut) { selected = item }
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
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .transition(.opacity.combined(with: .move(edge: .leading)))
      }
    }
  }
}

#Preview {
  InsightsView()
}
