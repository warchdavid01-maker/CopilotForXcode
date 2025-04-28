import SwiftUI
import ChatService
import Persist
import ComposableArchitecture
import GitHubCopilotService
import Combine

public let SELECTED_LLM_KEY = "selectedLLM"

extension AppState {
    func getSelectedModelFamily() -> String? {
        if let savedModel = get(key: SELECTED_LLM_KEY),
           let modelFamily = savedModel["modelFamily"]?.stringValue {
            return modelFamily
        }
        return nil
    }

    func getSelectedModelName() -> String? {
        if let savedModel = get(key: SELECTED_LLM_KEY),
           let modelName = savedModel["modelName"]?.stringValue {
            return modelName
        }
        return nil
    }

    func setSelectedModel(_ model: LLMModel) {
        update(key: SELECTED_LLM_KEY, value: model)
    }
}

class CopilotModelManagerObservable: ObservableObject {
    static let shared = CopilotModelManagerObservable()
    
    @Published var availableChatModels: [LLMModel] = []
    @Published var defaultModel: LLMModel = .init(modelName: "", modelFamily: "")
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Initial load
        availableChatModels = CopilotModelManager.getAvailableChatLLMs()
        
        // Setup notification to update when models change
        NotificationCenter.default.publisher(for: .gitHubCopilotModelsDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.availableChatModels = CopilotModelManager.getAvailableChatLLMs()
                self?.defaultModel = CopilotModelManager.getDefaultChatModel()
            }
            .store(in: &cancellables)
    }
}

extension CopilotModelManager {
    static func getAvailableChatLLMs() -> [LLMModel] {
        let LLMs = CopilotModelManager.getAvailableLLMs()
        return LLMs.filter(
            { $0.scopes.contains(.chatPanel) }
        ).map {
            LLMModel(modelName: $0.modelName, modelFamily: $0.modelFamily)
        }
    }

    static func getDefaultChatModel() -> LLMModel {
        let defaultModel = CopilotModelManager.getDefaultChatLLM()
        if let defaultModel = defaultModel {
            return LLMModel(modelName: defaultModel.modelName, modelFamily: defaultModel.modelFamily)
        }
        // Fallback to a hardcoded default if no model has isChatDefault = true
        return LLMModel(modelName: "GPT-4.1 (Preview)", modelFamily: "gpt-4.1")
    }
}

struct LLMModel: Codable, Hashable {
    let modelName: String
    let modelFamily: String
}

struct ModelPicker: View {
    @State private var selectedModel = ""
    @State private var isHovered = false
    @State private var isPressed = false
    @ObservedObject private var modelManager = CopilotModelManagerObservable.shared
    static var lastRefreshModelsTime: Date = .init(timeIntervalSince1970: 0)

    init() {
        let initialModel = AppState.shared.getSelectedModelName() ?? CopilotModelManager.getDefaultChatModel().modelName
        self._selectedModel = State(initialValue: initialModel)
    }

    var models: [LLMModel] {
        modelManager.availableChatModels
    }
    
    var defaultModel: LLMModel {
        modelManager.defaultModel
    }

    func updateCurrentModel() {
        selectedModel = AppState.shared.getSelectedModelName() ?? defaultModel.modelName
    }

    var body: some View {
        WithPerceptionTracking {
            Group {
                if !models.isEmpty && !selectedModel.isEmpty {
                    Menu(selectedModel) {
                        ForEach(models, id: \.self) { option in
                            Button {
                                selectedModel = option.modelName
                                AppState.shared.setSelectedModel(option)
                            } label: {
                                if selectedModel == option.modelName {
                                    Text("✓ \(option.modelName)")
                                } else {
                                    Text("    \(option.modelName)")
                                }
                            }
                        }
                    }
                    .menuStyle(BorderlessButtonMenuStyle())
                    .frame(maxWidth: labelWidth())
                    .padding(4)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(isHovered ? Color.gray.opacity(0.1) : Color.clear)
                    )
                    .onHover { hovering in
                        isHovered = hovering
                    }
                } else {
                    EmptyView()
                }
            }
            .onAppear() {
                Task {
                    await refreshModels()
                    updateCurrentModel()
                }
            }
            .onChange(of: defaultModel) { _ in
                updateCurrentModel()
            }
            .onChange(of: models) { _ in
                updateCurrentModel()
            }
            .help("Pick Model")
        }
    }

    func labelWidth() -> CGFloat {
        let font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let attributes = [NSAttributedString.Key.font: font]
        let width = selectedModel.size(withAttributes: attributes).width
        return CGFloat(width + 20)
    }

    @MainActor
    func refreshModels() async {
        let now = Date()
        if now.timeIntervalSince(Self.lastRefreshModelsTime) < 60 {
            return
        }

        Self.lastRefreshModelsTime = now
        let copilotModels = await SharedChatService.shared.copilotModels()
        if !copilotModels.isEmpty {
            CopilotModelManager.updateLLMs(copilotModels)
        }
    }
}

struct ModelPicker_Previews: PreviewProvider {
    static var previews: some View {
        ModelPicker()
    }
}
