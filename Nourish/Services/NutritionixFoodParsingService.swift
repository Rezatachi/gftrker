import Foundation

#if DEBUG
struct NutritionixFoodParsingService: FoodParsingService {
    let appID: String
    let apiKey: String

    func parseFoodLogMessage(_ text: String) async throws -> ParsedFoodResult {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { throw FoodParsingError.emptyMessage }
        guard !appID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FoodParsingError.unavailable
        }

        guard let url = URL(string: "https://trackapi.nutritionix.com/v2/natural/nutrients") else {
            throw FoodParsingError.unavailable
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 18
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(appID, forHTTPHeaderField: "x-app-id")
        request.setValue(apiKey, forHTTPHeaderField: "x-app-key")
        request.httpBody = try JSONEncoder().encode(
            NutritionixNutrientsRequest(
                query: trimmedText,
                lineDelimited: false,
                useRawFoods: true,
                useBrandedFoods: true
            )
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw FoodParsingError.unavailable
        }

        let parsedResponse = try JSONDecoder().decode(NutritionixNutrientsResponse.self, from: data)
        let items = parsedResponse.foods.compactMap { parsedItem(from: $0, sourcePhrase: trimmedText) }

        guard !items.isEmpty else {
            throw FoodParsingError.needsClarification("Nutritionix did not find a confident match for that yet.")
        }

        return ParsedFoodResult(originalText: trimmedText, items: items)
    }

    private func parsedItem(from food: NutritionixFood, sourcePhrase: String) -> ParsedFoodItem? {
        let grams = food.servingWeightGrams ?? 0
        guard grams > 0 else { return nil }

        let calories = food.calories ?? 0
        let protein = food.protein ?? 0
        let carbs = food.totalCarbohydrate ?? 0
        let fat = food.totalFat ?? 0
        let servingUnit = food.servingUnit ?? "serving"
        let servingQuantity = food.servingQuantity ?? 1
        let label = servingLabel(quantity: servingQuantity, unit: servingUnit)
        let serving = providerServing(
            grams: grams,
            label: label,
            quantity: servingQuantity,
            unit: servingUnit,
            altMeasures: food.altMeasures ?? [],
            isBranded: food.brandName != nil
        )
        let displayName = titleCased([food.brandName, food.foodName].compactMap { $0 }.joined(separator: " "))

        let providerID = food.nixItemID ?? food.tagID
        let candidate = ParsedFoodCandidate(
            id: "nutritionix:\(providerID ?? QuantityParser.normalize(displayName))",
            providerID: providerID,
            brandOwner: food.brandName,
            name: displayName.isEmpty ? titleCased(food.foodName ?? "Food") : displayName,
            detectedQuantity: label,
            estimatedServing: label,
            estimatedGrams: grams,
            minSuggestedGrams: serving.minGrams,
            maxSuggestedGrams: serving.maxGrams,
            estimatedCalories: Int(calories.rounded()),
            estimatedProtein: protein,
            estimatedCarbs: carbs,
            estimatedFat: fat,
            confidence: confidence(for: food),
            source: .nutritionix
        )
        return candidate.parsedItem(
            sourcePhrase: sourcePhrase,
            candidateOptions: [candidate]
        )
    }

    private func providerServing(
        grams: Double,
        label: String,
        quantity: Double,
        unit: String,
        altMeasures: [NutritionixAltMeasure],
        isBranded: Bool
    ) -> FoodServing {
        let safeQuantity = max(quantity, 0.01)
        let currentUnitWeight = grams / safeQuantity
        let neighboringWeights = altMeasures.compactMap { measure -> Double? in
            guard let servingWeight = measure.servingWeight,
                  let measureQuantity = measure.quantity,
                  servingWeight > 0,
                  measureQuantity > 0 else {
                return nil
            }
            let unitWeight = servingWeight / measureQuantity
            guard unitWeight >= currentUnitWeight * 0.60,
                  unitWeight <= currentUnitWeight * 1.65 else {
                return nil
            }
            return unitWeight * safeQuantity
        }

        let normalizedUnit = QuantityParser.normalize(unit)
        let isPackage = isBranded && [
            "container", "package", "packet", "bag", "bottle", "can", "jar", "bar"
        ].contains(where: normalizedUnit.contains)

        return ProviderFoodServing.serving(
            label: label,
            grams: grams,
            neighboringGramWeights: neighboringWeights,
            isPackage: isPackage
        ) ?? FoodServing(
            label: label,
            grams: grams,
            minGrams: max(grams * 0.90, 1),
            maxGrams: grams * 1.10
        )
    }

    private func confidence(for food: NutritionixFood) -> Double {
        var score = 0.62
        if food.servingWeightGrams != nil { score += 0.10 }
        if food.calories != nil { score += 0.08 }
        if food.protein != nil { score += 0.04 }
        if food.altMeasures?.isEmpty == false { score += 0.04 }
        if food.brandName != nil { score += 0.02 }
        return min(score, 0.88)
    }

    private func servingLabel(quantity: Double, unit: String) -> String {
        let formattedQuantity = quantity.rounded() == quantity ? "\(Int(quantity))" : String(format: "%.1f", quantity)
        return "\(formattedQuantity) \(unit)"
    }

    private func titleCased(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}

private struct NutritionixNutrientsRequest: Encodable {
    let query: String
    let lineDelimited: Bool
    let useRawFoods: Bool
    let useBrandedFoods: Bool

    enum CodingKeys: String, CodingKey {
        case query
        case lineDelimited = "line_delimited"
        case useRawFoods = "use_raw_foods"
        case useBrandedFoods = "use_branded_foods"
    }
}

private struct NutritionixNutrientsResponse: Decodable {
    let foods: [NutritionixFood]
}

private struct NutritionixFood: Decodable {
    let foodName: String?
    let brandName: String?
    let nixItemID: String?
    let tagID: String?
    let servingQuantity: Double?
    let servingUnit: String?
    let servingWeightGrams: Double?
    let calories: Double?
    let totalFat: Double?
    let totalCarbohydrate: Double?
    let protein: Double?
    let altMeasures: [NutritionixAltMeasure]?

    enum CodingKeys: String, CodingKey {
        case foodName = "food_name"
        case brandName = "brand_name"
        case nixItemID = "nix_item_id"
        case tagID = "tag_id"
        case servingQuantity = "serving_qty"
        case servingUnit = "serving_unit"
        case servingWeightGrams = "serving_weight_grams"
        case calories = "nf_calories"
        case totalFat = "nf_total_fat"
        case totalCarbohydrate = "nf_total_carbohydrate"
        case protein = "nf_protein"
        case altMeasures = "alt_measures"
    }
}

private struct NutritionixAltMeasure: Decodable {
    let servingWeight: Double?
    let measure: String?
    let quantity: Double?

    enum CodingKeys: String, CodingKey {
        case servingWeight = "serving_weight"
        case measure
        case quantity = "qty"
    }
}
#endif
