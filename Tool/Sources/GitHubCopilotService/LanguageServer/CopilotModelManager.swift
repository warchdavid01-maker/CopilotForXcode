import ConversationServiceProvider
import Foundation

public extension Notification.Name {
    static let gitHubCopilotModelsDidChange = Notification
        .Name("com.github.CopilotForXcode.CopilotModelsDidChange")
}

public class CopilotModelManager {
    private static var availableLLMs: [CopilotModel] = []
    
    public static func updateLLMs(_ models: [CopilotModel]) {
        availableLLMs = models.sorted(by: { $0.modelName.lowercased() < $1.modelName.lowercased()})
        NotificationCenter.default.post(name: .gitHubCopilotModelsDidChange, object: nil)
    }

    public static func getAvailableLLMs() -> [CopilotModel] {
        return availableLLMs
    }
    
    public static func getDefaultChatLLM() -> CopilotModel? {
        return availableLLMs.first(where: { $0.isChatDefault })
    }
    
    public static func hasLLMs() -> Bool {
        return !availableLLMs.isEmpty
    }

    public static func clearLLMs() {
        availableLLMs = []
        NotificationCenter.default.post(name: .gitHubCopilotModelsDidChange, object: nil)
    }
}
