import Foundation

struct OpenFoodFactsParsingService: FoodParsingService {
    func parseFoodLogMessage(_ text: String) async throws -> ParsedFoodResult {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { throw FoodParsingError.emptyMessage }

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
            throw FoodParsingError.needsClarification("Open Food Facts did not find a packaged food match for that yet.")
        }

        return ParsedFoodResult(originalText: trimmedText, items: items)
    }

    private func searchParsedItem(for phrase: String) async throws -> ParsedFoodItem? {
        let query = searchQuery(from: phrase)
        guard !query.isEmpty else { return nil }

        guard var components = URLComponents(string: "https://world.openfoodfacts.org/cgi/search.pl") else {
            throw FoodParsingError.unavailable
        }
        components.queryItems = [
            URLQueryItem(name: "search_terms", value: query),
            URLQueryItem(name: "search_simple", value: "1"),
            URLQueryItem(name: "action", value: "process"),
            URLQueryItem(name: "json", value: "1"),
            URLQueryItem(name: "page_size", value: "8"),
            URLQueryItem(
                name: "fields",
                value: "code,product_name,brands,quantity,product_quantity,product_quantity_unit,serving_size,serving_quantity,serving_quantity_unit,nutriments"
            )
        ]

        guard let url = components.url else { throw FoodParsingError.unavailable }
        var request = URLRequest(url: url)
        request.timeoutInterval = 18
        request.setValue("Nourish-iOS/1.0 (personal nutrition logger)", forHTTPHeaderField: "User-Agent")

        let data = try await responseData(for: request)
        let searchResponse = try JSONDecoder().decode(OpenFoodFactsSearchResponse.self, from: data)
        let quantity = QuantityParser.parse(phrase)
        let candidates = rankedProducts(from: searchResponse.products, query: query)
            .prefix(3)
            .compactMap {
                parsedCandidate(
                    from: $0,
                    phrase: phrase,
                    quantity: quantity,
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
        from product: OpenFoodFactsProduct,
        phrase: String,
        quantity: ParsedQuantity,
        query: String
    ) -> ParsedFoodCandidate? {
        guard let nutrients = nutrientsPer100g(from: product.nutriments) else {
            return nil
        }
        let nutritionEntry = FoodNutritionEntry(
            canonicalName: displayName(for: product),
            aliases: [],
            caloriesPer100g: nutrients.calories,
            proteinPer100g: nutrients.protein,
            carbsPer100g: nutrients.carbs,
            fatPer100g: nutrients.fat,
            commonServings: servings(for: product, requestedQuantity: quantity)
        )
        let serving = FoodServingEstimator.estimate(
            for: nutritionEntry,
            quantity: quantity,
            phrase: phrase,
            fallbackServing: ProviderFoodServing.fallback(for: quantity)
        )
        let scale = serving.grams / 100
        let name = displayName(for: product)

        let candidateID = product.code?.isEmpty == false
            ? "open-food-facts:\(product.code!)"
            : "open-food-facts:\(QuantityParser.normalize(name))"

        return ParsedFoodCandidate(
            id: candidateID,
            providerID: product.code,
            brandOwner: product.brands,
            name: name,
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
                max(confidence(for: product, query: query) * serving.confidence, 0.32),
                0.80
            ),
            source: .openFoodFacts
        )
    }

    private func responseData(for request: URLRequest) async throws -> Data {
        for attempt in 0..<3 {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw FoodParsingError.unavailable
            }
            if (200..<300).contains(httpResponse.statusCode) {
                return data
            }

            let isRetryable = httpResponse.statusCode == 429
                || (500..<600).contains(httpResponse.statusCode)
            guard isRetryable, attempt < 2 else {
                throw FoodParsingError.unavailable
            }

            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                .flatMap(Double.init)
            let delay = retryAfter ?? (0.5 * pow(2, Double(attempt)))
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }

        throw FoodParsingError.unavailable
    }

    private func searchQuery(from phrase: String) -> String {
        FoodTextScorer.searchQuery(from: phrase)
    }

    private func rankedProducts(
        from products: [OpenFoodFactsProduct],
        query: String
    ) -> [OpenFoodFactsProduct] {
        var seenIDs: Set<String> = []
        return products
            .filter { nutrientsPer100g(from: $0.nutriments) != nil }
            .sorted { score($0, query: query) > score($1, query: query) }
            .filter { product in
                let key = product.code?.isEmpty == false
                    ? product.code!
                    : QuantityParser.normalize(displayName(for: product))
                return seenIDs.insert(key).inserted
            }
    }

    private func score(_ product: OpenFoodFactsProduct, query: String) -> Double {
        let name = [product.productName, product.brands].compactMap { $0 }.joined(separator: " ").lowercased()
        let nutrientBoost = nutrientsPer100g(from: product.nutriments) == nil ? 0 : 0.18
        let nameBoost = (product.productName?.isEmpty == false) ? 0.10 : 0
        return FoodTextScorer.lexicalScore(candidateText: name, query: query) + nutrientBoost + nameBoost
    }

    private func confidence(for product: OpenFoodFactsProduct, query: String) -> Double {
        min(max(score(product, query: query), 0.42), 0.80)
    }

    private func servings(
        for product: OpenFoodFactsProduct,
        requestedQuantity: ParsedQuantity
    ) -> [FoodServing] {
        var result: [FoodServing] = []

        if let servingGrams = ProviderFoodServing.grams(
            value: product.servingQuantity,
            unit: product.servingQuantityUnit
        ) {
            let rawLabel = product.servingSize?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let parsedLabel = QuantityParser.parse(rawLabel)
            let label = parsedLabel.unit == nil || parsedLabel.unit == "g"
                ? "1 serving\(rawLabel.isEmpty ? "" : " (\(rawLabel))")"
                : rawLabel

            if let serving = ProviderFoodServing.serving(
                label: label,
                grams: servingGrams
            ) {
                result.append(serving)
            }

            if let unit = requestedQuantity.unit,
               discreteServingUnits.contains(unit),
               !label.lowercased().contains(unit),
               let alias = ProviderFoodServing.serving(
                   label: "1 \(unit)",
                   grams: servingGrams
               ) {
                result.append(alias)
            }
        }

        if let packageGrams = ProviderFoodServing.grams(
            value: product.productQuantity,
            unit: product.productQuantityUnit
        ) {
            let rawQuantity = product.quantity?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let packageLabel = "1 package\(rawQuantity.isEmpty ? "" : " (\(rawQuantity))")"
            if let package = ProviderFoodServing.serving(
                label: packageLabel,
                grams: packageGrams,
                isPackage: true
            ) {
                result.append(package)
            }

            if let unit = requestedQuantity.unit,
               packageUnits.contains(unit),
               unit != "package",
               let alias = ProviderFoodServing.serving(
                   label: "1 \(unit)\(rawQuantity.isEmpty ? "" : " (\(rawQuantity))")",
                   grams: packageGrams,
                   isPackage: true
               ) {
                result.append(alias)
            }
        }

        var seenLabels: Set<String> = []
        return result.filter {
            seenLabels.insert(QuantityParser.normalize($0.label)).inserted
        }
    }

    private var discreteServingUnits: Set<String> {
        [
            "bar", "piece", "slice", "container", "packet", "bag", "bottle",
            "can", "jar", "roll", "cracker", "cookie", "portion", "serving"
        ]
    }

    private var packageUnits: Set<String> {
        ["package", "container", "packet", "bag", "bottle", "can", "jar"]
    }

    private func nutrientsPer100g(from nutriments: OpenFoodFactsNutriments?) -> OpenFoodFactsNutrients? {
        guard let calories = nutriments?.energyKcal100g else { return nil }
        return OpenFoodFactsNutrients(
            calories: calories,
            protein: nutriments?.proteins100g ?? 0,
            carbs: nutriments?.carbohydrates100g ?? 0,
            fat: nutriments?.fat100g ?? 0
        )
    }

    private func displayName(for product: OpenFoodFactsProduct) -> String {
        let name = product.productName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Packaged food"
        let brand = product.brands?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if brand.isEmpty { return titleCased(name) }
        return titleCased("\(brand) \(name)")
    }

    private func titleCased(_ value: String) -> String {
        value
            .lowercased()
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}

private struct OpenFoodFactsSearchResponse: Decodable {
    let products: [OpenFoodFactsProduct]
}

private struct OpenFoodFactsProduct: Decodable {
    let code: String?
    let productName: String?
    let brands: String?
    let quantity: String?
    let productQuantity: Double?
    let productQuantityUnit: String?
    let servingSize: String?
    let servingQuantity: Double?
    let servingQuantityUnit: String?
    let nutriments: OpenFoodFactsNutriments?

    enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case brands
        case quantity
        case productQuantity = "product_quantity"
        case productQuantityUnit = "product_quantity_unit"
        case servingSize = "serving_size"
        case servingQuantity = "serving_quantity"
        case servingQuantityUnit = "serving_quantity_unit"
        case nutriments
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try? container.decode(String.self, forKey: .code)
        productName = try? container.decode(String.self, forKey: .productName)
        brands = try? container.decode(String.self, forKey: .brands)
        quantity = try? container.decode(String.self, forKey: .quantity)
        productQuantity = container.flexibleDouble(forKey: .productQuantity)
        productQuantityUnit = try? container.decode(String.self, forKey: .productQuantityUnit)
        servingSize = try? container.decode(String.self, forKey: .servingSize)
        servingQuantity = container.flexibleDouble(forKey: .servingQuantity)
        servingQuantityUnit = try? container.decode(String.self, forKey: .servingQuantityUnit)
        nutriments = try? container.decode(OpenFoodFactsNutriments.self, forKey: .nutriments)
    }
}

private struct OpenFoodFactsNutriments: Decodable {
    let energyKcal100g: Double?
    let proteins100g: Double?
    let carbohydrates100g: Double?
    let fat100g: Double?

    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case proteins100g = "proteins_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case fat100g = "fat_100g"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        energyKcal100g = container.flexibleDouble(forKey: .energyKcal100g)
        proteins100g = container.flexibleDouble(forKey: .proteins100g)
        carbohydrates100g = container.flexibleDouble(forKey: .carbohydrates100g)
        fat100g = container.flexibleDouble(forKey: .fat100g)
    }
}

private struct OpenFoodFactsNutrients {
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
}

private extension KeyedDecodingContainer {
    func flexibleDouble(forKey key: Key) -> Double? {
        if let value = try? decode(Double.self, forKey: key) {
            return value
        }
        if let value = try? decode(Int.self, forKey: key) {
            return Double(value)
        }
        if let value = try? decode(String.self, forKey: key) {
            return Double(value.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }
}
