import Foundation

struct LocalFoodDatabaseParsingService: FoodParsingService {
    var confidenceAdjustment: Double = 0

    func parseFoodLogMessage(_ text: String) async throws -> ParsedFoodResult {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { throw FoodParsingError.emptyMessage }

        let phrases = QuantityParser.splitFoodPhrases(trimmedText)
        let items = phrases.flatMap { parsedItems(for: $0) }

        guard !items.isEmpty else {
            throw FoodParsingError.needsClarification("I am not totally sure what you meant. Can you add serving sizes or a more specific food?")
        }

        return ParsedFoodResult(originalText: trimmedText, items: items)
    }

    private func parsedItems(for phrase: String) -> [ParsedFoodItem] {
        let matches = FoodMatcher.matches(in: phrase)
        guard !matches.isEmpty else { return [] }

        let quantity = QuantityParser.parse(phrase)
        return matches.map { match in
            let serving = servingEstimate(for: match.entry, quantity: quantity, phrase: phrase)
            let nutrition = match.entry.nutrition(for: serving.grams)
            let confidence = min(max(match.confidence * quantity.confidence * serving.confidence + confidenceAdjustment, 0.10), 0.95)
            let source: FoodLogSource = confidence >= 0.75 ? .localDatabase : .needsReview

            return ParsedFoodItem(
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
    }

    private func servingEstimate(for entry: FoodNutritionEntry, quantity: ParsedQuantity, phrase: String) -> ServingEstimate {
        if let explicitGrams = quantity.explicitGrams {
            return ServingEstimate(
                label: "\(Int(explicitGrams.rounded()))g",
                grams: explicitGrams,
                minGrams: explicitGrams * 0.92,
                maxGrams: explicitGrams * 1.08,
                detectedQuantity: quantity.quantityText,
                confidence: 0.96
            )
        }

        let normalizedPhrase = QuantityParser.normalize(phrase)
        let baseServing = bestServing(for: entry, unit: quantity.unit, phrase: normalizedPhrase)
        var multiplier = quantity.multiplier

        if normalizedPhrase.contains("half"), baseServing.label.contains("half") {
            multiplier = 1
        }

        let grams = max(baseServing.grams * multiplier, 1)
        let rangeMultiplier = quantity.isVague ? 1.35 : 1
        let detectedQuantity = detectedQuantityText(quantity: quantity, serving: baseServing, multiplier: multiplier)

        return ServingEstimate(
            label: servingLabel(baseServing.label, multiplier: multiplier),
            grams: grams,
            minGrams: max(baseServing.minGrams * multiplier / rangeMultiplier, 1),
            maxGrams: max(baseServing.maxGrams * multiplier * rangeMultiplier, grams + 1),
            detectedQuantity: detectedQuantity,
            confidence: quantity.isVague ? 0.62 : 0.86
        )
    }

    private func bestServing(for entry: FoodNutritionEntry, unit: String?, phrase: String) -> FoodServing {
        if phrase.contains("half"), let serving = entry.commonServings.first(where: { $0.label.contains("half") }) {
            return serving
        }

        if let unit,
           let serving = entry.commonServings.first(where: { servingMatches($0, unit: unit, foodName: entry.canonicalName) }) {
            return serving
        }

        return entry.commonServings.first ?? FoodServing(label: "serving", grams: 150, minGrams: 100, maxGrams: 220)
    }

    private func servingMatches(_ serving: FoodServing, unit: String, foodName: String) -> Bool {
        let label = serving.label.lowercased()
        if label.contains(unit) { return true }
        if unit == "egg", foodName == "Eggs" { return label.contains("egg") }
        if unit == "banana", foodName == "Banana" { return label.contains("banana") }
        if unit == "apple", foodName == "Apple" { return label.contains("apple") }
        if unit == "slice", label.contains("slice") { return true }
        return false
    }

    private func detectedQuantityText(quantity: ParsedQuantity, serving: FoodServing, multiplier: Double) -> String {
        if quantity.quantityText != "1 serving" {
            return quantity.quantityText
        }
        return servingLabel(serving.label, multiplier: multiplier)
    }

    private func servingLabel(_ label: String, multiplier: Double) -> String {
        guard multiplier != 1 else { return label }
        let formatted = multiplier.rounded() == multiplier ? "\(Int(multiplier))" : String(format: "%.1f", multiplier)
        let cleaned = label.replacingOccurrences(of: "1 ", with: "")
        return "\(formatted) \(cleaned)"
    }
}

private struct ServingEstimate {
    let label: String
    let grams: Double
    let minGrams: Double
    let maxGrams: Double
    let detectedQuantity: String
    let confidence: Double
}
