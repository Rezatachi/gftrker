import Foundation

#if DEBUG
struct OllamaFoodParsingService: FoodParsingService {
    var baseURL: String
    var model: String

    func parseFoodLogMessage(_ text: String) async throws -> ParsedFoodResult {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { throw FoodParsingError.emptyMessage }

        let response = try await requestEntities(for: trimmedText)
        let parsedItems = response.items.flatMap { entity in
            parseEntity(entity, originalText: trimmedText)
        }

        guard !parsedItems.isEmpty else {
            throw FoodParsingError.needsClarification("Local AI found food words, but they did not match the local nutrition database yet.")
        }

        return ParsedFoodResult(originalText: trimmedText, items: parsedItems)
    }

    private func requestEntities(for text: String) async throws -> OllamaFoodEntityResponse {
        guard let url = URL(string: normalizedBaseURL + "/api/generate") else {
            throw FoodParsingError.unavailable
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 45
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            OllamaGenerateRequest(
                model: model,
                prompt: prompt(for: text),
                stream: false,
                format: "json"
            )
        )

        let (data, httpResponse) = try await URLSession.shared.data(for: request)
        guard let httpResponse = httpResponse as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw FoodParsingError.unavailable
        }

        let generateResponse = try JSONDecoder().decode(OllamaGenerateResponse.self, from: data)
        let jsonData = Data(generateResponse.response.utf8)
        return try JSONDecoder().decode(OllamaFoodEntityResponse.self, from: jsonData)
    }

    private func parseEntity(_ entity: OllamaFoodEntity, originalText: String) -> [ParsedFoodItem] {
        let quantityPrefix = entity.quantityText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let servingHint = entity.servingHint?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let phrase = [quantityPrefix, entity.name, servingHint]
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        let service = LocalFoodDatabaseParsingService(confidenceAdjustment: 0.02)
        let semaphore = LocalEntityParser(service: service)
        let items = semaphore.parseSynchronously(phrase.isEmpty ? entity.name : phrase)

        return items.map { item in
            ParsedFoodItem(
                name: item.name,
                sourcePhrase: phrase,
                detectedQuantity: item.detectedQuantity,
                estimatedServing: item.estimatedServing,
                estimatedGrams: item.estimatedGrams,
                minSuggestedGrams: item.minSuggestedGrams,
                maxSuggestedGrams: item.maxSuggestedGrams,
                estimatedCalories: item.estimatedCalories,
                estimatedProtein: item.estimatedProtein,
                estimatedCarbs: item.estimatedCarbs,
                estimatedFat: item.estimatedFat,
                confidence: min(item.confidence, 0.82),
                source: .localLLM
            )
        }
    }

    private var normalizedBaseURL: String {
        var value = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasSuffix("/") {
            value.removeLast()
        }
        if value.hasPrefix("http://") || value.hasPrefix("https://") {
            return value
        }
        return "http://\(value)"
    }

    private func prompt(for text: String) -> String {
        let knownFoods = LocalFoodDatabase.entries.map(\.canonicalName).joined(separator: ", ")
        return """
        You extract food logging entities for a nutrition app.
        Return strict JSON only. Do not include markdown.
        Use the closest food name from this local database when possible:
        \(knownFoods)

        JSON shape:
        {
          "items": [
            {
              "name": "closest food name",
              "quantityText": "quantity from text, such as 1 cup or 2 bars",
              "servingHint": "cup, bowl, bar, piece, serving, or null"
            }
          ]
        }

        Rules:
        - Extract each food separately.
        - If the message is not English, translate each food to the closest English local database name.
        - Prefer names exactly from the local database list.
        - Do not estimate calories.
        - Do not invent foods that are not implied by the message.
        - If a phrase is vague, keep quantityText short, like "1 serving".

        Message:
        \(text)
        """
    }
}

private struct OllamaGenerateRequest: Encodable {
    let model: String
    let prompt: String
    let stream: Bool
    let format: String
}

private struct OllamaGenerateResponse: Decodable {
    let response: String
}

private struct OllamaFoodEntityResponse: Decodable {
    let items: [OllamaFoodEntity]
}

private struct OllamaFoodEntity: Decodable {
    let name: String
    let quantityText: String?
    let servingHint: String?
}

private struct LocalEntityParser {
    let service: LocalFoodDatabaseParsingService

    func parseSynchronously(_ text: String) -> [ParsedFoodItem] {
        let phrases = QuantityParser.splitFoodPhrases(text)
        return phrases.flatMap { phrase in
            FoodMatcher.matches(in: phrase).map { match in
                parsedItem(for: match, phrase: phrase)
            }
        }
    }

    private func parsedItem(for match: FoodMatch, phrase: String) -> ParsedFoodItem {
        let quantity = QuantityParser.parse(phrase)
        let serving = FoodServingEstimator.estimate(
            for: match.entry,
            quantity: quantity,
            phrase: phrase
        )
        let nutrition = match.entry.nutrition(for: serving.grams)
        let confidence = min(max(match.confidence * quantity.confidence * serving.confidence + service.confidenceAdjustment, 0.10), 0.82)

        return ParsedFoodItem(
            name: match.entry.canonicalName,
            sourcePhrase: phrase,
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
            source: .localLLM
        )
    }
}
#endif
