import ConversationServiceProvider
import JSONRPC

public class RunInTerminalTool: ICopilotTool {
    public func invokeTool(_ request: InvokeClientToolRequest, completion: @escaping (AnyJSONRPCResponse) -> Void, chatHistoryUpdater: ChatHistoryUpdater?, contextProvider: (any ToolContextProvider)?) -> Bool {
        let params = request.params!
        let editAgentRounds: [AgentRound] = [
            AgentRound(roundId: params.roundId,
                       reply: "",
                       toolCalls: [
                        AgentToolCall(id: params.toolCallId, name: params.name, status: .waitForConfirmation, invokeParams: params)
                       ]
                      )
        ]

        if let chatHistoryUpdater = chatHistoryUpdater {
            chatHistoryUpdater(params.turnId, editAgentRounds)
        }

        return false
    }
}
