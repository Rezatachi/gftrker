import Foundation

struct FoodParsingRouter: FoodParsingService {
    let preferLocalParsing: Bool
    let aiFallbackEnabled: Bool
    let localLLMEnabled: Bool
    let ollamaBaseURL: String
    let ollamaModel: String
    let usdaSearchEnabled: Bool
    let usdaAPIKey: String
    let nutritionixSearchEnabled: Bool
    let nutritionixAppID: String
    let nutritionixAPIKey: String
    let openFoodFactsSearchEnabled: Bool

    private let ruleBasedService = RuleBasedFoodParsingService()
    private let localDatabaseService = LocalFoodDatabaseParsingService()
    private let smallModelService = SmallModelFoodParsingService()
#if DEBUG
    private let openAIService = OpenAIFoodParsingService()
#endif

    init(
        preferLocalParsing: Bool = true,
        aiFallbackEnabled: Bool = false,
        localLLMEnabled: Bool = false,
        ollamaBaseURL: String = AppConfiguration.defaultOllamaBaseURL,
        ollamaModel: String = AppConfiguration.defaultOllamaModel,
        usdaSearchEnabled: Bool = false,
        usdaAPIKey: String = "",
        nutritionixSearchEnabled: Bool = false,
        nutritionixAppID: String = "",
        nutritionixAPIKey: String = "",
        openFoodFactsSearchEnabled: Bool = true
    ) {
        self.preferLocalParsing = preferLocalParsing
        self.aiFallbackEnabled = aiFallbackEnabled
        self.localLLMEnabled = localLLMEnabled
        self.ollamaBaseURL = ollamaBaseURL
        self.ollamaModel = ollamaModel
        self.usdaSearchEnabled = usdaSearchEnabled
        self.usdaAPIKey = usdaAPIKey
        self.nutritionixSearchEnabled = nutritionixSearchEnabled
        self.nutritionixAppID = nutritionixAppID
        self.nutritionixAPIKey = nutritionixAPIKey
        self.openFoodFactsSearchEnabled = openFoodFactsSearchEnabled
    }

    func parseFoodLogMessage(_ text: String) async throws -> ParsedFoodResult {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { throw FoodParsingError.emptyMessage }

        var bestResult: ParsedFoodResult?
        let expectedPhraseCount = max(QuantityParser.splitFoodPhrases(trimmedText).count, 1)

        if preferLocalParsing {
            if let result = try? await ruleBasedService.parseFoodLogMessage(trimmedText), result.averageConfidence >= 0.45 {
                if result.isHighCertainty(expectedPhraseCount: expectedPhraseCount) {
                    return result
                }
                bestResult = betterResult(between: bestResult, and: result, expectedPhraseCount: expectedPhraseCount)
            }

            if let result = try? await localDatabaseService.parseFoodLogMessage(trimmedText) {
                if result.isHighCertainty(expectedPhraseCount: expectedPhraseCount) {
                    return result
                }
                bestResult = betterResult(between: bestResult, and: result, expectedPhraseCount: expectedPhraseCount)
            }

            if let bestResult, bestResult.isFastDraftReady(expectedPhraseCount: expectedPhraseCount) {
                return bestResult
            }
        }

        bestResult = await bestFallbackResult(
            for: trimmedText,
            expectedPhraseCount: expectedPhraseCount,
            currentBest: bestResult
        )

        if let bestResult {
            return bestResult
        }

        throw FoodParsingError.needsClarification("I am not totally sure what you meant. Can you add serving sizes?")
    }

    private func betterResult(
        between current: ParsedFoodResult?,
        and candidate: ParsedFoodResult,
        expectedPhraseCount: Int
    ) -> ParsedFoodResult {
        guard let current else { return candidate }
        return candidate.rankingScore(expectedPhraseCount: expectedPhraseCount) > current.rankingScore(expectedPhraseCount: expectedPhraseCount)
            ? candidate
            : current
    }

    private func bestFallbackResult(
        for text: String,
        expectedPhraseCount: Int,
        currentBest: ParsedFoodResult?
    ) async -> ParsedFoodResult? {
        await withTaskGroup(of: ParsedFoodResult?.self, returning: ParsedFoodResult?.self) { group in
            group.addTask {
                if let result = try? await smallModelService.parseFoodLogMessage(text),
                   result.averageConfidence >= 0.45 {
                    return result
                }
                return nil
            }

#if DEBUG
            if localLLMEnabled {
                group.addTask {
                    let ollamaService = OllamaFoodParsingService(baseURL: ollamaBaseURL, model: ollamaModel)
                    if let result = try? await ollamaService.parseFoodLogMessage(text),
                       result.averageConfidence >= 0.45 {
                        return result
                    }
                    return nil
                }
            }

            if nutritionixSearchEnabled {
                group.addTask {
                    let nutritionixService = NutritionixFoodParsingService(appID: nutritionixAppID, apiKey: nutritionixAPIKey)
                    if let result = try? await nutritionixService.parseFoodLogMessage(text),
                       result.averageConfidence >= 0.45 {
                        return result
                    }
                    return nil
                }
            }

            if usdaSearchEnabled {
                group.addTask {
                    let usdaService = USDAFoodCatalogService(apiKey: usdaAPIKey)
                    if let result = try? await usdaService.parseFoodLogMessage(text),
                       result.averageConfidence >= 0.45 {
                        return result
                    }
                    return nil
                }
            }

            if aiFallbackEnabled {
                group.addTask {
                    try? await openAIService.parseFoodLogMessage(text)
                }
            }
#endif

            if openFoodFactsSearchEnabled {
                group.addTask {
                    let openFoodFactsService = OpenFoodFactsParsingService()
                    if let result = try? await openFoodFactsService.parseFoodLogMessage(text),
                       result.averageConfidence >= 0.45 {
                        return result
                    }
                    return nil
                }
            }

            var bestResult = currentBest
            for await candidate in group {
                guard let candidate else { continue }
                if candidate.isHighCertainty(expectedPhraseCount: expectedPhraseCount) {
                    group.cancelAll()
                    return candidate
                }
                bestResult = betterResult(
                    between: bestResult,
                    and: candidate,
                    expectedPhraseCount: expectedPhraseCount
                )
            }

            return bestResult
        }
    }
}

private extension ParsedFoodResult {
    var averageConfidence: Double {
        guard !items.isEmpty else { return 0 }
        return items.reduce(0) { $0 + $1.confidence } / Double(items.count)
    }

    func coversExpectedPhrases(_ expectedPhraseCount: Int) -> Bool {
        items.count >= expectedPhraseCount
    }

    func rankingScore(expectedPhraseCount: Int) -> Double {
        let coverage = min(Double(items.count) / Double(max(expectedPhraseCount, 1)), 1)
        let overExtractionPenalty = max(Double(items.count - expectedPhraseCount), 0) * 0.08
        return coverage * 0.42
            + averageConfidence * 0.38
            + averageSourceReliability * 0.14
            + sourcePhraseCoverage(expectedPhraseCount: expectedPhraseCount) * 0.06
            - overExtractionPenalty
    }

    func isHighCertainty(expectedPhraseCount: Int) -> Bool {
        coversExpectedPhrases(expectedPhraseCount)
            && averageConfidence >= 0.88
            && rankingScore(expectedPhraseCount: expectedPhraseCount) >= 0.86
    }

    func isFastDraftReady(expectedPhraseCount: Int) -> Bool {
        coversExpectedPhrases(expectedPhraseCount)
            && averageConfidence >= 0.72
            && averageSourceReliability >= 0.80
            && rankingScore(expectedPhraseCount: expectedPhraseCount) >= 0.73
            && items.allSatisfy { $0.source != .needsReview }
    }

    private var averageSourceReliability: Double {
        guard !items.isEmpty else { return 0 }
        return items.reduce(0) { $0 + $1.source.reliabilityScore } / Double(items.count)
    }

    private func sourcePhraseCoverage(expectedPhraseCount: Int) -> Double {
        let phrases = Set(
            items.compactMap { item -> String? in
                guard let sourcePhrase = item.sourcePhrase else { return nil }
                let query = FoodTextScorer.searchQuery(from: sourcePhrase)
                return query.isEmpty ? nil : query
            }
        )
        return min(Double(phrases.count) / Double(max(expectedPhraseCount, 1)), 1)
    }
}

private extension FoodLogSource {
    var reliabilityScore: Double {
        switch self {
        case .correctionMemory:
            1.00
        case .nutritionix:
            0.90
        case .localDatabase:
            0.84
        case .usda:
            0.78
        case .openFoodFacts:
            0.72
        case .commonServing:
            0.70
        case .localLLM:
            0.62
        case .smallModel:
            0.58
        case .needsReview:
            0.50
        case .chat:
            0.45
        case .manual, .imported:
            0.40
        }
    }
}
