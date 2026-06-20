import Foundation

struct FoodParsingRouter: FoodParsingService {
    let preferLocalParsing: Bool
    let aiFallbackEnabled: Bool

    private let ruleBasedService = RuleBasedFoodParsingService()
    private let localDatabaseService = LocalFoodDatabaseParsingService()
    private let smallModelService = SmallModelFoodParsingService()
    private let openAIService = OpenAIFoodParsingService()

    init(preferLocalParsing: Bool = true, aiFallbackEnabled: Bool = false) {
        self.preferLocalParsing = preferLocalParsing
        self.aiFallbackEnabled = aiFallbackEnabled
    }

    func parseFoodLogMessage(_ text: String) async throws -> ParsedFoodResult {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { throw FoodParsingError.emptyMessage }

        var bestResult: ParsedFoodResult?

        if preferLocalParsing {
            if let result = try? await ruleBasedService.parseFoodLogMessage(trimmedText), result.averageConfidence >= 0.75 {
                return result
            }

            if let result = try? await localDatabaseService.parseFoodLogMessage(trimmedText) {
                if result.averageConfidence >= 0.45 {
                    return result
                }
                bestResult = result
            }
        }

        if let result = try? await smallModelService.parseFoodLogMessage(trimmedText), result.averageConfidence >= 0.45 {
            return result
        }

        if aiFallbackEnabled, let result = try? await openAIService.parseFoodLogMessage(trimmedText) {
            return result
        }

        if let bestResult {
            return bestResult
        }

        throw FoodParsingError.needsClarification("I am not totally sure what you meant. Can you add serving sizes?")
    }
}

private extension ParsedFoodResult {
    var averageConfidence: Double {
        guard !items.isEmpty else { return 0 }
        return items.reduce(0) { $0 + $1.confidence } / Double(items.count)
    }
}
