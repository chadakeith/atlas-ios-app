import SwiftData
import SwiftUI

@main
struct SiteLogApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [Client.self, Visit.self, Device.self])
    }
}
