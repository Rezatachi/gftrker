import Foundation

struct FoodCorrectionMemoryService: FoodParsingService {
    let parser: FoodParsingService
    let store: FoodCorrectionStore

    func parseFoodLogMessage(_ text: String) async throws -> ParsedFoodResult {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { throw FoodParsingError.emptyMessage }

        let phrases = QuantityParser.splitFoodPhrases(trimmedText)
        guard !phrases.isEmpty else { throw FoodParsingError.emptyMessage }

        var items: [ParsedFoodItem] = []
        for phrase in phrases {
            let normalizedPhrase = FoodCorrection.normalized(phrase)
            if let corrections = try? await store.corrections(matching: normalizedPhrase),
               let correction = corrections.max(by: { lhs, rhs in
                   if lhs.useCount == rhs.useCount {
                       if lhs.confidence == rhs.confidence {
                           return lhs.updatedAt < rhs.updatedAt
                       }
                       return lhs.confidence < rhs.confidence
                   }
                   return lhs.useCount < rhs.useCount
               }) {
                items.append(correction.parsedItem(sourcePhrase: phrase))
                continue
            }

            if let parsed = try? await parser.parseFoodLogMessage(phrase) {
                items.append(contentsOf: parsed.items.map { item in
                    var item = item
                    if item.sourcePhrase == nil {
                        item.sourcePhrase = phrase
                    }
                    return item
                })
            }
        }

        guard !items.isEmpty else {
            throw FoodParsingError.needsClarification("I am not totally sure what you meant. Can you add serving sizes?")
        }

        return ParsedFoodResult(originalText: trimmedText, items: items)
    }

    func rememberCorrections(from result: ParsedFoodResult) async {
        for item in result.items {
            let sourcePhrase = item.sourcePhrase ?? result.originalText
            guard let correction = FoodCorrectionRecord(parsedItem: item, originalPhrase: sourcePhrase) else {
                continue
            }

            try? await store.save(correction)
        }
    }
}
