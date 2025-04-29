import Client
import Foundation
import Logger
import SharedUIComponents
import SwiftUI
import Toast

extension ButtonStyle where Self == BorderedProminentWhiteButtonStyle {
    static var borderedProminentWhite: BorderedProminentWhiteButtonStyle {
        BorderedProminentWhiteButtonStyle()
    }
}

struct BorderedProminentWhiteButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .foregroundColor(colorScheme == .dark ? .white : .primary)
            .background(
                colorScheme == .dark ? Color(red: 0.43, green: 0.43, blue: 0.44) : .white
            )
            .cornerRadius(5)
            .overlay(
                RoundedRectangle(cornerRadius: 5).stroke(.clear, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 0, x: 0, y: 0)
            .shadow(color: .black.opacity(0.3), radius: 1.25, x: 0, y: 0.5)
    }
}

struct CardGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            configuration.label.foregroundColor(.primary)
            configuration.content.foregroundColor(.primary)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color("GroupBoxBackgroundColor"))
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .inset(by: 0.5)
                .stroke(Color("GroupBoxStrokeColor"), lineWidth: 1)
        )
    }
}

struct MCPConfigView: View {
    @State private var mcpConfig: String = ""
    @Environment(\.toast) var toast
    @State private var configFilePath: String = ""
    @State private var isMonitoring: Bool = false
    @State private var lastModificationDate: Date? = nil
    @State private var fileMonitorTask: Task<Void, Error>? = nil
    @State private var copiedToClipboard: Bool = false
    @Environment(\.colorScheme) var colorScheme

    var exampleConfig: String {
        """
        {
            "servers": {
                "my-mcp-server": {
                    "type": "stdio",
                    "command": "my-command",
                    "args": []
                }
            }
        }
        """
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                GroupBox(
                    label: Text("Model Context Protocol (MCP) Configuration")
                        .fontWeight(.bold)
                ) {
                    Text(
                        "MCP is an open standard that connects AI models to external tools. In Xcode, it enhances GitHub Copilot's agent mode by connecting to any MCP server and integrating its tools into your workflow. [Learn More](https://modelcontextprotocol.io/introduction)"
                    )
                }.groupBoxStyle(CardGroupBoxStyle())

                Button {
                    openConfigFile()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Edit Config")
                    }
                }
                .buttonStyle(.borderedProminentWhite)
                .help("Configure your MCP server")

                GroupBox(label: Text("Example Configuration").fontWeight(.bold)) {
                    ZStack(alignment: .topTrailing) {
                        Text(exampleConfig)
                            .font(.system(.body, design: .monospaced))
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                Color(nsColor: .textBackgroundColor).opacity(0.5)
                            )
                            .textSelection(.enabled)
                            .cornerRadius(8)

                        CopyButton {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(exampleConfig, forType: .string)
                        }
                    }
                }.groupBoxStyle(CardGroupBoxStyle())
            }
            .padding(20)
            .onAppear {
                setupConfigFilePath()
                startMonitoringConfigFile()
            }
            .onDisappear {
                stopMonitoringConfigFile()
            }
        }
    }

    private func wrapBinding<T>(_ b: Binding<T>) -> Binding<T> {
        DebouncedBinding(b, handler: refreshConfiguration).binding
    }

    private func setupConfigFilePath() {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
       configFilePath = homeDirectory.appendingPathComponent(".config/github-copilot/xcode/mcp.json").path

        // Create directory and file if they don't exist
        let configDirectory = homeDirectory.appendingPathComponent(".config/github-copilot/xcode")
        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: configDirectory.path) {
            try? fileManager.createDirectory(at: configDirectory, withIntermediateDirectories: true)
        }

        // If the file doesn't exist, create one with a proper structure
        let configFileURL = URL(fileURLWithPath: configFilePath)
        if !fileManager.fileExists(atPath: configFilePath) {
            try? """
            {
                "servers": {
                    
                }
            }
            """.write(to: configFileURL, atomically: true, encoding: .utf8)
        }

        // Read the current content from file and ensure it's valid JSON
        mcpConfig = readAndValidateJSON(from: configFileURL) ?? "{}"

        // Get initial modification date
        lastModificationDate = getFileModificationDate(url: configFileURL)
    }

    /// Reads file content and validates it as JSON, returning only the "servers" object
    private func readAndValidateJSON(from url: URL) -> String? {
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }

        // Try to parse as JSON to validate
        do {
            // First verify it's valid JSON
            let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            // Extract the "servers" object
            guard let servers = jsonObject?["servers"] as? [String: Any] else {
                Logger.client.info("No 'servers' key found in MCP configuration")
                toast("No 'servers' key found in MCP configuration", .error)
                // Return empty object if no servers section
                return "{}"
            }

            // Convert the servers object back to JSON data
            let serversData = try JSONSerialization.data(
                withJSONObject: servers, options: [.prettyPrinted])

            // Return as a string
            return String(data: serversData, encoding: .utf8)
        } catch {
            // If parsing fails, return nil
            Logger.client.info("Parsing MCP JSON error: \(error)")
            toast("Invalid JSON in MCP configuration file", .error)
            return nil
        }
    }

    private func getFileModificationDate(url: URL) -> Date? {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        return attributes?[.modificationDate] as? Date
    }

    private func startMonitoringConfigFile() {
        stopMonitoringConfigFile()  // Stop existing monitoring if any

        isMonitoring = true

        fileMonitorTask = Task {
            let configFileURL = URL(fileURLWithPath: configFilePath)

            // Check for file changes periodically
            while isMonitoring {
                try? await Task.sleep(nanoseconds: 3_000_000_000)  // Check every 3 seconds

                let currentDate = getFileModificationDate(url: configFileURL)

                if let currentDate = currentDate, currentDate != lastModificationDate {
                    // File modification date has changed, update our record
                    lastModificationDate = currentDate

                    // Read and validate the updated content
                    if let validJson = readAndValidateJSON(from: configFileURL) {
                        await MainActor.run {
                            mcpConfig = validJson
                            refreshConfiguration(validJson)
                            toast("MCP configuration file updated", .info)
                        }
                    } else {
                        // If JSON is invalid, show error
                        await MainActor.run {
                            toast("Invalid JSON in MCP configuration file", .error)
                        }
                    }
                }
            }
        }
    }

    private func stopMonitoringConfigFile() {
        isMonitoring = false
        fileMonitorTask?.cancel()
        fileMonitorTask = nil
    }

    private func openConfigFile() {
        let url = URL(fileURLWithPath: configFilePath)
        NSWorkspace.shared.open(url)
    }

    func refreshConfiguration(_: Any) {
        let fileURL = URL(fileURLWithPath: configFilePath)
        if let jsonString = readAndValidateJSON(from: fileURL) {
            UserDefaults.shared.set(jsonString, for: \.gitHubCopilotMCPConfig)
        }

        NotificationCenter.default.post(
            name: .gitHubCopilotShouldRefreshEditorInformation,
            object: nil
        )

        Task {
            let service = try getService()
            do {
                try await service.postNotification(
                    name: Notification.Name
                        .gitHubCopilotShouldRefreshEditorInformation.rawValue
                )
                toast("MCP configuration updated", .info)
            } catch {
                toast(error.localizedDescription, .error)
            }
        }
    }
}

#Preview {
    MCPConfigView()
        .frame(width: 800, height: 600)
}
