import Foundation

struct LocalFoodDatabaseParsingService: FoodParsingService {
    var confidenceAdjustment: Double = 0

    func parseFoodLogMessage(_ text: String) async throws -> ParsedFoodResult {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { throw FoodParsingError.emptyMessage }

        let phrases = QuantityParser.splitFoodPhrases(trimmedText)
        let items = phrases.compactMap { parsedItem(for: $0) }

        guard !items.isEmpty else {
            throw FoodParsingError.needsClarification("I am not totally sure what you meant. Can you add serving sizes or a more specific food?")
        }

        return ParsedFoodResult(originalText: trimmedText, items: items)
    }

    private func parsedItem(for phrase: String) -> ParsedFoodItem? {
        let matches = Array(FoodMatcher.matches(in: phrase).prefix(3))
        guard !matches.isEmpty else { return nil }

        let quantity = QuantityParser.parse(phrase)
        let candidates = matches.map { match in
            let serving = FoodServingEstimator.estimate(
                for: match.entry,
                quantity: quantity,
                phrase: phrase
            )
            let nutrition = match.entry.nutrition(for: serving.grams)
            let confidence = min(max(match.confidence * quantity.confidence * serving.confidence + confidenceAdjustment, 0.10), 0.95)
            let source: FoodLogSource = confidence >= 0.75 ? .localDatabase : .needsReview

            return ParsedFoodCandidate(
                id: "local:\(QuantityParser.normalize(match.entry.canonicalName))",
                name: match.entry.canonicalName,
                detectedQuantity: serving.detectedQuantity,
                estimatedServing: serving.label,
                estimatedGrams: serving.grams,
                minSuggestedGrams: serving.minGrams,
                maxSuggestedGrams: serving.maxGrams,
                estimatedCalories: Int(nutrition.calories.rounded()),
                estimatedProtein: nutrition.protein,
                estimatedCarbs: nutrition.carbs,
                estimatedFat: nutrition.fat,
                confidence: confidence,
                source: source
            )
        }

        return candidates[0].parsedItem(
            sourcePhrase: phrase,
            candidateOptions: candidates
        )
    }
}
