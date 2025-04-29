import SwiftUI
import ChatService
import Perception
import ComposableArchitecture
import GitHubCopilotService
import JSONRPC
import SharedUIComponents
import OrderedCollections
import ConversationServiceProvider

struct WorkingSetView: View {
    let chat: StoreOf<Chat>
    
    private let r: Double = 8
    
    var body: some View {
        WithPerceptionTracking {
            VStack(alignment: .leading, spacing: 4) {
                
                WorkingSetHeader(chat: chat)
                
                ForEach(chat.fileEditMap.elements, id: \.key.path) { element in
                    FileEditView(chat: chat, fileEdit: element.value)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedCorners(tl: r, tr: r, bl: 0, br: 0)
                    .fill(.ultraThickMaterial)
            )
            .overlay(
                RoundedCorners(tl: r, tr: r, bl: 0, br: 0)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
            )
        }
    }
}

struct WorkingSetHeader: View {
    let chat: StoreOf<Chat>
    
    func getTitle() -> String {
        return chat.fileEditMap.count > 1 ? "\(chat.fileEditMap.count) files changed" : "1 file changed"
    }
    
    var body: some View {
        WithPerceptionTracking {
            HStack {
                Text(getTitle())
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
                
                Spacer()
                
                if chat.fileEditMap.contains(where: {_, fileEdit in
                    return fileEdit.status == .none
                }) {
                    /// Undo all edits
                    Button("Undo") {
                        chat.send(.undoEdits(fileURLs: chat.fileEditMap.values.map { $0.fileURL }))
                    }
                    .help("Undo All Edits")
                    
                    Button("Keep") {
                        chat.send(.keepEdits(fileURLs: chat.fileEditMap.values.map { $0.fileURL }))
                    }
                    .buttonStyle(.borderedProminent)
                    .help("Keep All Edits")
                } else {
                    Button("Done") {
                        chat.send(.resetEdits)
                    }
                    .help("Done")
                }
            }
        }
    }
}

struct FileEditView: View {
    let chat: StoreOf<Chat>
    let fileEdit: FileEdit
    
    @State private var isHovering = false

    var body: some View {
        ZStack(alignment: .trailing) {
            HStack(spacing: 4) {
                Button(action: {
                    chat.send(.openDiffViewWindow(fileURL: fileEdit.fileURL))
                }) {
                    drawFileIcon(fileEdit.fileURL)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundColor(.secondary)
                    
                    Text(fileEdit.fileURL.lastPathComponent)
                        .bold()
                        .font(.system(size: 14))
                }
                .buttonStyle(HoverButtonStyle())
                
                Spacer()
            }
            
            if isHovering {
                HStack(spacing: 4) {
                    
                    Spacer()
                    
                    if fileEdit.status == .none {
                        Button {
                            chat.send(.undoEdits(fileURLs: [fileEdit.fileURL]))
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 14, height: 14)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(HoverButtonStyle(padding: 0))
                        .help("Undo")
                        
                        Button {
                            chat.send(.keepEdits(fileURLs: [fileEdit.fileURL]))
                        } label: {
                            Image(systemName: "checkmark")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 14, height: 14)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(HoverButtonStyle(padding: 0))
                        .help("Keep")
                        
                        Button {
                            chat.send(.openDiffViewWindow(fileURL: fileEdit.fileURL))
                        } label: {
                            Image(systemName: "pencil.and.list.clipboard")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 14, height: 14)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(HoverButtonStyle(padding: 0))
                        .help("Open changes in Diff Editor")
                    }
                    
                    Button {
                        /// User directly close this edit. undo and remove it
                        chat.send(.discardFileEdits(fileURLs: [fileEdit.fileURL]))
                    } label: {
                        Image(systemName: "xmark")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 14, height: 14)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(HoverButtonStyle(padding: 0))
                    .help("Remove file")
                }
            }
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }
}


struct WorkingSetView_Previews: PreviewProvider {
    static let fileEditMap: OrderedDictionary<URL, FileEdit> = [
        URL(fileURLWithPath: "file:///f1.swift"): FileEdit(fileURL: URL(fileURLWithPath: "file:///f1.swift"), originalContent: "single line", modifiedContent: "single line 1", toolName: ToolName.insertEditIntoFile),
        URL(fileURLWithPath: "file:///f2.swift"): FileEdit(fileURL: URL(fileURLWithPath: "file:///f2.swift"), originalContent: "multi \n line \n end", modifiedContent: "another \n mut \n li \n", status: .kept, toolName: ToolName.insertEditIntoFile)
    ]
    
    static var previews: some View {
        WorkingSetView(
            chat: .init(
                initialState: .init(
                    history: ChatPanel_Preview.history,
                    isReceivingMessage: true,
                    fileEditMap: fileEditMap
                ),
                reducer: { Chat(service: ChatService.service(for: ChatPanel_Preview.chatTabInfo)) }
            )
        )
    }
}
