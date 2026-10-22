import StreakCelebration
import SwiftUI

@main
struct StreakDemoApp: App {
    var body: some Scene {
        WindowGroup {
            DemoView()
        }
    }
}

/// Plays the celebration on launch; pick a streak and tap Celebrate to watch it again.
struct DemoView: View {
    @State private var streak = 10
    @State private var isCelebrating = true

    var body: some View {
        VStack(spacing: 24) {
            Text("Streak demo")
                .font(.largeTitle.bold())

            Stepper("Streak: \(streak) days", value: $streak, in: 1...365)

            Button("Celebrate") {
                isCelebrating = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(32)
        .fullScreenCover(isPresented: $isCelebrating) {
            StreakCelebrationView(streak: streak) {
                isCelebrating = false
            }
        }
    }
}
