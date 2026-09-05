import SwiftUI

enum LoadState<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(Error)

    var value: Value? {
        if case .loaded(let value) = self { return value }
        return nil
    }

    var isLoaded: Bool { value != nil }
}

/// Renders a `LoadState`: spinner, error with retry (or sign-in prompt), or content.
struct RemoteContent<Value, Content: View>: View {
    @Environment(AppModel.self) private var model

    let state: LoadState<Value>
    let retry: () async -> Void
    @ViewBuilder let content: (Value) -> Content

    var body: some View {
        switch state {
        case .idle, .loading:
            ProgressView("Loading…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let error):
            if let apiError = error as? APIError, case .needsSignIn = apiError {
                ContentUnavailableView {
                    Label("Sign in required", systemImage: "person.badge.key")
                } description: {
                    Text("Use your Atlas Google account to reach the dashboard.")
                } actions: {
                    Button("Sign in") { model.isShowingSignIn = true }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                ContentUnavailableView {
                    Label("Couldn't load", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(error.localizedDescription)
                } actions: {
                    Button("Retry") { Task { await retry() } }
                        .buttonStyle(.bordered)
                }
            }
        case .loaded(let value):
            content(value)
        }
    }
}

/// Shared toolbar: settings gear plus a "recompute on server" action.
struct DashboardToolbar: ToolbarContent {
    let recompute: () async -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            DashboardMenu(recompute: recompute)
        }
    }
}

private struct DashboardMenu: View {
    @Environment(AppModel.self) private var model
    let recompute: () async -> Void

    var body: some View {
        Menu {
            Button("Recompute on server", systemImage: "arrow.triangle.2.circlepath") {
                Task { await recompute() }
            }
            Button("Settings", systemImage: "gearshape") {
                model.isShowingSettings = true
            }
        } label: {
            Label("More", systemImage: "ellipsis.circle")
        }
    }
}
