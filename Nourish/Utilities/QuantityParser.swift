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
        "half": 0.5,
        "quarter": 0.25,
        "quarters": 0.25
    ]

    private static let unicodeFractions: [String: String] = [
        "¼": " 1/4 ",
        "½": " 1/2 ",
        "¾": " 3/4 ",
        "⅓": " 1/3 ",
        "⅔": " 2/3 ",
        "⅛": " 1/8 ",
        "⅜": " 3/8 ",
        "⅝": " 5/8 ",
        "⅞": " 7/8 "
    ]

    private static let chineseNumbers: [Character: Double] = [
        "零": 0,
        "一": 1,
        "二": 2,
        "两": 2,
        "三": 3,
        "四": 4,
        "五": 5,
        "六": 6,
        "七": 7,
        "八": 8,
        "九": 9,
        "十": 10,
        "半": 0.5
    ]

    private static let units: Set<String> = [
        "cup", "cups", "tbsp", "tablespoon", "tablespoons", "tsp", "teaspoon", "teaspoons",
        "ounce", "ounces", "oz", "gram", "grams", "g", "bowl", "bowls", "plate", "plates",
        "piece", "pieces", "bar", "bars", "scoop", "scoops", "serving", "servings",
        "egg", "eggs", "banana", "bananas", "apple", "apples", "slice", "slices",
        "handful", "handfuls", "pinch", "pinches", "splash", "splashes",
        "container", "containers", "package", "packages", "packet", "packets",
        "bag", "bags", "bottle", "bottles", "can", "cans", "jar", "jars",
        "fillet", "fillets", "drink", "drinks", "roll", "rolls", "shake", "shakes",
        "cracker", "crackers", "cookie", "cookies", "sandwich", "sandwiches",
        "wrap", "wraps", "burger", "burgers", "shot", "shots", "glass", "glasses",
        "portion", "portions"
    ]

    private static let chineseUnits: [Character: String] = [
        "碗": "bowl",
        "杯": "cup",
        "个": "piece",
        "颗": "piece",
        "片": "slice",
        "份": "serving",
        "根": "piece",
        "条": "piece",
        "勺": "scoop",
        "匙": "tbsp",
        "克": "g"
    ]

    static func parse(_ phrase: String) -> ParsedQuantity {
        let normalized = normalize(phrase)
        let tokens = normalized.split(separator: " ").map(String.init)

        if let chineseQuantity = parseChineseQuantity(normalized) {
            return chineseQuantity
        }

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

        if let vagueUnit = tokens.first(where: { ["handful", "handfuls", "pinch", "pinches", "splash", "splashes"].contains($0) }) {
            return ParsedQuantity(
                quantityText: canonicalUnit(vagueUnit),
                unit: canonicalUnit(vagueUnit),
                multiplier: 1,
                explicitGrams: nil,
                confidence: 0.72,
                isVague: true
            )
        }

        let parsedAmount = parseAmount(in: tokens)
        var multiplier = parsedAmount?.value ?? 1.0
        let numberToken = parsedAmount?.text

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
            confidence: unit == nil && numberToken == nil ? 0.62 : 0.86,
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

        for separator in [",", ";", "，", "、", "；", " and ", " with ", " plus ", " & ", " 和 ", "和", " 还有 ", "还有", " 加 ", "加"] {
            normalized = normalized.replacingOccurrences(of: separator, with: "|")
        }

        return normalized
            .split(separator: "|")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    static func normalize(_ text: String) -> String {
        var normalized = text
            .lowercased()
            .preservingDecimalPoints()
            .replacingOccurrences(of: "one half", with: "1/2")
            .replacingOccurrences(of: "a half", with: "1/2")
            .replacingOccurrences(of: "half a ", with: "1/2 ")
            .replacingOccurrences(of: "half an ", with: "1/2 ")
            .replacingOccurrences(of: "one quarter", with: "1/4")
            .replacingOccurrences(of: "a quarter", with: "1/4")
            .replacingOccurrences(of: "quarter of a", with: "1/4")
            .replacingOccurrences(of: "three quarters", with: "3/4")
            .replacingOccurrences(of: "three quarter", with: "3/4")
            .replacingOccurrences(of: "__decimal_point__", with: ".")
            .replacingOccurrences(of: "!", with: " ")
            .replacingOccurrences(of: "?", with: " ")
            .replacingOccurrences(of: "。", with: " ")
            .replacingOccurrences(of: "！", with: " ")
            .replacingOccurrences(of: "？", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        for (fraction, replacement) in unicodeFractions {
            normalized = normalized.replacingOccurrences(of: fraction, with: replacement)
        }

        while normalized.contains("  ") {
            normalized = normalized.replacingOccurrences(of: "  ", with: " ")
        }
        return normalized.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func parseChineseQuantity(_ text: String) -> ParsedQuantity? {
        let characters = Array(text)
        for index in characters.indices {
            let character = characters[index]
            guard let unit = chineseUnits[character] else { continue }

            let previous = index > 0 ? characters[index - 1] : nil
            let multiplier = previous.flatMap { chineseNumbers[$0] } ?? 1
            let quantityText = unit == "g" ? "\(Int(multiplier))g" : "\(formatted(multiplier)) \(unit)"

            return ParsedQuantity(
                quantityText: quantityText,
                unit: unit,
                multiplier: multiplier,
                explicitGrams: unit == "g" ? multiplier : nil,
                confidence: previous == nil ? 0.68 : 0.84,
                isVague: false
            )
        }

        if text.contains("一些") || text.contains("有点") {
            return ParsedQuantity(quantityText: "some", unit: nil, multiplier: 1, explicitGrams: nil, confidence: 0.50, isVague: true)
        }

        return nil
    }

    private static func explicitGrams(in tokens: [String]) -> Double? {
        for index in tokens.indices {
            let token = tokens[index]
            if token.hasSuffix("g"), let grams = parseNumericValue(String(token.dropLast())) {
                return grams
            }
            if let value = parseNumericValue(token), index + 1 < tokens.count {
                let next = tokens[index + 1]
                if ["g", "gram", "grams"].contains(next) {
                    return value
                }
            }
        }
        return nil
    }

    private static func parseAmount(in tokens: [String]) -> (value: Double, text: String)? {
        for index in tokens.indices {
            let token = tokens[index]

            if let whole = parseWholeNumber(token),
               index + 1 < tokens.count,
               let fraction = parseFraction(tokens[index + 1]) {
                return (whole + fraction, "\(formatted(whole)) \(tokens[index + 1])")
            }

            if let value = parseNumericValue(token) {
                return (value, quantityTokenText(token, value: value))
            }

            if token == "half" {
                return (0.5, "1/2")
            }

            if token == "quarter" || token == "quarters" {
                return (0.25, "1/4")
            }

            if let value = numberWords[token] {
                return (value, token)
            }
        }

        return nil
    }

    private static func parseNumericValue(_ token: String) -> Double? {
        if let decimal = Double(token) {
            return decimal
        }
        return parseFraction(token)
    }

    private static func parseWholeNumber(_ token: String) -> Double? {
        if let value = Double(token), value.rounded() == value {
            return value
        }
        if let value = numberWords[token], value.rounded() == value {
            return value
        }
        return nil
    }

    private static func parseFraction(_ token: String) -> Double? {
        let parts = token.split(separator: "/", omittingEmptySubsequences: false)
        guard parts.count == 2,
              let numerator = Double(parts[0]),
              let denominator = Double(parts[1]),
              denominator != 0 else {
            return nil
        }
        return numerator / denominator
    }

    private static func quantityTokenText(_ token: String, value: Double) -> String {
        if token.contains("/") {
            return token
        }
        return formatted(value)
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
        case "handfuls": "handful"
        case "pinches": "pinch"
        case "splashes": "splash"
        case "containers": "container"
        case "packages": "package"
        case "packets": "packet"
        case "bags": "bag"
        case "bottles": "bottle"
        case "cans": "can"
        case "jars": "jar"
        case "fillets": "fillet"
        case "drinks": "drink"
        case "rolls": "roll"
        case "shakes": "shake"
        case "crackers": "cracker"
        case "cookies": "cookie"
        case "sandwiches": "sandwich"
        case "wraps": "wrap"
        case "burgers": "burger"
        case "shots": "shot"
        case "glasses": "glass"
        case "portions": "portion"
        default: unit
        }
    }

    private static func formatted(_ value: Double) -> String {
        value.rounded() == value ? "\(Int(value))" : String(format: "%.1f", value)
    }
}

private extension String {
    func preservingDecimalPoints() -> String {
        let characters = Array(self)
        var result = ""

        for index in characters.indices {
            let character = characters[index]
            if character == "." {
                let previousIsNumber = index > characters.startIndex && characters[characters.index(before: index)].isNumber
                let nextIsNumber = index < characters.index(before: characters.endIndex) && characters[characters.index(after: index)].isNumber
                result += previousIsNumber && nextIsNumber ? "__decimal_point__" : " "
            } else {
                result.append(character)
            }
        }

        return result
    }
}
