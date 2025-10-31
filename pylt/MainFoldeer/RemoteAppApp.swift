import SwiftUI

@main
struct TasteCoreApp: App {
  var body: some Scene {
    WindowGroup {
//        OnboardingView(onFinish: {})
        ContentView()
    }
  }
}
import SwiftUI

struct RootHost: View {
  @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false

  var body: some View {
    Group {
      if hasSeenOnboarding {
        ContentView()
          .transition(.opacity) // плавный переход
      } else {
        OnboardingView {
          // вызывается из онбординга на финальной кнопке или крестике
          hasSeenOnboarding = true
        }
        .transition(.opacity)
      }
    }
    .animation(.easeInOut(duration: 0.25), value: hasSeenOnboarding)
  }
}
