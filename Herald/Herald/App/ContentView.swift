import SwiftUI
import os

private let logger = Logger(subsystem: "com.herald", category: "ContentView")

enum AppTab: Hashable {
    case allServices, thread, matter, info
}

struct ContentView: View {
    @StateObject private var discoveryEngine = BonjourDiscoveryEngine()
    @State private var selectedTab: AppTab = .allServices
    @Environment(\.scenePhase) private var scenePhase
    private var navigationState = NavigationState.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            AllServicesView(engine: discoveryEngine)
                .tabItem {
                    Label("All Services", systemImage: "list.bullet.rectangle")
                }
                .tag(AppTab.allServices)

            ThreadNetworkView()
                .tabItem {
                    Label("Thread", systemImage: "point.3.connected.trianglepath.dotted")
                }
                .tag(AppTab.thread)

            MatterDeviceView()
                .tabItem {
                    Label("Matter", systemImage: "house")
                }
                .tag(AppTab.matter)

            InfoView()
                .tabItem {
                    Label("Info", systemImage: "info.circle")
                }
                .tag(AppTab.info)
        }
        .onAppear {
            logger.info("ContentView appeared")
            if !discoveryEngine.isScanning {
                discoveryEngine.startFullScan()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                logger.info("Scene entered background — stopping discovery")
                discoveryEngine.stopAll()
            case .active:
                logger.info("Scene became active — restarting discovery")
                discoveryEngine.restartAfterBackground()
                if let tab = navigationState.consumePendingTab() {
                    selectedTab = tab
                }
            case .inactive:
                break
            @unknown default:
                break
            }
        }
    }
}
