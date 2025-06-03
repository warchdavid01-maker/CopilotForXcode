import SwiftUI
import ComposableArchitecture

struct ChatSection: View {
    var body: some View {
        SettingsSection(title: "Chat Settings") {
            VStack(spacing: 10) {
                // Response language picker
                ResponseLanguageSetting()
            }
            .padding(10)
        }
    }
}

struct ResponseLanguageSetting: View {
    @AppStorage(\.chatResponseLocale) var chatResponseLocale

    // Locale codes mapped to language display names
    // reference: https://code.visualstudio.com/docs/configure/locales#_available-locales
    private let localeLanguageMap: [String: String] = [
        "en": "English",
        "zh-cn": "Chinese, Simplified",
        "zh-tw": "Chinese, Traditional",
        "fr": "French",
        "de": "German",
        "it": "Italian",
        "es": "Spanish",
        "ja": "Japanese",
        "ko": "Korean",
        "ru": "Russian",
        "pt-br": "Portuguese (Brazil)",
        "tr": "Turkish",
        "pl": "Polish",
        "cs": "Czech",
        "hu": "Hungarian"
    ]
    
    var selectedLanguage: String {
        if chatResponseLocale == "" {
            return "English"
        }
        
        return localeLanguageMap[chatResponseLocale] ?? "English"
    }

    // Display name to locale code mapping (for the picker UI)
    var sortedLanguageOptions: [(displayName: String, localeCode: String)] {
        localeLanguageMap.map { (displayName: $0.value, localeCode: $0.key) }
            .sorted { $0.displayName < $1.displayName }
    }

    var body: some View {
        WithPerceptionTracking {
            HStack {
                VStack(alignment: .leading) {
                    Text("Response Language")
                        .font(.body)
                    Text("This change applies only to new chat sessions. Existing ones won’t be impacted.")
                        .font(.footnote)
                }

                Spacer()

                Picker("", selection: $chatResponseLocale) {
                    ForEach(sortedLanguageOptions, id: \.localeCode) { option in
                        Text(option.displayName).tag(option.localeCode)
                    }
                }
                .frame(maxWidth: 200, alignment: .leading)
            }
        }
    }
}

#Preview {
    ChatSection()
        .frame(width: 600)
}
