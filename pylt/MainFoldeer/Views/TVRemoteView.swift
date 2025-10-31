import SwiftUI

struct RemoteView: View {
  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      VStack(spacing: 24) {
        Spacer(minLength: 0)

        // 🔴 Power — 50×50, по центру
        IconButton(asset: "TurnOn", width: 50, height: 50)
          .frame(maxWidth: .infinity)
          .padding(.bottom, 12)

        // 🎬 Hulu / Netflix / YouTube
        HStack(spacing: 20) {
          IconButton(asset: "HuluButton", width: 98, height: 63)
          IconButton(asset: "NetflixButton", width: 98, height: 63)
          IconButton(asset: "YouTubeButton", width: 98, height: 63)
        }

        // 🔘 Центральный круг 248×248
        IconButton(asset: "RoundIpne", width: 248, height: 248)
          .padding(.vertical, 8)

        // 🔹 Ряд 1: четыре кнопки 66×66
        HStack(spacing: 20) {
          IconButton(asset: "1.1", width: 66, height: 66)
          IconButton(asset: "1.2", width: 66, height: 66)
          IconButton(asset: "1.3", width: 66, height: 66)
          IconButton(asset: "1.4", width: 66, height: 66)
        }

        // 🔸 Второй блок с вертикальными парами и длинными боковыми
        HStack(alignment: .top, spacing: 20) {
          // Левая длинная (2.1) — под 1.1
          IconButton(asset: "2.1", width: 66, height: 143)

          // Средние колонки
          VStack(spacing: 11) {
            IconButton(asset: "2.2", width: 66, height: 66)
            IconButton(asset: "3.2", width: 66, height: 66)
          }

          VStack(spacing: 11) {
            IconButton(asset: "2.3", width: 66, height: 66)
            IconButton(asset: "3.3", width: 66, height: 66)
          }

          // Правая длинная (2.4) — под 1.4
          IconButton(asset: "2.4", width: 66, height: 143)
        }

        Spacer(minLength: 0)
      }
      .frame(maxWidth: .infinity, alignment: .center)
      .padding(.vertical, 24)
      .padding(.bottom, 56 + 12)
    }
  }
}

// MARK: - Универсальная кнопка с фиксированным размером

private struct IconButton: View {
  let asset: String
  let width: CGFloat
  let height: CGFloat
  var action: (() -> Void)? = nil

  var body: some View {
    Button(action: { action?() }) {
      Image(asset)
        .resizable()
        .renderingMode(.original)
        .scaledToFit()
        .frame(width: width, height: height)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}

// MARK: - Preview

#Preview {
  RemoteView()
}
