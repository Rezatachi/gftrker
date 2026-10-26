import Foundation

#if DEBUG
struct USDAFoodCatalogService: FoodParsingService {
    let apiKey: String

    func parseFoodLogMessage(_ text: String) async throws -> ParsedFoodResult {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { throw FoodParsingError.emptyMessage }
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FoodParsingError.unavailable
        }

        let phrases = QuantityParser.splitFoodPhrases(trimmedText)
        let items = try await withThrowingTaskGroup(of: ParsedFoodItem?.self) { group in
            for phrase in phrases {
                group.addTask {
                    try await searchParsedItem(for: phrase)
                }
            }

            var parsedItems: [ParsedFoodItem] = []
            for try await item in group {
                if let item {
                    parsedItems.append(item)
                }
            }
            return parsedItems
        }

        guard !items.isEmpty else {
            throw FoodParsingError.needsClarification("I could not find a nutrition match for that yet.")
        }

        return ParsedFoodResult(originalText: trimmedText, items: items)
    }

    private func searchParsedItem(for phrase: String) async throws -> ParsedFoodItem? {
        let query = searchQuery(from: phrase)
        guard !query.isEmpty else { return nil }

        guard var components = URLComponents(string: "https://api.nal.usda.gov/fdc/v1/foods/search") else {
            throw FoodParsingError.unavailable
        }
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey)
        ]

        guard let url = components.url else { throw FoodParsingError.unavailable }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 18
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            USDASearchRequest(
                query: query,
                pageSize: 8,
                dataType: ["Foundation", "SR Legacy", "Survey (FNDDS)", "Branded"]
            )
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw FoodParsingError.unavailable
        }

        let searchResponse = try JSONDecoder().decode(USDASearchResponse.self, from: data)
        let quantity = QuantityParser.parse(phrase)
        let candidates = rankedFoods(from: searchResponse.foods, query: query)
            .prefix(3)
            .map {
                parsedCandidate(
                    from: $0,
                    phrase: phrase,
                    quantity: quantity,
                    peerFoods: searchResponse.foods,
                    query: query
                )
            }

        guard let selected = candidates.first else { return nil }
        return selected.parsedItem(
            sourcePhrase: phrase,
            candidateOptions: Array(candidates)
        )
    }

    private func parsedCandidate(
        from food: USDAFood,
        phrase: String,
        quantity: ParsedQuantity,
        peerFoods: [USDAFood],
        query: String
    ) -> ParsedFoodCandidate {
        let nutrients = nutrientsPer100g(from: food.foodNutrients)
        let nutritionEntry = FoodNutritionEntry(
            canonicalName: food.description,
            aliases: [],
            caloriesPer100g: nutrients.calories,
            proteinPer100g: nutrients.protein,
            carbsPer100g: nutrients.carbs,
            fatPer100g: nutrients.fat,
            commonServings: servings(for: food, peerFoods: peerFoods)
        )
        let serving = FoodServingEstimator.estimate(
            for: nutritionEntry,
            quantity: quantity,
            phrase: phrase,
            fallbackServing: ProviderFoodServing.fallback(for: quantity)
        )
        let scale = serving.grams / 100

        return ParsedFoodCandidate(
            id: "usda:\(food.fdcId)",
            providerID: String(food.fdcId),
            providerDataType: food.dataType,
            brandOwner: food.brandOwner,
            name: titleCased(food.description),
            detectedQuantity: serving.detectedQuantity,
            estimatedServing: serving.label,
            estimatedGrams: serving.grams,
            minSuggestedGrams: serving.minGrams,
            maxSuggestedGrams: serving.maxGrams,
            estimatedCalories: Int((nutrients.calories * scale).rounded()),
            estimatedProtein: nutrients.protein * scale,
            estimatedCarbs: nutrients.carbs * scale,
            estimatedFat: nutrients.fat * scale,
            confidence: min(
                max(confidence(for: food, query: query) * serving.confidence, 0.35),
                0.86
            ),
            source: .usda
        )
    }

    private func searchQuery(from phrase: String) -> String {
        FoodTextScorer.searchQuery(from: phrase)
    }

    private func rankedFoods(from foods: [USDAFood], query: String) -> [USDAFood] {
        var seenIDs: Set<Int> = []
        return foods
            .sorted { score($0, query: query) > score($1, query: query) }
            .filter { seenIDs.insert($0.fdcId).inserted }
            .filter { nutrientsPer100g(from: $0.foodNutrients).calories > 0 }
    }

    private func score(_ food: USDAFood, query: String) -> Double {
        let dataTypeBoost: Double
        switch food.dataType {
        case "Survey (FNDDS)": dataTypeBoost = 0.18
        case "Foundation": dataTypeBoost = 0.15
        case "SR Legacy": dataTypeBoost = 0.12
        default: dataTypeBoost = 0.04
        }

        return FoodTextScorer.lexicalScore(candidateText: food.description, query: query) + dataTypeBoost
    }

    private func confidence(for food: USDAFood, query: String) -> Double {
        min(max(score(food, query: query), 0.48), 0.86)
    }

    private func servings(for food: USDAFood, peerFoods: [USDAFood]) -> [FoodServing] {
        var result: [FoodServing] = []

        if let servingGrams = ProviderFoodServing.grams(
            value: food.servingSize,
            unit: food.servingSizeUnit
        ) {
            let label = normalizedServingLabel(
                food.householdServingFullText,
                fallback: "1 serving"
            )
            let neighboringWeights = peerFoods.compactMap { peer -> Double? in
                guard let peerGrams = ProviderFoodServing.grams(
                    value: peer.servingSize,
                    unit: peer.servingSizeUnit
                ) else {
                    return nil
                }
                let peerLabel = normalizedServingLabel(
                    peer.householdServingFullText,
                    fallback: "1 serving"
                )
                return equivalentWeight(
                    peerLabel: peerLabel,
                    peerGrams: peerGrams,
                    targetLabel: label
                )
            }
            if let serving = ProviderFoodServing.serving(
                label: label,
                grams: servingGrams,
                neighboringGramWeights: neighboringWeights
            ) {
                result.append(serving)
            }
        }

        let measures = (food.foodMeasures ?? [])
            .filter { $0.gramWeight > 0 }
            .sorted { ($0.rank ?? Int.max) < ($1.rank ?? Int.max) }

        for measure in measures {
            let label = normalizedServingLabel(
                measure.disseminationText,
                fallback: "1 serving"
            )
            let neighboringWeights = measures.compactMap {
                equivalentWeight(
                    peerLabel: normalizedServingLabel(
                        $0.disseminationText,
                        fallback: "1 serving"
                    ),
                    peerGrams: $0.gramWeight,
                    targetLabel: label
                )
            }
            if let serving = ProviderFoodServing.serving(
                label: label,
                grams: measure.gramWeight,
                neighboringGramWeights: neighboringWeights
            ) {
                result.append(serving)
            }
        }

        var seenLabels: Set<String> = []
        return result.filter {
            seenLabels.insert(QuantityParser.normalize($0.label)).inserted
        }
    }

    private func normalizedServingLabel(_ label: String?, fallback: String) -> String {
        let trimmed = label?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if trimmed.isEmpty || trimmed.lowercased().contains("quantity not specified") {
            return fallback
        }
        return trimmed
    }

    private func equivalentWeight(
        peerLabel: String,
        peerGrams: Double,
        targetLabel: String
    ) -> Double? {
        let peerQuantity = QuantityParser.parse(
            peerLabel.replacingOccurrences(of: ",", with: " ")
        )
        let targetQuantity = QuantityParser.parse(
            targetLabel.replacingOccurrences(of: ",", with: " ")
        )

        if peerQuantity.unit == targetQuantity.unit,
           let unit = targetQuantity.unit,
           !unit.isEmpty,
           peerQuantity.multiplier > 0,
           targetQuantity.multiplier > 0 {
            return peerGrams / peerQuantity.multiplier * targetQuantity.multiplier
        }

        return QuantityParser.normalize(peerLabel) == QuantityParser.normalize(targetLabel)
            ? peerGrams
            : nil
    }

    private func nutrientsPer100g(from nutrients: [USDANutrient]) -> USDANutrients {
        var result = USDANutrients(calories: 0, protein: 0, carbs: 0, fat: 0)
        for nutrient in nutrients {
            let name = nutrient.nutrientName.lowercased()
            if name.contains("energy") && nutrient.unitName.lowercased() == "kcal" {
                result.calories = nutrient.value
            } else if name == "protein" {
                result.protein = nutrient.value
            } else if name.contains("carbohydrate") {
                result.carbs = nutrient.value
            } else if name == "total lipid (fat)" || name == "total fat" {
                result.fat = nutrient.value
            }
        }
        return result
    }

    private func titleCased(_ value: String) -> String {
        value
            .lowercased()
            .split(separator: " ")
            .map { word in
                word.prefix(1).uppercased() + word.dropFirst()
            }
            .joined(separator: " ")
    }
}

private struct USDASearchRequest: Encodable {
    let query: String
    let pageSize: Int
    let dataType: [String]
}

private struct USDASearchResponse: Decodable {
    let foods: [USDAFood]
}

private struct USDAFood: Decodable {
    let fdcId: Int
    let description: String
    let dataType: String?
    let brandOwner: String?
    let foodNutrients: [USDANutrient]
    let servingSize: Double?
    let servingSizeUnit: String?
    let householdServingFullText: String?
    let foodMeasures: [USDAFoodMeasure]?
}

private struct USDAFoodMeasure: Decodable {
    let disseminationText: String?
    let gramWeight: Double
    let rank: Int?
}

private struct USDANutrient: Decodable {
    let nutrientName: String
    let value: Double
    let unitName: String
}

private struct USDANutrients {
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
}
#endif
