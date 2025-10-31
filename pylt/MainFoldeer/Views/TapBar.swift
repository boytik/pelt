import SwiftUI

// MARK: - Tabs

enum Tab: Hashable {
  case tvRemote, apps, insights, settings
}

struct TabItem: Identifiable, Hashable {
  let id = UUID()
  let tab: Tab
  let title: String
  let systemImage: String
}

private let tabs: [TabItem] = [
  .init(tab: .tvRemote, title: "Remote", systemImage: "appletvremote.gen3"),
  .init(tab: .apps,     title: "Apps",      systemImage: "square.grid.2x2"),
  .init(tab: .insights, title: "Insights",  systemImage: "text.book.closed"),
  .init(tab: .settings, title: "Settings",  systemImage: "gearshape")
]

// MARK: - Root

struct ContentView: View {
  @State private var selected: Tab = .tvRemote

  var body: some View {
    ZStack(alignment: .bottom) {
      // Контент вкладок
      Group {
        switch selected {
        case .tvRemote: RemoteView()
        case .apps:     AppsView()
        case .insights: InsightsView()
        case .settings: SettingsView()
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color.black.edgesIgnoringSafeArea(.all))

      // Кастомный таб-бар
      CustomTabBar(selected: $selected, items: tabs)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
    .background(Color.black)
    .ignoresSafeArea(.keyboard)
  }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
  @Binding var selected: Tab
  let items: [TabItem]

  var body: some View {
    HStack(spacing: 24) {
      ForEach(items) { item in
        Button {
          selected = item.tab
        } label: {
          VStack(spacing: 6) {
            Image(systemName: item.systemImage)
              .font(.system(size: 18, weight: .regular))
            Text(item.title)
              .font(.footnote)
          }
          .frame(maxWidth: .infinity)
          .foregroundStyle(selected == item.tab ? Color.red : Color.gray)
          .contentShape(Rectangle())
          .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.horizontal, 12)
    .background(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(Color(white: 0.12)) // тёмная плашка как на скрине
        .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: -2)
    )
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
  }
}

// MARK: - Placeholder Views







#Preview {
  ContentView()
}
