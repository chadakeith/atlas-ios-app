import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            VisitsView()
                .tabItem { Label("Visits", systemImage: "clock") }

            ClientsView()
                .tabItem { Label("Clients", systemImage: "building.2") }

            DevicesView()
                .tabItem { Label("Devices", systemImage: "laptopcomputer.and.iphone") }
        }
    }
}

#if DEBUG
#Preview {
    RootView()
        .modelContainer(PreviewData.container)
}
#endif
