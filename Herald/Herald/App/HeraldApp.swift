import SwiftUI
import TipKit

@main
struct HeraldApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    try? Tips.configure()
                }
        }
    }
}
