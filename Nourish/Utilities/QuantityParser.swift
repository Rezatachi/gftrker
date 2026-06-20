import Foundation

struct ParsedQuantity {
    let quantityText: String
    let unit: String?
    let multiplier: Double
    let explicitGrams: Double?
    let confidence: Double
    let isVague: Bool
}

enum QuantityParser {
    private static let numberWords: [String: Double] = [
        "zero": 0,
        "a": 1,
        "an": 1,
        "one": 1,
        "two": 2,
        "three": 3,
        "four": 4,
        "five": 5,
        "six": 6,
        "seven": 7,
        "eight": 8,
        "nine": 9,
        "ten": 10,
        "half": 0.5
    ]

    private static let units: Set<String> = [
        "cup", "cups", "tbsp", "tablespoon", "tablespoons", "tsp", "teaspoon", "teaspoons",
        "ounce", "ounces", "oz", "gram", "grams", "g", "bowl", "bowls", "plate", "plates",
        "piece", "pieces", "bar", "bars", "scoop", "scoops", "serving", "servings",
        "egg", "eggs", "banana", "bananas", "apple", "apples", "slice", "slices"
    ]

    static func parse(_ phrase: String) -> ParsedQuantity {
        let normalized = normalize(phrase)
        let tokens = normalized.split(separator: " ").map(String.init)

        if let grams = explicitGrams(in: tokens) {
            return ParsedQuantity(
                quantityText: "\(Int(grams))g",
                unit: "g",
                multiplier: 1,
                explicitGrams: grams,
                confidence: 0.96,
                isVague: false
            )
        }

        if normalized.contains("a little") {
            return ParsedQuantity(quantityText: "a little", unit: nil, multiplier: 0.55, explicitGrams: nil, confidence: 0.48, isVague: true)
        }
        if normalized.contains("a lot") {
            return ParsedQuantity(quantityText: "a lot", unit: nil, multiplier: 1.55, explicitGrams: nil, confidence: 0.50, isVague: true)
        }
        if normalized.contains("some ") || normalized == "some" {
            return ParsedQuantity(quantityText: "some", unit: nil, multiplier: 1, explicitGrams: nil, confidence: 0.52, isVague: true)
        }

        var multiplier = 1.0
        var numberToken: String?
        for token in tokens {
            if let value = Double(token) {
                multiplier = value
                numberToken = token
                break
            }
            if let value = numberWords[token] {
                multiplier = value
                numberToken = token
                break
            }
        }

        if normalized.contains("small") {
            multiplier *= 0.75
        } else if normalized.contains("large") {
            multiplier *= 1.25
        }

        let unit = tokens.first { units.contains($0) }.map(canonicalUnit)
        let quantityText = [numberToken ?? (multiplier == 1 ? "1" : formatted(multiplier)), unit]
            .compactMap { $0 }
            .joined(separator: " ")

        return ParsedQuantity(
            quantityText: quantityText.isEmpty ? "1 serving" : quantityText,
            unit: unit,
            multiplier: multiplier,
            explicitGrams: nil,
            confidence: unit == nil && numberToken == nil ? 0.62 : 0.82,
            isVague: false
        )
    }

    static func splitFoodPhrases(_ text: String) -> [String] {
        var normalized = normalize(text)
        let removablePrefixes = ["i had ", "i ate ", "had ", "ate ", "for breakfast ", "for lunch ", "for dinner ", "for snack "]
        for prefix in removablePrefixes where normalized.hasPrefix(prefix) {
            normalized.removeFirst(prefix.count)
            break
        }

        for separator in [",", ";", " and ", " with ", " plus ", " & "] {
            normalized = normalized.replacingOccurrences(of: separator, with: "|")
        }

        return normalized
            .split(separator: "|")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    static func normalize(_ text: String) -> String {
        text
            .lowercased()
            .replacingOccurrences(of: ".", with: " ")
            .replacingOccurrences(of: "!", with: " ")
            .replacingOccurrences(of: "?", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func explicitGrams(in tokens: [String]) -> Double? {
        for index in tokens.indices {
            let token = tokens[index]
            if token.hasSuffix("g"), let grams = Double(token.dropLast()) {
                return grams
            }
            if let value = Double(token), index + 1 < tokens.count {
                let next = tokens[index + 1]
                if ["g", "gram", "grams"].contains(next) {
                    return value
                }
            }
        }
        return nil
    }

    private static func canonicalUnit(_ unit: String) -> String {
        switch unit {
        case "cups": "cup"
        case "tablespoon", "tablespoons": "tbsp"
        case "teaspoon", "teaspoons": "tsp"
        case "ounces", "ounce": "oz"
        case "grams", "gram": "g"
        case "bowls": "bowl"
        case "plates": "plate"
        case "pieces": "piece"
        case "bars": "bar"
        case "scoops": "scoop"
        case "servings": "serving"
        case "eggs": "egg"
        case "bananas": "banana"
        case "apples": "apple"
        case "slices": "slice"
        default: unit
        }
    }

    private static func formatted(_ value: Double) -> String {
        value.rounded() == value ? "\(Int(value))" : String(format: "%.1f", value)
    }
}
