import SwiftUI

#if !canImport(XCTest)
@main
struct PodMonstersApp: App {
    var body: some Scene {
        WindowGroup {
            DashboardView()
        }
    }
}
#else
struct PodMonstersApp: App {
    var body: some Scene {
        WindowGroup {
            DashboardView()
        }
    }
}
#endif

