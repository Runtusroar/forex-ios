import SwiftUI

struct SettingsView: View {
    @Bindable var settings: AppSettings
    @State private var connectionMessage: String?
    @State private var isTesting = false

    var body: some View {
        NavigationStack {
            ZStack {
                EditorialTheme.paper.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        EditorialMasthead(section: "Settings")

                        VStack(alignment: .leading, spacing: 16) {
                            sectionTitle("Backend")
                            fieldLabel("Server address")
                    TextField("https://api.juezhou.cc", text: $settings.baseURLText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                                .font(.body.monospaced())
                                .padding(.vertical, 8)
                                .overlay(alignment: .bottom) { EditorialRule() }

                            fieldLabel("Private API key")
                    SecureField(
                        settings.hasStoredAPIKey ? "API key already saved" : "API key",
                        text: $settings.apiKeyText
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                            .font(.body.monospaced())
                            .padding(.vertical, 8)
                            .overlay(alignment: .bottom) { EditorialRule() }

                            Text("The API key stays in this iPhone's Keychain. Kimi credentials remain on the server.")
                                .font(.footnote)
                                .foregroundStyle(EditorialTheme.mutedInk)
                                .lineSpacing(3)
                        }

                        VStack(alignment: .leading, spacing: 0) {
                            sectionTitle("Actions")
                            Button { save() } label: { actionRow("Save settings") }
                            .buttonStyle(.plain)
                    Button {
                        Task { await testConnection() }
                    } label: {
                                actionRow("Test connection", isLoading: isTesting)
                    }
                            .buttonStyle(.plain)
                    .disabled(isTesting)
                    if settings.hasStoredAPIKey {
                                Button(role: .destructive) { removeKey() } label: {
                                    actionRow("Remove API key", destructive: true)
                                }
                                .buttonStyle(.plain)
                            }
                    }

                if let message = connectionMessage ?? settings.message {
                            VStack(alignment: .leading, spacing: 12) {
                                sectionTitle("Status")
                                HStack(alignment: .top, spacing: 12) {
                                    Rectangle()
                                        .fill(EditorialTheme.accent)
                                        .frame(width: 3)
                                    Text(message)
                                        .font(.subheadline)
                                        .foregroundStyle(EditorialTheme.ink)
                                }
                                .padding(.vertical, 4)
                            }
                }

                        VStack(alignment: .leading, spacing: 0) {
                            sectionTitle("Refresh")
                            infoRow("While app is open", value: "Every 30 seconds")
                            infoRow("In background", value: "Paused")
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 36)
                }
            }
            .toolbarBackground(EditorialTheme.paper, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(EditorialTheme.smallCaps)
                .tracking(1.2)
                .foregroundStyle(EditorialTheme.accent)
            EditorialRule(weight: .strong)
        }
    }

    private func fieldLabel(_ label: String) -> some View {
        Text(label.uppercased())
            .font(EditorialTheme.smallCaps)
            .tracking(0.8)
            .foregroundStyle(EditorialTheme.mutedInk)
    }

    private func actionRow(
        _ title: String,
        isLoading: Bool = false,
        destructive: Bool = false
    ) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.body.weight(.semibold))
                Spacer()
                if isLoading {
                    ProgressView()
                } else {
                    Image(systemName: "arrow.right")
                }
            }
            .foregroundStyle(destructive ? Color.red : EditorialTheme.ink)
            .padding(.vertical, 15)
            EditorialRule()
        }
        .contentShape(Rectangle())
    }

    private func infoRow(_ title: String, value: String) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .foregroundStyle(EditorialTheme.ink)
                Spacer()
                Text(value)
                    .font(EditorialTheme.metadata)
                    .foregroundStyle(EditorialTheme.mutedInk)
            }
            .padding(.vertical, 14)
            EditorialRule()
        }
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
            connectionMessage = "Connected — \(status.status), translation: \(status.model)"
        } catch {
            isTesting = false
            connectionMessage = (error as? LocalizedError)?.errorDescription ?? "Connection failed."
        }
    }
}
