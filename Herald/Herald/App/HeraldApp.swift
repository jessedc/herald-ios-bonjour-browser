import SwiftUI
import TipKit

@main
struct HeraldApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    if UITestingMode.current.isActive {
                        try? Tips.configure()
                        Tips.hideAllTipsForTesting()
                    } else {
                        try? Tips.configure()
                    }
                }
        }
    }
}
