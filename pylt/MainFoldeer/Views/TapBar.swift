import SwiftUI

// MARK: - Tabs

enum Tab: Hashable {
  case tvRemote, apps, insights, settings
}


// MARK: - Root

struct ContentView: View {
  @State private var selected: Tab = .tvRemote

  var body: some View {
    TabView(selection: $selected) {
      RemoteView()
        .tabItem {
          Image(systemName: "appletvremote.gen3")
          Text("Remote")
        }
        .tag(Tab.tvRemote)
      
      AppsView()
        .tabItem {
          Image(systemName: "square.grid.2x2")
          Text("Apps")
        }
        .tag(Tab.apps)
      
      InsightsView()
        .tabItem {
          Image(systemName: "text.book.closed")
          Text("Insights")
        }
        .tag(Tab.insights)
      
      SettingsView()
        .tabItem {
          Image(systemName: "gearshape")
          Text("Settings")
        }
        .tag(Tab.settings)
    }
    .accentColor(Color("MainRed")) // цвет активной вкладки из Assets
    .background(Color("Bg").ignoresSafeArea()) // фон из Assets
    .onAppear {
      setupTabBarAppearance()
    }
  }
  
  private func setupTabBarAppearance() {
    let appearance = UITabBarAppearance()
    appearance.configureWithOpaqueBackground()
    
    // Фон таб-бара
    if let bgColor = UIColor(named: "Bg") {
      appearance.backgroundColor = bgColor
    }
    
    // Цвет невыбранных элементов (светло-серый)
    appearance.stackedLayoutAppearance.normal.iconColor = UIColor.lightGray
    appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
      .foregroundColor: UIColor.lightGray
    ]
    
    // Цвет выбранных элементов (MainRed)
    if let mainRedColor = UIColor(named: "MainRed") {
      appearance.stackedLayoutAppearance.selected.iconColor = mainRedColor
      appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
        .foregroundColor: mainRedColor
      ]
    }
    
    UITabBar.appearance().standardAppearance = appearance
    UITabBar.appearance().scrollEdgeAppearance = appearance
  }
}

// MARK: - Placeholder Views







#Preview {
  ContentView()
}
