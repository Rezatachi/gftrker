import Foundation
import SwiftData

@Model
final class FoodItem {
    var id: UUID
    var name: String
    var servingSize: String
    var quantity: Double
    var estimatedCalories: Int
    var protein: Double
    var carbs: Double
    var fat: Double
    var quantityText: String?
    var grams: Double?
    var minSuggestedGrams: Double?
    var maxSuggestedGrams: Double?
    var confidence: Double?
    var sourceRawValue: String?
    var createdAt: Date?
    var meal: Meal?

    init(
        id: UUID = UUID(),
        name: String,
        servingSize: String,
        quantity: Double = 1,
        estimatedCalories: Int,
        protein: Double = 0,
        carbs: Double = 0,
        fat: Double = 0,
        quantityText: String? = nil,
        grams: Double? = nil,
        minSuggestedGrams: Double? = nil,
        maxSuggestedGrams: Double? = nil,
        confidence: Double? = nil,
        source: FoodLogSource = .manual,
        createdAt: Date = .now,
        meal: Meal? = nil
    ) {
        self.id = id
        self.name = name
        self.servingSize = servingSize
        self.quantity = quantity
        self.estimatedCalories = estimatedCalories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.quantityText = quantityText
        self.grams = grams
        self.minSuggestedGrams = minSuggestedGrams
        self.maxSuggestedGrams = maxSuggestedGrams
        self.confidence = confidence
        self.sourceRawValue = source.rawValue
        self.createdAt = createdAt
        self.meal = meal
    }

    var totalCalories: Int {
        Int((Double(estimatedCalories) * quantity).rounded())
    }

    var source: FoodLogSource {
        get { FoodLogSource(rawValue: sourceRawValue ?? "") ?? .manual }
        set { sourceRawValue = newValue.rawValue }
    }
}

enum FoodLogSource: String, Codable, CaseIterable {
    case manual = "Manual"
    case chat = "AI estimate"
    case localDatabase = "Matched locally"
    case commonServing = "Estimated from common serving"
    case needsReview = "Needs review"
    case smallModel = "Small model estimate"
    case localLLM = "Local AI draft"
    case usda = "USDA match"
    case nutritionix = "Nutritionix match"
    case openFoodFacts = "Open Food Facts match"
    case correctionMemory = "Saved correction"
    case imported = "Imported"
}
