import Foundation

struct RuleBasedFoodParsingService: FoodParsingService {
    private let localService = LocalFoodDatabaseParsingService(confidenceAdjustment: 0.04)

    func parseFoodLogMessage(_ text: String) async throws -> ParsedFoodResult {
        try await localService.parseFoodLogMessage(text)
    }
}
