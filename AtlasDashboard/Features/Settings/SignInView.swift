import SwiftUI
import WebKit

/// Embedded browser for the dashboard's Google sign-in. Once the dashboard itself
/// loads, the session cookies are copied to URLSession and the sheet closes.
struct SignInView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var webView: WKWebView?
    @State private var isVerifying = false
    @State private var message = "Sign in with your Atlas Google account. The sheet closes on its own once the dashboard loads."

    var body: some View {
        NavigationStack {
            Group {
                if let url = model.baseURL {
                    SignInWebView(url: url, expectedHost: url.host() ?? "") { view in
                        webView = view
                    } onDashboardLoaded: { view in
                        Task { await finish(with: view) }
                    }
                    .ignoresSafeArea(edges: .bottom)
                } else {
                    ContentUnavailableView("No dashboard address", systemImage: "link.badge.plus",
                                           description: Text("Set the server in Settings first."))
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 10) {
                    if isVerifying { ProgressView() }
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .background(.bar)
            }
            .navigationTitle("Sign in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        if let webView { Task { await finish(with: webView) } }
                    }
                    .disabled(webView == nil || isVerifying)
                }
            }
        }
        .interactiveDismissDisabled(isVerifying)
    }

    private func finish(with webView: WKWebView) async {
        guard !isVerifying else { return }
        isVerifying = true
        defer { isVerifying = false }
        if await model.completeSignIn(from: webView) {
            dismiss()
        } else {
            message = "The dashboard hasn't accepted the session yet. Finish signing in, then tap Done."
        }
    }
}

struct SignInWebView: UIViewRepresentable {
    let url: URL
    let expectedHost: String
    let onCreated: (WKWebView) -> Void
    let onDashboardLoaded: (WKWebView) -> Void

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        // Google refuses OAuth in embedded browsers it can identify; a Safari UA keeps
        // the standard sign-in flow working inside WKWebView.
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        webView.load(URLRequest(url: url))
        DispatchQueue.main.async { onCreated(webView) }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(expectedHost: expectedHost, onDashboardLoaded: onDashboardLoaded)
    }

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate {
        let expectedHost: String
        let onDashboardLoaded: (WKWebView) -> Void

        init(expectedHost: String, onDashboardLoaded: @escaping (WKWebView) -> Void) {
            self.expectedHost = expectedHost
            self.onDashboardLoaded = onDashboardLoaded
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard let host = webView.url?.host(), host.lowercased() == expectedHost.lowercased() else { return }
            let path = webView.url?.path() ?? "/"
            // Login-wall pages live under /oauth2 or /cdn-cgi; the real dashboard is anything else.
            guard !path.hasPrefix("/oauth2"), !path.hasPrefix("/cdn-cgi") else { return }
            onDashboardLoaded(webView)
        }
    }
}
