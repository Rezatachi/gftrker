import Foundation
import SwiftData

@Model
final class FoodCorrection {
    var id: UUID
    var originalPhrase: String
    var normalizedPhrase: String
    var correctionKey: String
    var canonicalFoodName: String
    var sourceRawValue: String
    var usdaFDCID: Int?
    var usdaDataType: String?
    var brandOwner: String?
    var servingLabel: String
    var typicalGrams: Double
    var minSuggestedGrams: Double
    var maxSuggestedGrams: Double
    var caloriesPer100g: Double
    var proteinPer100g: Double
    var carbsPer100g: Double
    var fatPer100g: Double
    var confidence: Double
    var createdAt: Date
    var updatedAt: Date
    var lastUsedAt: Date?
    var useCount: Int

    init(
        id: UUID = UUID(),
        originalPhrase: String,
        normalizedPhrase: String? = nil,
        canonicalFoodName: String,
        source: FoodLogSource,
        usdaFDCID: Int? = nil,
        usdaDataType: String? = nil,
        brandOwner: String? = nil,
        servingLabel: String,
        typicalGrams: Double,
        minSuggestedGrams: Double,
        maxSuggestedGrams: Double,
        caloriesPer100g: Double,
        proteinPer100g: Double,
        carbsPer100g: Double = 0,
        fatPer100g: Double = 0,
        confidence: Double = 1,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        lastUsedAt: Date? = nil,
        useCount: Int = 0
    ) {
        let grams = max(typicalGrams, 1)
        let normalizedValue = normalizedPhrase ?? FoodCorrection.normalized(originalPhrase)
        self.id = id
        self.originalPhrase = originalPhrase
        self.normalizedPhrase = normalizedValue
        self.canonicalFoodName = canonicalFoodName
        self.correctionKey = FoodCorrection.correctionKey(
            normalizedPhrase: normalizedValue,
            canonicalFoodName: canonicalFoodName
        )
        self.sourceRawValue = source.rawValue
        self.usdaFDCID = usdaFDCID
        self.usdaDataType = usdaDataType
        self.brandOwner = brandOwner
        self.servingLabel = servingLabel
        self.typicalGrams = grams
        self.minSuggestedGrams = max(minSuggestedGrams, 1)
        self.maxSuggestedGrams = max(maxSuggestedGrams, grams)
        self.caloriesPer100g = caloriesPer100g
        self.proteinPer100g = proteinPer100g
        self.carbsPer100g = carbsPer100g
        self.fatPer100g = fatPer100g
        self.confidence = min(max(confidence, 0), 1)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastUsedAt = lastUsedAt
        self.useCount = useCount
    }

    var source: FoodLogSource {
        get { FoodLogSource(rawValue: sourceRawValue) ?? .manual }
        set { sourceRawValue = newValue.rawValue }
    }

    static func normalized(_ phrase: String) -> String {
        QuantityParser.normalize(phrase)
    }

    static func correctionKey(normalizedPhrase: String, canonicalFoodName: String) -> String {
        "\(normalizedPhrase)|\(normalized(canonicalFoodName))"
    }

    static func per100g(total: Double, grams: Double) -> Double {
        guard grams > 0 else { return 0 }
        return total / grams * 100
    }

    func markUsed(at date: Date = .now) {
        lastUsedAt = date
        updatedAt = date
        useCount += 1
    }

    func calories(for grams: Double) -> Int {
        Int((caloriesPer100g * max(grams, 1) / 100).rounded())
    }

    func protein(for grams: Double) -> Double {
        proteinPer100g * max(grams, 1) / 100
    }

    func carbs(for grams: Double) -> Double {
        carbsPer100g * max(grams, 1) / 100
    }

    func fat(for grams: Double) -> Double {
        fatPer100g * max(grams, 1) / 100
    }

    func makeParsedFoodItem(sourcePhrase: String? = nil) -> ParsedFoodItem {
        ParsedFoodItem(
            name: canonicalFoodName,
            sourcePhrase: sourcePhrase ?? originalPhrase,
            detectedQuantity: servingLabel,
            estimatedServing: servingLabel,
            estimatedGrams: typicalGrams,
            minSuggestedGrams: minSuggestedGrams,
            maxSuggestedGrams: maxSuggestedGrams,
            estimatedCalories: calories(for: typicalGrams),
            estimatedProtein: protein(for: typicalGrams),
            estimatedCarbs: carbs(for: typicalGrams),
            estimatedFat: fat(for: typicalGrams),
            confidence: confidence,
            source: .correctionMemory
        )
    }

    static func makeCorrection(
        from item: ParsedFoodItem,
        originalPhrase: String
    ) -> FoodCorrection? {
        let trimmedPhrase = originalPhrase.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPhrase.isEmpty, !trimmedName.isEmpty else { return nil }

        let grams = max(item.estimatedGrams, 1)
        return FoodCorrection(
            originalPhrase: trimmedPhrase,
            canonicalFoodName: trimmedName,
            source: item.source,
            servingLabel: item.estimatedServing,
            typicalGrams: grams,
            minSuggestedGrams: min(item.minSuggestedGrams, grams),
            maxSuggestedGrams: max(item.maxSuggestedGrams, grams),
            caloriesPer100g: FoodCorrection.per100g(total: Double(item.estimatedCalories), grams: grams),
            proteinPer100g: FoodCorrection.per100g(total: item.estimatedProtein, grams: grams),
            carbsPer100g: FoodCorrection.per100g(total: item.estimatedCarbs, grams: grams),
            fatPer100g: FoodCorrection.per100g(total: item.estimatedFat, grams: grams),
            confidence: item.confidence
        )
    }
}
