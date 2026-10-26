import Foundation

struct FoodMatch {
    let entry: FoodNutritionEntry
    let matchedAlias: String
    let confidence: Double
}

enum FoodMatcher {
    static func matches(in phrase: String, database: [FoodNutritionEntry] = LocalFoodDatabase.entries) -> [FoodMatch] {
        let normalizedPhrase = QuantityParser.normalize(phrase)
        let phraseTokens = Set(FoodTextScorer.foodTokens(for: normalizedPhrase))
        guard !phraseTokens.isEmpty else { return [] }

        var matches: [FoodMatch] = []

        for entry in database {
            let sortedAliases = entry.aliases.sorted { $0.count > $1.count }
            let bestCandidate = sortedAliases.compactMap { alias -> FoodMatch? in
                guard let confidence = confidence(for: alias, in: normalizedPhrase, phraseTokens: phraseTokens) else {
                    return nil
                }
                return FoodMatch(entry: entry, matchedAlias: alias, confidence: confidence)
            }.max { lhs, rhs in
                if lhs.confidence == rhs.confidence {
                    return lhs.matchedAlias.count < rhs.matchedAlias.count
                }
                return lhs.confidence < rhs.confidence
            }

            if let bestCandidate {
                matches.append(bestCandidate)
            }
        }

        return matches
            .sorted { lhs, rhs in
                if lhs.confidence == rhs.confidence {
                    return lhs.matchedAlias.count > rhs.matchedAlias.count
                }
                return lhs.confidence > rhs.confidence
            }
            .removingCoveredShortAliases()
            .deduplicatedByFoodName()
    }

    private static func confidence(
        for alias: String,
        in normalizedPhrase: String,
        phraseTokens: Set<String>
    ) -> Double? {
        let normalizedAlias = QuantityParser.normalize(alias)
        let aliasTokens = Set(FoodTextScorer.foodTokens(for: normalizedAlias))
        guard !aliasTokens.isEmpty else { return nil }

        if normalizedAlias.containsCJKCharacters,
           normalizedPhrase.contains(normalizedAlias) {
            return 0.94
        }

        let aliasTokenCount = aliasTokens.count
        let overlapCount = phraseTokens.intersection(aliasTokens).count
        guard overlapCount > 0 else { return nil }

        let tokenCoverage = Double(overlapCount) / Double(aliasTokenCount)
        let phraseCoverage = Double(overlapCount) / Double(max(phraseTokens.count, 1))
        let aliasLengthBoost = min(Double(aliasTokenCount) * 0.05, 0.15)

        let exactPhraseMatch = phraseTokens == aliasTokens
        if exactPhraseMatch {
            return normalizedPhrase.hasWholeWordSequence(normalizedAlias) ? 0.97 : 0.95
        }

        if aliasTokenCount > 1, tokenCoverage < 0.67 {
            return nil
        }

        if aliasTokenCount > phraseTokens.count, tokenCoverage < 1 {
            return nil
        }

        let containsWholePhrase = normalizedPhrase.hasWholeWordSequence(normalizedAlias)
        let baseScore: Double
        if containsWholePhrase {
            baseScore = 0.84 + min(Double(aliasTokenCount) * 0.03, 0.08)
        } else {
            baseScore = 0.58 + tokenCoverage * 0.25 + phraseCoverage * 0.10
        }

        let penalty: Double
        if aliasTokenCount == 1, phraseTokens.count > 1 {
            penalty = 0.10
        } else if aliasTokenCount == 2, phraseTokens.count > 3 {
            penalty = 0.03
        } else {
            penalty = 0
        }

        let score = baseScore + aliasLengthBoost - penalty
        let threshold = aliasTokenCount == 1 ? 0.80 : 0.68
        return score >= threshold ? min(score, 0.97) : nil
    }
}

enum FoodTextScorer {
    private static let quantityWords: Set<String> = [
        "zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
        "half", "quarter", "quarters"
    ]

    private static let fillerWords: Set<String> = [
        "i", "me", "my", "had", "ate", "eat", "eating", "for", "breakfast", "lunch", "dinner", "snack",
        "a", "an", "the", "of", "about", "around", "roughly", "maybe", "approximately",
        "some", "little", "lot", "small", "medium", "large", "and", "with", "plus"
    ]

    private static let measurementWords: Set<String> = [
        "cup", "cups", "tbsp", "tablespoon", "tablespoons", "tsp", "teaspoon", "teaspoons",
        "ounce", "ounces", "oz", "gram", "grams", "g", "bowl", "bowls", "plate", "plates",
        "piece", "pieces", "scoop", "scoops", "serving", "servings", "slice", "slices",
        "handful", "handfuls", "pinch", "pinches", "splash", "splashes", "container",
        "containers", "jar", "jars", "bag", "bags", "shot", "shots", "glass", "glasses",
        "bottle", "bottles"
    ]

    static func foodTokens(for text: String) -> [String] {
        normalizedTokens(for: text).filter { !isNonFoodToken($0) }
    }

    static func searchQuery(from phrase: String) -> String {
        let normalized = QuantityParser.normalize(phrase)
        let tokens = foodTokens(for: normalized)
        return tokens.isEmpty ? normalized : tokens.joined(separator: " ")
    }

    static func lexicalScore(candidateText: String, query: String) -> Double {
        let candidateTokens = Set(foodTokens(for: candidateText))
        let queryTokens = Set(foodTokens(for: query))
        guard !candidateTokens.isEmpty, !queryTokens.isEmpty else { return 0 }

        let overlapCount = queryTokens.intersection(candidateTokens).count
        let queryCoverage = Double(overlapCount) / Double(queryTokens.count)
        let candidateCoverage = Double(overlapCount) / Double(candidateTokens.count)
        let normalizedCandidate = QuantityParser.normalize(candidateText)
        let normalizedQuery = QuantityParser.normalize(query)
        let exactBoost = normalizedCandidate.hasWholeWordSequence(normalizedQuery) ? 0.30 : 0

        return queryCoverage * 0.62 + candidateCoverage * 0.18 + exactBoost
    }

    private static func normalizedTokens(for text: String) -> [String] {
        QuantityParser.normalize(text)
            .split(separator: " ")
            .map { token in
                String(token).trimmingCharacters(in: .punctuationCharacters)
            }
            .filter { !$0.isEmpty }
    }

    private static func isNonFoodToken(_ token: String) -> Bool {
        fillerWords.contains(token)
            || measurementWords.contains(token)
            || quantityWords.contains(token)
            || parseFraction(token) != nil
            || Double(token) != nil
    }

    private static func parseFraction(_ token: String) -> Double? {
        let parts = token.split(separator: "/", omittingEmptySubsequences: false)
        guard parts.count == 2,
              Double(parts[0]) != nil,
              let denominator = Double(parts[1]),
              denominator != 0 else {
            return nil
        }
        return 1
    }
}

private extension Array where Element == FoodMatch {
    func removingCoveredShortAliases() -> [FoodMatch] {
        var accepted: [FoodMatch] = []
        for match in self {
            let isCovered = accepted.contains { existing in
                existing.matchedAlias != match.matchedAlias
                    && existing.matchedAlias.count >= match.matchedAlias.count
                    && existing.matchedAlias.hasWholeWordSequence(match.matchedAlias)
                    && existing.confidence >= match.confidence - 0.03
            }
            if !isCovered {
                accepted.append(match)
            }
        }
        return accepted
    }

    func deduplicatedByFoodName() -> [FoodMatch] {
        var seen = Set<String>()
        return filter { match in
            guard !seen.contains(match.entry.canonicalName) else { return false }
            seen.insert(match.entry.canonicalName)
            return true
        }
    }
}

private extension String {
    func hasWholeWordSequence(_ needle: String) -> Bool {
        let haystack = " \(self) "
        let target = " \(needle) "
        return haystack.contains(target)
    }

    var containsCJKCharacters: Bool {
        unicodeScalars.contains { scalar in
            switch scalar.value {
            case 0x3400...0x4DBF, 0x4E00...0x9FFF, 0xF900...0xFAFF:
                return true
            default:
                return false
            }
        }
    }
}
