import Foundation

struct SmallModelFoodParsingService: FoodParsingService {
    func parseFoodLogMessage(_ text: String) async throws -> ParsedFoodResult {
        /*
         TODO:
         - Load a compact Core ML sequence/tagging model when one exists.
         - Use it to extract food spans and quantity spans only.
         - Keep nutrition math in LocalFoodDatabase so the model does not need
           to memorize calories or macros.
         - Return ParsedFoodResult with source .smallModel or .needsReview.
         */
        throw FoodParsingError.unavailable
    }
}
