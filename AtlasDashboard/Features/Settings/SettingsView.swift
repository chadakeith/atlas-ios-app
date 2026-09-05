import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var serverDraft = ""
    @State private var tokenID = ""
    @State private var tokenSecret = ""
    @State private var isCheckingIdentity = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("https://dashboard.example.com", text: $serverDraft)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onSubmit(saveServer)
                    if serverDraft != model.serverURLString {
                        Button("Use this server", action: saveServer)
                            .disabled(AppModel.normalizeServer(serverDraft) == nil)
                    }
                } header: {
                    Text("Dashboard")
                } footer: {
                    Text("The Atlas dashboard host. Data is read from its JSON endpoints, the same ones the web page uses.")
                }

                Section {
                    if let email = model.accountEmail {
                        LabeledContent("Signed in as", value: email)
                    } else {
                        LabeledContent("Status", value: "Not signed in")
                    }
                    Button("Sign in with Google…", systemImage: "person.badge.key") {
                        model.isShowingSignIn = true
                    }
                    Button("Check connection", systemImage: "antenna.radiowaves.left.and.right") {
                        Task {
                            isCheckingIdentity = true
                            await model.refreshIdentity()
                            isCheckingIdentity = false
                        }
                    }
                    .disabled(isCheckingIdentity)
                    Button("Sign out", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                        Task { await model.signOut() }
                    }
                } header: {
                    Text("Account")
                } footer: {
                    Text("Signing in opens the dashboard's normal Google login. The session cookie stays on this device.")
                }

                Section {
                    TextField("Client ID", text: $tokenID)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(.body, design: .monospaced))
                    SecureField("Client secret", text: $tokenSecret)
                        .font(.system(.body, design: .monospaced))
                    HStack {
                        Button("Save token") {
                            model.serviceToken = ServiceToken(clientID: tokenID.trimmingCharacters(in: .whitespaces),
                                                              clientSecret: tokenSecret.trimmingCharacters(in: .whitespaces))
                            model.serverChanged()
                        }
                        .disabled(tokenID.isEmpty || tokenSecret.isEmpty)
                        Spacer()
                        if model.serviceToken != nil {
                            Button("Remove", role: .destructive) {
                                model.serviceToken = nil
                                tokenID = ""
                                tokenSecret = ""
                                model.serverChanged()
                            }
                        }
                    }
                } header: {
                    Text("Cloudflare Access service token (optional)")
                } footer: {
                    Text("If the dashboard sits behind Cloudflare Access, a service token from Zero Trust → Access → Service Auth lets the app skip the browser sign-in. Stored in the Keychain.")
                }

                Section("About") {
                    LabeledContent("Version", value: Bundle.main.versionLabel)
                    Link("Open dashboard in Safari", destination: model.baseURL ?? URL(string: AppModel.defaultServer)!)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                serverDraft = model.serverURLString
                tokenID = model.serviceToken?.clientID ?? ""
                tokenSecret = model.serviceToken?.clientSecret ?? ""
            }
        }
    }

    private func saveServer() {
        guard let url = AppModel.normalizeServer(serverDraft) else { return }
        model.serverURLString = url.absoluteString
        serverDraft = url.absoluteString
        model.serverChanged()
    }
}

extension Bundle {
    var versionLabel: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "0"
        return "\(version) (\(build))"
    }
}

#if DEBUG
#Preview {
    SettingsView()
        .environment(AppModel(defaults: .preview))
}
#endif
