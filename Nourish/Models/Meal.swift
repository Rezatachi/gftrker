import Foundation
import SwiftData
import SwiftUI

enum MealType: String, CaseIterable, Codable, Identifiable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .breakfast: "sunrise.fill"
        case .lunch: "leaf.fill"
        case .dinner: "moon.stars.fill"
        case .snack: "heart.fill"
        }
    }
}

@Model
final class Meal {
    var id: UUID
    var name: String
    var mealTypeRawValue: String
    var date: Date
    var photoFileName: String?
    @Relationship(deleteRule: .cascade, inverse: \FoodItem.meal)
    var foodItems: [FoodItem]

    init(
        id: UUID = UUID(),
        name: String,
        mealType: MealType,
        date: Date = .now,
        photoFileName: String? = nil,
        foodItems: [FoodItem] = []
    ) {
        self.id = id
        self.name = name
        self.mealTypeRawValue = mealType.rawValue
        self.date = date
        self.photoFileName = photoFileName
        self.foodItems = foodItems
    }

    var mealType: MealType {
        get { MealType(rawValue: mealTypeRawValue) ?? .snack }
        set { mealTypeRawValue = newValue.rawValue }
    }

    var totalCalories: Int {
        foodItems.reduce(0) { $0 + $1.totalCalories }
    }

    var protein: Double {
        foodItems.reduce(0) { $0 + $1.protein }
    }

    var carbs: Double {
        foodItems.reduce(0) { $0 + $1.carbs }
    }

    var fat: Double {
        foodItems.reduce(0) { $0 + $1.fat }
    }
}

@Model
final class MealTemplate {
    var id: UUID
    var name: String
    var mealTypeRawValue: String
    var sortIndex: Int?
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade, inverse: \TemplateFoodItem.template)
    var foodItems: [TemplateFoodItem]

    init(
        id: UUID = UUID(),
        name: String,
        mealType: MealType,
        sortIndex: Int? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        foodItems: [TemplateFoodItem] = []
    ) {
        self.id = id
        self.name = name
        self.mealTypeRawValue = mealType.rawValue
        self.sortIndex = sortIndex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.foodItems = foodItems
    }

    var mealType: MealType {
        get { MealType(rawValue: mealTypeRawValue) ?? .snack }
        set { mealTypeRawValue = newValue.rawValue }
    }

    var totalCalories: Int {
        foodItems.reduce(0) { $0 + $1.totalCalories }
    }
}

@Model
final class TemplateFoodItem {
    var id: UUID
    var name: String
    var servingSize: String
    var quantity: Double
    var estimatedCalories: Int
    var protein: Double
    var carbs: Double
    var fat: Double
    var template: MealTemplate?

    init(
        id: UUID = UUID(),
        name: String,
        servingSize: String,
        quantity: Double = 1,
        estimatedCalories: Int,
        protein: Double = 0,
        carbs: Double = 0,
        fat: Double = 0,
        template: MealTemplate? = nil
    ) {
        self.id = id
        self.name = name
        self.servingSize = servingSize
        self.quantity = quantity
        self.estimatedCalories = estimatedCalories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.template = template
    }

    var totalCalories: Int {
        Int((Double(estimatedCalories) * quantity).rounded())
    }
}

struct DailyLog {
    let date: Date
    let meals: [Meal]
    let waterEntries: [WaterEntry]
    let settings: AppSettings

    var consumedCalories: Int {
        meals.reduce(0) { $0 + $1.totalCalories }
    }

    var remainingCalories: Int {
        max(settings.dailyCalorieGoal - consumedCalories, 0)
    }

    var glasses: Int {
        waterEntries.reduce(0) { $0 + $1.glasses }
    }

    var waterOunces: Int {
        waterEntries.reduce(0) { $0 + $1.effectiveOunces }
    }
}

@Model
final class AppSettings {
    var dailyCalorieGoal: Int
    var dailyWaterGoal: Int
    var dailyProteinGoal: Int?
    var partnerName: String?
    var favoriteBottleName: String?
    var themeVariantRawValue: String?
    var horseMotifEnabled: Bool?
    var waterRemindersEnabled: Bool
    var reminderStartHour: Int
    var reminderEndHour: Int
    var aiFallbackEnabled: Bool?
    var preferLocalParsing: Bool?

    init(
        dailyCalorieGoal: Int = 2100,
        dailyWaterGoal: Int = 80,
        dailyProteinGoal: Int? = 130,
        partnerName: String? = nil,
        favoriteBottleName: String? = "Owala",
        themeVariant: ThemeVariant = .sageGreen,
        horseMotifEnabled: Bool? = false,
        waterRemindersEnabled: Bool = false,
        reminderStartHour: Int = 9,
        reminderEndHour: Int = 20,
        aiFallbackEnabled: Bool? = false,
        preferLocalParsing: Bool? = true
    ) {
        self.dailyCalorieGoal = dailyCalorieGoal
        self.dailyWaterGoal = dailyWaterGoal
        self.dailyProteinGoal = dailyProteinGoal
        self.partnerName = partnerName
        self.favoriteBottleName = favoriteBottleName
        self.themeVariantRawValue = themeVariant.rawValue
        self.horseMotifEnabled = horseMotifEnabled
        self.waterRemindersEnabled = waterRemindersEnabled
        self.reminderStartHour = reminderStartHour
        self.reminderEndHour = reminderEndHour
        self.aiFallbackEnabled = aiFallbackEnabled
        self.preferLocalParsing = preferLocalParsing
    }

    var effectiveDailyProteinGoal: Int {
        dailyProteinGoal ?? 130
    }

    var effectiveDailyWaterGoalOunces: Int {
        dailyWaterGoal <= 20 ? dailyWaterGoal * 12 : dailyWaterGoal
    }

    var effectivePartnerName: String {
        sanitized(partnerName).isEmpty ? "her" : sanitized(partnerName)
    }

    var effectiveFavoriteBottleName: String {
        sanitized(favoriteBottleName).isEmpty ? "Owala" : sanitized(favoriteBottleName)
    }

    var themeVariant: ThemeVariant {
        get { ThemeVariant(storedValue: themeVariantRawValue) }
        set { themeVariantRawValue = newValue.rawValue }
    }

    var effectiveHorseMotifEnabled: Bool {
        horseMotifEnabled ?? false
    }

    var effectiveAIFallbackEnabled: Bool {
        aiFallbackEnabled ?? false
    }

    var effectivePreferLocalParsing: Bool {
        preferLocalParsing ?? true
    }

    private func sanitized(_ value: String?) -> String {
        value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}

enum ThemeVariant: String, CaseIterable, Identifiable, Codable {
    case sageGreen = "Sage Green"
    case babyYellow = "Baby Yellow"
    case babyBlueEspresso = "Baby Blue Espresso"

    var id: String { rawValue }

    init(storedValue: String?) {
        switch storedValue {
        case Self.sageGreen.rawValue, "Stable Morning":
            self = .sageGreen
        case Self.babyYellow.rawValue, "Ceramic Rose":
            self = .babyYellow
        case Self.babyBlueEspresso.rawValue, "Bubblegum Blue":
            self = .babyBlueEspresso
        default:
            self = .sageGreen
        }
    }

    var icon: String {
        switch self {
        case .sageGreen: "leaf.fill"
        case .babyYellow: "sun.max.fill"
        case .babyBlueEspresso: "cup.and.saucer.fill"
        }
    }

    var palette: AppTheme {
        switch self {
        case .sageGreen:
            AppTheme(
                background: LinearGradient(
                    colors: [
                        Color(red: 0.89, green: 0.94, blue: 0.83),
                        Color(red: 0.97, green: 0.94, blue: 0.85),
                        Color(red: 0.78, green: 0.86, blue: 0.70)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                accent: Color(red: 0.48, green: 0.61, blue: 0.36),
                secondaryAccent: Color(red: 0.97, green: 0.94, blue: 0.74),
                softSurface: Color(red: 0.91, green: 0.95, blue: 0.79),
                deepAccent: Color(red: 0.25, green: 0.36, blue: 0.20)
            )
        case .babyYellow:
            AppTheme(
                background: LinearGradient(
                    colors: [
                        Color(red: 1.00, green: 0.96, blue: 0.76),
                        Color(red: 1.00, green: 0.88, blue: 0.44),
                        Color(red: 0.98, green: 0.75, blue: 0.39)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                accent: Color(red: 0.96, green: 0.55, blue: 0.24),
                secondaryAccent: Color(red: 1.00, green: 0.91, blue: 0.48),
                softSurface: Color(red: 1.00, green: 0.96, blue: 0.76),
                deepAccent: Color(red: 0.47, green: 0.30, blue: 0.15)
            )
        case .babyBlueEspresso:
            AppTheme(
                background: LinearGradient(
                    colors: [
                        Color(red: 0.18, green: 0.15, blue: 0.13),
                        Color(red: 0.42, green: 0.31, blue: 0.25),
                        Color(red: 0.72, green: 0.88, blue: 0.96)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                accent: Color(red: 0.00, green: 0.55, blue: 0.84),
                secondaryAccent: Color(red: 0.87, green: 0.73, blue: 0.69),
                softSurface: Color(red: 0.84, green: 0.93, blue: 0.95),
                deepAccent: Color(red: 0.22, green: 0.25, blue: 0.32)
            )
        }
    }
}
