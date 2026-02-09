import SwiftUI
import SwiftData

@main
struct SpellingGeniusApp: App {
    var body: some Scene {
        WindowGroup {
            HomeScreen()
        }
        .modelContainer(for: [WordSet.self, WordPair.self, Attempt.self])
    }
}
