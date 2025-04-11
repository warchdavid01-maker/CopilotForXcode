import Foundation
import ChatAPIService
import Persist
import Logger
import ConversationServiceProvider

extension ChatMessage {
    
    struct TurnItemData: Codable {
        var content: String
        var rating: ConversationRating
        var references: [ConversationReference]
        var followUp: ConversationFollowUp?
        var suggestedTitle: String?
        var errorMessage: String?
        var steps: [ConversationProgressStep]
    }
    
    func toTurnItem() -> TurnItem {
        let turnItemData = TurnItemData(
            content: self.content,
            rating: self.rating,
            references: self.references,
            followUp: self.followUp,
            suggestedTitle: self.suggestedTitle,
            errorMessage: self.errorMessage,
            steps: self.steps
        )
        
        // TODO: handle exception
        let encoder = JSONEncoder()
        let encodeData = (try? encoder.encode(turnItemData)) ?? Data()
        let data = String(data: encodeData, encoding: .utf8) ?? "{}"
        
        return TurnItem(id: self.id, conversationID: self.chatTabID, CLSTurnID: self.clsTurnID, role: role.rawValue, data: data, createdAt: self.createdAt, updatedAt: self.updatedAt)
    }
    
    static func from(_ turnItem: TurnItem) -> ChatMessage? {
        var chatMessage: ChatMessage? = nil
                
        do {
            if let jsonData = turnItem.data.data(using: .utf8) {
                let decoder = JSONDecoder()
                let turnItemData = try decoder.decode(TurnItemData.self, from: jsonData)
                
                chatMessage = .init(
                    id: turnItem.id,
                    chatTabID: turnItem.conversationID,
                    clsTurnID: turnItem.CLSTurnID,
                    role: ChatMessage.Role(rawValue: turnItem.role)!,
                    content: turnItemData.content,
                    references: turnItemData.references,
                    followUp: turnItemData.followUp,
                    suggestedTitle: turnItemData.suggestedTitle,
                    errorMessage: turnItemData.errorMessage,
                    rating: turnItemData.rating,
                    steps: turnItemData.steps,
                    createdAt: turnItem.createdAt,
                    updatedAt: turnItem.updatedAt
                )
            }
        } catch {
            Logger.client.error("Failed to restore chat message: \(error)")
        }
        
        return chatMessage
    }
}

extension Array where Element == ChatMessage {
    func toTurnItems() -> [TurnItem] {
        return self.map { $0.toTurnItem() }
    }
}
