import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        TabView {
            OverviewView()
                .tabItem { Label("Overview", systemImage: "gauge.with.dots.needle.33percent") }
            MissingView()
                .tabItem { Label("Missing", systemImage: "questionmark.square.dashed") }
            SecurityView()
                .tabItem { Label("Security", systemImage: "lock.shield") }
            FleetView()
                .tabItem { Label("Fleet", systemImage: "laptopcomputer") }
            TeamView()
                .tabItem { Label("Team", systemImage: "person.3") }
        }
        .sheet(isPresented: $model.isShowingSignIn) {
            SignInView()
        }
        .sheet(isPresented: $model.isShowingSettings) {
            SettingsView()
        }
    }
}

#if DEBUG
#Preview {
    RootView()
        .environment(AppModel(defaults: .preview))
}
#endif
