import Foundation

struct FoodMatch {
    let entry: FoodNutritionEntry
    let matchedAlias: String
    let confidence: Double
}

enum FoodMatcher {
    static func matches(in phrase: String, database: [FoodNutritionEntry] = LocalFoodDatabase.entries) -> [FoodMatch] {
        let normalizedPhrase = QuantityParser.normalize(phrase)
        let phraseTokens = Set(normalizedPhrase.split(separator: " ").map(String.init))
        var matches: [FoodMatch] = []

        for entry in database {
            let sortedAliases = entry.aliases.sorted { $0.count > $1.count }
            if let exactAlias = sortedAliases.first(where: { normalizedPhrase.contains($0) }) {
                matches.append(FoodMatch(entry: entry, matchedAlias: exactAlias, confidence: exactAlias == normalizedPhrase ? 0.94 : 0.88))
                continue
            }

            let bestTokenScore = sortedAliases.map { alias in
                let aliasTokens = Set(alias.split(separator: " ").map(String.init))
                guard !aliasTokens.isEmpty else { return 0.0 }
                let overlap = aliasTokens.intersection(phraseTokens).count
                return Double(overlap) / Double(aliasTokens.count)
            }.max() ?? 0

            if bestTokenScore >= 0.67, let alias = sortedAliases.first {
                matches.append(FoodMatch(entry: entry, matchedAlias: alias, confidence: 0.64 + min(bestTokenScore, 1) * 0.20))
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
}

private extension Array where Element == FoodMatch {
    func removingCoveredShortAliases() -> [FoodMatch] {
        var accepted: [FoodMatch] = []
        for match in self {
            let isCovered = accepted.contains { existing in
                existing.matchedAlias != match.matchedAlias
                    && existing.matchedAlias.contains(match.matchedAlias)
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
