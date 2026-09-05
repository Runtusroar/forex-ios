import SwiftUI

struct SettingsView: View {
    @Bindable var settings: AppSettings
    @State private var connectionMessage: String?
    @State private var isTesting = false
    @State private var lastCheckedAt: Date?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    PageHeader(title: "Settings", subtitle: "", date: nil)
                    VStack(alignment: .leading, spacing: EditorialSpacing.section) {
                        VStack(alignment: .leading, spacing: 16) {
                            sectionTitle("Connection")
                            VStack(alignment: .leading, spacing: 8) {
                                fieldLabel("Server address")
                                TextField("https://api.juezhou.cc", text: $settings.baseURLText)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .keyboardType(.URL)
                                    .modifier(SettingsInputStyle())
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                fieldLabel("Private API key")
                                SecureField(settings.hasStoredAPIKey ? "API key already saved" : "API key", text: $settings.apiKeyText)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .modifier(SettingsInputStyle())
                            }
                            Text("Your API key is stored in this iPhone’s Keychain. Kimi credentials stay on the server.")
                                .font(.footnote)
                                .foregroundStyle(EditorialTheme.mutedInk)
                                .lineSpacing(3)
                        }
                        VStack(alignment: .leading, spacing: 12) {
                            Button("Save settings", action: save)
                                .buttonStyle(FlatActionStyle(primary: true))
                            Button {
                                Task { await testConnection() }
                            } label: {
                                HStack(spacing: 10) {
                                    Text("Test connection")
                                }
                            }
                            .buttonStyle(FlatActionStyle())
                            .disabled(isTesting)
                            if settings.hasStoredAPIKey {
                                Button("Remove API key", role: .destructive, action: removeKey)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(EditorialTheme.negative)
                                    .frame(maxWidth: .infinity, minHeight: 44)
                            }
                            if let lastCheckedAt {
                                Text("Last checked " + EditorialDateFormatter.timestamp(lastCheckedAt))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(EditorialTheme.mutedInk)
                            }
                            if let message = connectionMessage ?? settings.message {
                                Text(message)
                                    .font(.subheadline)
                                    .lineSpacing(3)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(14)
                                    .background(EditorialTheme.subtleSurface)
                                    .accessibilityLabel("Connection status: " + message)
                            }
                        }
                        VStack(alignment: .leading, spacing: EditorialSpacing.content) {
                            sectionTitle("Refresh")
                            LabeledContent("Calendar & news", value: "Every 30 seconds")
                            LabeledContent("Contracts", value: "Every 5 seconds")
                            LabeledContent("In background", value: "Paused")
                        }
                        .font(.subheadline)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, EditorialSpacing.related)
                    .padding(.bottom, EditorialSpacing.section)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .foregroundStyle(EditorialTheme.ink)
            .tint(EditorialTheme.accent)
            .background(EditorialTheme.paper.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title).font(.headline).accessibilityAddTraits(.isHeader)
    }

    private func fieldLabel(_ label: String) -> some View {
        Text(label).font(.subheadline).foregroundStyle(EditorialTheme.mutedInk)
    }

    private func save() {
        do {
            try settings.save()
            connectionMessage = "Settings saved."
        } catch {
            connectionMessage = (error as? LocalizedError)?.errorDescription ?? "Unable to save settings."
        }
    }

    private func removeKey() {
        do {
            try settings.removeKey()
            connectionMessage = "API key removed."
        } catch {
            connectionMessage = "Unable to remove the API key."
        }
    }

    @MainActor
    private func testConnection() async {
        do {
            try settings.save()
            isTesting = true
            defer { isTesting = false }
            let credentials = try settings.credentials()
            let status = try await APIClient(
                baseURL: credentials.baseURL,
                apiKey: credentials.apiKey
            ).status()
            lastCheckedAt = Date()
            connectionMessage = "Connected — \(status.status), translation: \(status.model)"
        } catch {
            isTesting = false
            connectionMessage = (error as? LocalizedError)?.errorDescription ?? "Connection failed."
        }
    }
}


private struct SettingsInputStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.body)
            .padding(.horizontal, 12)
            .padding(.vertical, EditorialSpacing.content)
            .frame(minHeight: 48)
            .background(EditorialTheme.subtleSurface, in: RoundedRectangle(cornerRadius: 3))
            .overlay { RoundedRectangle(cornerRadius: 3).stroke(EditorialTheme.rule, lineWidth: 1) }
    }
}
