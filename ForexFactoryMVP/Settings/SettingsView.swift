import SwiftUI

struct SettingsView: View {
    @Bindable var settings: AppSettings
    @State private var connectionMessage: String?
    @State private var isTesting = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("https://zhenmei.shop", text: $settings.baseURLText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    SecureField(
                        settings.hasStoredAPIKey ? "API key already saved" : "API key",
                        text: $settings.apiKeyText
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                } header: {
                    Text("Backend")
                } footer: {
                    Text("The API key stays in this iPhone's Keychain. Kimi credentials remain on the server.")
                }

                Section {
                    Button("Save") { save() }
                    Button {
                        Task { await testConnection() }
                    } label: {
                        HStack {
                            Text("Test Connection")
                            Spacer()
                            if isTesting { ProgressView() }
                        }
                    }
                    .disabled(isTesting)
                    if settings.hasStoredAPIKey {
                        Button("Remove API Key", role: .destructive) { removeKey() }
                    }
                }

                if let message = connectionMessage ?? settings.message {
                    Section("Status") { Text(message) }
                }

                Section("Refresh") {
                    LabeledContent("While app is open", value: "Every 30 seconds")
                    LabeledContent("In background", value: "Paused")
                }
            }
            .navigationTitle("Settings")
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
