import Foundation

enum AppConfiguration {
    static var developerProviderConfigurationEnabled: Bool {
#if DEBUG
        true
#else
        false
#endif
    }

    static var usdaAPIKey: String {
        guard developerProviderConfigurationEnabled else { return "" }
        return bundledValue(for: "USDA_API_KEY")
    }

    static var nutritionixAppID: String {
        guard developerProviderConfigurationEnabled else { return "" }
        return bundledValue(for: "NUTRITIONIX_APP_ID")
    }

    static var nutritionixAPIKey: String {
        guard developerProviderConfigurationEnabled else { return "" }
        return bundledValue(for: "NUTRITIONIX_API_KEY")
    }

    static var defaultOllamaBaseURL: String {
#if DEBUG
        return "http://localhost:11434"
#else
        return ""
#endif
    }

    static var defaultOllamaModel: String {
#if DEBUG
        return "llama3.2:3b"
#else
        return ""
#endif
    }

    static var hasUSDAAPIKey: Bool {
        !usdaAPIKey.isEmpty
    }

    static var hasNutritionixCredentials: Bool {
        !nutritionixAppID.isEmpty && !nutritionixAPIKey.isEmpty
    }

    private static func bundledValue(for key: String) -> String {
        guard let rawValue = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return ""
        }

        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, !value.hasPrefix("$("), !value.contains("your_") else {
            return ""
        }

        return value
    }
}
