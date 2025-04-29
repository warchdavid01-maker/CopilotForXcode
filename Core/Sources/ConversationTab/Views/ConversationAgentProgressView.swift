
import SwiftUI
import ConversationServiceProvider
import ComposableArchitecture
import Combine
import ChatTab
import ChatService

struct ProgressAgentRound: View {
    let rounds: [AgentRound]
    let chat: StoreOf<Chat>
    
    var body: some View {
        WithPerceptionTracking {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(rounds, id: \.roundId) { round in
                    VStack(alignment: .leading, spacing: 4) {
                        ThemedMarkdownText(text: round.reply, chat: chat)
                        ProgressToolCalls(tools: round.toolCalls ?? [], chat: chat)
                            .padding(.vertical, 8)
                    }
                }
            }
            .foregroundStyle(.secondary)
        }
    }
}

struct ProgressToolCalls: View {
    let tools: [AgentToolCall]
    let chat: StoreOf<Chat>
    
    var body: some View {
        WithPerceptionTracking {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(tools) { tool in
                    if tool.name == ToolName.runInTerminal.rawValue && tool.invokeParams != nil {
                        RunInTerminalToolView(tool: tool, chat: chat)
                    } else {
                        ToolStatusItemView(tool: tool)
                    }
                }
            }
        }
    }
}

struct ToolStatusItemView: View {
    
    let tool: AgentToolCall
    
    @AppStorage(\.chatFontSize) var chatFontSize
    
    var statusIcon: some View {
        Group {
            switch tool.status {
            case .running:
                ProgressView()
                    .controlSize(.small)
                    .scaleEffect(0.7)
            case .completed:
                Image(systemName: "checkmark")
                    .foregroundColor(.green.opacity(0.5))
            case .error:
                Image(systemName: "xmark.circle")
                    .foregroundColor(.red.opacity(0.5))
            case .cancelled:
                Image(systemName: "slash.circle")
                    .foregroundColor(.gray.opacity(0.5))
            case .waitForConfirmation:
                EmptyView()
            }
        }
    }
    
    var progressTitleText: some View {
        let message: String = {
            var msg = tool.progressMessage ?? tool.name
            if tool.name == ToolName.createFile.rawValue {
                if let input = tool.invokeParams?.input, let filePath = input["filePath"]?.value as? String {
                    let fileURL = URL(fileURLWithPath: filePath)
                    msg += ": [\(fileURL.lastPathComponent)](\(fileURL.absoluteString))"
                }
            }
            return msg
        }()

        return Group {
            if let attributedString = try? AttributedString(markdown: message) {
                Text(attributedString)
                    .environment(\.openURL, OpenURLAction { url in
                        if url.scheme == "file" || url.isFileURL {
                            NSWorkspace.shared.open(url)
                            return .handled
                        } else {
                            return .systemAction
                        }
                    })
            } else {
                Text(tool.progressMessage ?? tool.name)
            }
        }
    }
    
    var body: some View {
        WithPerceptionTracking {
            HStack(spacing: 4) {
                statusIcon
                    .frame(width: 16, height: 16)

                progressTitleText
                    .font(.system(size: chatFontSize))
                    .lineLimit(1)
                
                Spacer()
            }
        }
    }
}

struct ProgressAgentRound_Preview: PreviewProvider {
    static let agentRounds: [AgentRound] = [
        .init(roundId: 1, reply: "this is agent step", toolCalls: [
            .init(
                id: "toolcall_001",
                name: "Tool Call 1",
                progressMessage: "Read Tool Call 1",
                status: .completed,
                error: nil),
            .init(
                id: "toolcall_002",
                name: "Tool Call 2",
                progressMessage: "Running Tool Call 2",
                status: .running)
            ])
        ]

    static var previews: some View {
        let chatTabInfo = ChatTabInfo(id: "id", workspacePath: "path", username: "name")
        ProgressAgentRound(rounds: agentRounds, chat: .init(initialState: .init(), reducer: { Chat(service: ChatService.service(for: chatTabInfo)) }))
            .frame(width: 300, height: 300)
    }
}
