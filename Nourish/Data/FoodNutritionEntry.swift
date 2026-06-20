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
