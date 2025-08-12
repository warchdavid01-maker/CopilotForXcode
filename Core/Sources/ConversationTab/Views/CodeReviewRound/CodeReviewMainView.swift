import ComposableArchitecture
import ConversationServiceProvider
import LanguageServerProtocol
import SwiftUI

// MARK: - Main View

struct CodeReviewMainView: View {
    let store: StoreOf<Chat>
    let round: CodeReviewRound 
    @State private var selectedFileUris: [DocumentUri]
    @AppStorage(\.chatFontSize) var chatFontSize
    
    private var changedFileUris: [DocumentUri] { 
        round.request?.changedFileUris ?? []
    }
    
    private var hasChangedFiles: Bool { 
        !changedFileUris.isEmpty 
    }
    
    private var hasFileComments: Bool {
        guard let fileComments = round.response?.fileComments else { return false }
        return !fileComments.isEmpty
    }
    
    static let HelloMessage: String = "Sure, I can help you with that."
    
    public init(store: StoreOf<Chat>, round: CodeReviewRound) {
        self.store = store
        self.round = round
        self.selectedFileUris = round.request?.selectedFileUris ?? []
    }
    
    var helloMessageView: some View {
        Text(Self.HelloMessage)
            .font(.system(size: chatFontSize))
    }
    
    var statusIcon: some View {
        Group {
            switch round.status {
            case .running:
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 16, height: 16)
                    .scaleEffect(0.7)
            case .completed:
                Image(systemName: "checkmark")
                    .foregroundColor(.green)
            case .error:
                Image(systemName: "xmark.circle")
                    .foregroundColor(.red)
            case .cancelled:
                Image(systemName: "slash.circle")
                    .foregroundColor(.gray)
            case .waitForConfirmation:
                EmptyView()
            case .accepted:
                EmptyView()
            }
        }
    }
    
    var statusView: some View {
        Group {
            switch round.status {
            case .waitForConfirmation, .accepted:
                EmptyView()
            default:
                HStack(spacing: 4) {
                    statusIcon
                        .frame(width: 16, height: 16)
                    
                    Text("Running Code Review...")
                        .font(.system(size: chatFontSize))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
        }
    }
    
    var shouldShowHelloMessage: Bool { round.statusHistory.contains(.waitForConfirmation) }
    var shouldShowRunningStatus: Bool { round.statusHistory.contains(.running) }
    
    var body: some View {
        WithPerceptionTracking {
            VStack(alignment: .leading, spacing: 8) {
                if shouldShowHelloMessage {
                    helloMessageView
                }
                
                if hasChangedFiles {
                    FileSelectionSection(
                        store: store,
                        round: round,
                        changedFileUris: changedFileUris,
                        selectedFileUris: $selectedFileUris
                    )
                }
                
                if shouldShowRunningStatus {
                    statusView
                }
                
                if hasFileComments {
                    ReviewResultsSection(store: store, round: round)
                }
                
                if round.status == .completed || round.status == .error {
                    ReviewSummarySection(round: round)
                }
            }
        }
    }
}
