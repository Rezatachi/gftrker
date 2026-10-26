import Foundation

struct FoodServing: Identifiable, Hashable {
    let label: String
    let grams: Double
    let minGrams: Double
    let maxGrams: Double

    var id: String { label }
}

struct FoodNutritionEntry: Identifiable, Hashable {
    let canonicalName: String
    let aliases: [String]
    let caloriesPer100g: Double
    let proteinPer100g: Double
    let carbsPer100g: Double
    let fatPer100g: Double
    let commonServings: [FoodServing]

    var id: String { canonicalName }

    func nutrition(for grams: Double) -> NutritionEstimate {
        let scale = grams / 100
        return NutritionEstimate(
            calories: caloriesPer100g * scale,
            protein: proteinPer100g * scale,
            carbs: carbsPer100g * scale,
            fat: fatPer100g * scale
        )
    }
}

struct NutritionEstimate {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
}

struct FoodServingEstimate {
    let label: String
    let grams: Double
    let minGrams: Double
    let maxGrams: Double
    let detectedQuantity: String
    let confidence: Double
}

enum FoodServingEstimator {
    static func estimate(
        for entry: FoodNutritionEntry,
        quantity: ParsedQuantity,
        phrase: String,
        fallbackServing: FoodServing? = nil
    ) -> FoodServingEstimate {
        if let explicitGrams = quantity.explicitGrams {
            let tolerance = max(explicitGrams * 0.03, 1)
            return FoodServingEstimate(
                label: "\(Int(explicitGrams.rounded()))g",
                grams: explicitGrams,
                minGrams: max(explicitGrams - tolerance, 1),
                maxGrams: explicitGrams + tolerance,
                detectedQuantity: quantity.quantityText,
                confidence: 0.98
            )
        }

        let normalizedPhrase = QuantityParser.normalize(phrase)
        let selection = selectServing(
            for: entry,
            quantity: quantity,
            phrase: normalizedPhrase,
            fallbackServing: fallbackServing
        )
        let scale = scaleFactor(
            quantity: quantity,
            serving: selection.serving,
            selectionReason: selection.reason
        )
        let grams = max(selection.serving.grams * scale, 1)

        return FoodServingEstimate(
            label: servingLabel(
                quantity: quantity,
                serving: selection.serving,
                scale: scale
            ),
            grams: grams,
            minGrams: max(selection.serving.minGrams * scale, 1),
            maxGrams: max(selection.serving.maxGrams * scale, grams + 1),
            detectedQuantity: detectedQuantityText(
                quantity: quantity,
                serving: selection.serving,
                scale: scale
            ),
            confidence: confidence(
                quantity: quantity,
                selectionReason: selection.reason
            )
        )
    }

    private static func selectServing(
        for entry: FoodNutritionEntry,
        quantity: ParsedQuantity,
        phrase: String,
        fallbackServing: FoodServing?
    ) -> ServingSelection {
        if quantity.quantityText != "1 serving",
           let serving = entry.commonServings.first(where: {
               QuantityParser.normalize($0.label) == quantity.quantityText
           }) {
            return ServingSelection(serving: serving, reason: .exactLabel)
        }

        if phrase.contains("half"),
           let serving = entry.commonServings.first(where: { $0.label.contains("half") }) {
            return ServingSelection(serving: serving, reason: .exactLabel)
        }

        if quantity.unit == nil,
           quantity.multiplier > 1,
           let serving = countBasedServing(for: entry) {
            return ServingSelection(serving: serving, reason: .matchedUnit)
        }

        if let unit = quantity.unit,
           let serving = entry.commonServings.first(where: {
               servingMatches($0, unit: unit, foodName: entry.canonicalName)
           }) {
            return ServingSelection(serving: serving, reason: .matchedUnit)
        }

        if quantity.isVague,
           let serving = vagueServing(for: entry, phrase: phrase) {
            return ServingSelection(serving: serving, reason: .vague)
        }

        if let fallbackServing {
            return ServingSelection(serving: fallbackServing, reason: .fallbackServing)
        }

        return ServingSelection(
            serving: entry.commonServings.first
                ?? FoodServing(label: "serving", grams: 150, minGrams: 100, maxGrams: 220),
            reason: .defaultServing
        )
    }

    private static func scaleFactor(
        quantity: ParsedQuantity,
        serving: FoodServing,
        selectionReason: ServingSelectionReason
    ) -> Double {
        if selectionReason == .exactLabel {
            return 1
        }

        if selectionReason == .vague {
            return max(quantity.multiplier, 0.01)
        }

        if selectionReason == .matchedUnit {
            let servingAmount = leadingAmount(in: serving.label)
            return max(quantity.multiplier / servingAmount, 0.01)
        }

        return max(quantity.multiplier, 0.01)
    }

    private static func servingMatches(_ serving: FoodServing, unit: String, foodName: String) -> Bool {
        let label = serving.label.lowercased()
        if label.contains(unit) { return true }
        if unit == "egg", foodName == "Eggs" { return label.contains("egg") }
        if unit == "banana", foodName == "Banana" { return label.contains("banana") }
        if unit == "apple", foodName == "Apple" { return label.contains("apple") }
        if unit == "slice", label.contains("slice") { return true }
        if unit == "handful", label.contains("handful") { return true }
        if unit == "splash", label.contains("splash") { return true }
        if unit == "pinch", label.contains("pinch") { return true }
        return false
    }

    private static func vagueServing(for entry: FoodNutritionEntry, phrase: String) -> FoodServing? {
        if phrase.contains("some"),
           let serving = entry.commonServings.first(where: { $0.label == "serving" }) {
            return serving
        }
        return entry.commonServings.first(where: {
            ["handful", "splash", "small bowl"].contains($0.label)
        })
    }

    private static func countBasedServing(for entry: FoodNutritionEntry) -> FoodServing? {
        entry.commonServings.first(where: { serving in
            let normalized = QuantityParser.normalize(serving.label)
            guard leadingAmount(in: normalized) == 1 else { return false }
            return [
                "piece", "egg", "banana", "apple", "bar", "bun", "roll",
                "bite", "slice", "rice ball", "sandwich", "burger", "shot"
            ].contains(where: normalized.contains)
        })
    }

    private static func leadingAmount(in label: String) -> Double {
        guard let firstToken = QuantityParser.normalize(label).split(separator: " ").first else {
            return 1
        }

        let token = String(firstToken)
        if token == "half" { return 0.5 }
        if token == "quarter" { return 0.25 }
        if let number = Double(token), number > 0 { return number }

        let parts = token.split(separator: "/", omittingEmptySubsequences: false)
        if parts.count == 2,
           let numerator = Double(parts[0]),
           let denominator = Double(parts[1]),
           denominator > 0 {
            return numerator / denominator
        }
        return 1
    }

    private static func servingLabel(
        quantity: ParsedQuantity,
        serving: FoodServing,
        scale: Double
    ) -> String {
        if quantity.quantityText != "1 serving", !quantity.isVague {
            return quantity.quantityText
        }
        guard scale != 1 else { return serving.label }
        let formatted = scale.rounded() == scale ? "\(Int(scale))" : String(format: "%.2g", scale)
        return "\(formatted) \(serving.label)"
    }

    private static func detectedQuantityText(
        quantity: ParsedQuantity,
        serving: FoodServing,
        scale: Double
    ) -> String {
        if quantity.quantityText != "1 serving" {
            return quantity.quantityText
        }
        return servingLabel(quantity: quantity, serving: serving, scale: scale)
    }

    private static func confidence(
        quantity: ParsedQuantity,
        selectionReason: ServingSelectionReason
    ) -> Double {
        switch selectionReason {
        case .exactLabel:
            return 0.96
        case .matchedUnit:
            return 0.90
        case .vague:
            return 0.64
        case .defaultServing:
            return quantity.quantityText == "1 serving" ? 0.62 : 0.72
        case .fallbackServing:
            return quantity.isVague ? 0.46 : 0.56
        }
    }
}

enum ProviderFoodServing {
    static func serving(
        label: String,
        grams: Double,
        neighboringGramWeights: [Double] = [],
        isPackage: Bool = false
    ) -> FoodServing? {
        guard grams.isFinite, grams > 0 else { return nil }

        let normalizedLabel = QuantityParser.normalize(label)
        let tolerance = relativeTolerance(
            for: normalizedLabel,
            isPackage: isPackage
        )
        var minGrams = max(grams * (1 - tolerance), 1)
        var maxGrams = grams * (1 + tolerance)

        if !containsSizeDescriptor(normalizedLabel) {
            let plausibleNeighbors = neighboringGramWeights.filter {
                $0.isFinite && $0 > 0 && $0 >= grams * 0.60 && $0 <= grams * 1.65
            }
            if let lower = plausibleNeighbors.filter({ $0 < grams }).max() {
                minGrams = min(minGrams, lower)
            }
            if let upper = plausibleNeighbors.filter({ $0 > grams }).min() {
                maxGrams = max(maxGrams, upper)
            }
        }

        return FoodServing(
            label: label,
            grams: grams,
            minGrams: minGrams,
            maxGrams: max(maxGrams, grams + 1)
        )
    }

    static func fallback(for quantity: ParsedQuantity) -> FoodServing {
        let unit = quantity.unit
        let (label, grams, tolerance): (String, Double, Double) = switch unit {
        case "oz": ("1 oz", 28.3495, 0.04)
        case "cup": ("1 cup", 240, 0.30)
        case "bowl": ("1 bowl", 380, 0.38)
        case "plate": ("1 plate", 420, 0.38)
        case "piece": ("1 piece", 45, 0.30)
        case "slice": ("1 slice", 35, 0.28)
        case "bar": ("1 bar", 55, 0.20)
        case "tbsp": ("1 tbsp", 16, 0.18)
        case "tsp": ("1 tsp", 5, 0.18)
        case "scoop": ("1 scoop", 31, 0.25)
        case "egg": ("1 egg", 50, 0.18)
        case "banana": ("1 banana", 118, 0.22)
        case "apple": ("1 apple", 180, 0.24)
        case "handful": ("1 handful", 30, 0.40)
        case "pinch": ("1 pinch", 1, 0.50)
        case "splash": ("1 splash", 30, 0.55)
        case "container": ("1 container", 150, 0.30)
        case "package": ("1 package", 100, 0.40)
        case "packet": ("1 packet", 35, 0.30)
        case "bag": ("1 bag", 32, 0.30)
        case "bottle": ("1 bottle", 355, 0.25)
        case "can": ("1 can", 355, 0.25)
        case "jar": ("1 jar", 300, 0.35)
        case "fillet": ("1 fillet", 160, 0.30)
        case "drink": ("1 drink", 240, 0.35)
        case "roll": ("1 roll", 190, 0.30)
        case "shake": ("1 shake", 330, 0.35)
        case "cracker": ("1 cracker", 10, 0.35)
        case "cookie": ("1 cookie", 30, 0.35)
        case "sandwich": ("1 sandwich", 220, 0.30)
        case "wrap": ("1 wrap", 240, 0.30)
        case "burger": ("1 burger", 230, 0.30)
        case "shot": ("1 shot", 44, 0.15)
        case "glass": ("1 glass", 240, 0.30)
        case "portion", "serving": ("1 serving", 150, 0.40)
        default: ("1 serving", 150, 0.45)
        }

        return FoodServing(
            label: label,
            grams: grams,
            minGrams: max(grams * (1 - tolerance), 1),
            maxGrams: grams * (1 + tolerance)
        )
    }

    static func grams(value: Double?, unit: String?) -> Double? {
        guard let value, value.isFinite, value > 0 else { return nil }
        switch QuantityParser.normalize(unit ?? "g") {
        case "g", "gram", "grams":
            return value
        case "kg", "kilogram", "kilograms":
            return value * 1_000
        case "oz", "ounce", "ounces":
            return value * 28.3495
        case "lb", "pound", "pounds":
            return value * 453.592
        case "ml", "milliliter", "milliliters", "millilitre", "millilitres":
            return value
        case "cl":
            return value * 10
        case "l", "liter", "liters", "litre", "litres":
            return value * 1_000
        default:
            return nil
        }
    }

    private static func relativeTolerance(for label: String, isPackage: Bool) -> Double {
        if isPackage { return 0.05 }
        if isWeightLabel(label) {
            return 0.04
        }
        if ["cup", "tbsp", "tsp", "ml", "fl oz"].contains(where: label.contains) {
            return 0.10
        }
        if ["piece", "slice", "egg", "cookie", "cracker", "fillet"].contains(where: label.contains) {
            return 0.14
        }
        return 0.18
    }

    private static func isWeightLabel(_ label: String) -> Bool {
        let tokens = label.split(separator: " ").map(String.init)
        if tokens.contains(where: {
            ["g", "gram", "grams", "kg", "kilogram", "kilograms", "oz", "ounce", "ounces"].contains($0)
        }) {
            return true
        }
        guard let finalToken = tokens.last else { return false }
        for suffix in ["kg", "oz", "g"] where finalToken.hasSuffix(suffix) {
            let numericPart = finalToken.dropLast(suffix.count)
            if Double(numericPart) != nil {
                return true
            }
        }
        return false
    }

    private static func containsSizeDescriptor(_ label: String) -> Bool {
        ["small", "medium", "large", "mini", "thin", "thick", "half", "quarter"]
            .contains(where: label.contains)
    }
}

private struct ServingSelection {
    let serving: FoodServing
    let reason: ServingSelectionReason
}

private enum ServingSelectionReason {
    case exactLabel
    case matchedUnit
    case vague
    case fallbackServing
    case defaultServing
}
