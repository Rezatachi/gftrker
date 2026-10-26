import Foundation

#if DEBUG
struct OpenAIFoodParsingService: FoodParsingService {
    func parseFoodLogMessage(_ text: String) async throws -> ParsedFoodResult {
        /*
         TODO:
         - Optional fallback only when the user enables AI fallback in settings.
         - Send `text` to an LLM with a strict JSON schema.
         - Do not auto-save results.
         - Decode JSON into ParsedFoodResult.
         - API keys should come from secure runtime configuration, never source.

         Expected JSON shape:
         {
           "items": [
             {
               "name": "Greek yogurt",
               "detectedQuantity": "1 cup",
               "estimatedServing": "1 cup",
               "estimatedGrams": 225,
               "minSuggestedGrams": 180,
               "maxSuggestedGrams": 250,
               "estimatedCalories": 140,
               "estimatedProtein": 20,
               "estimatedCarbs": 8,
               "estimatedFat": 0,
               "confidence": 0.82
             }
           ]
         }
         */
        throw FoodParsingError.unavailable
    }
}
#endif
