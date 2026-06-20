import Foundation

struct TodayCopy {
    let headline: String
    let subtitle: String
    let calorieTitle: String
    let calorieDetail: String
    let hydrationTitle: String
    let emptyMealTitle: String
    let emptyMealDetail: String
    let primaryAction: String
    let firstInsightTitle: String
    let firstInsightValue: String
    let secondInsightTitle: String
    let secondInsightValue: String
}

enum PersonalizedCopyService {
    static func todayCopy(
        settings: AppSettings,
        consumedCalories: Int,
        calorieGoal: Int,
        consumedProtein: Int,
        proteinGoal: Int,
        waterOunces: Int,
        waterGoalOunces: Int,
        mealCount: Int,
        date: Date = .now
    ) -> TodayCopy {
        let name = settings.effectivePartnerName == "her" ? nil : settings.effectivePartnerName
        let bottle = settings.effectiveFavoriteBottleName
        let hour = Calendar.app.component(.hour, from: date)

        let headline = headline(name: name, hour: hour, theme: settings.themeVariant)
        let subtitle = subtitle(mealCount: mealCount, waterOunces: waterOunces, waterGoalOunces: waterGoalOunces)
        let remaining = max(calorieGoal - consumedCalories, 0)
        let proteinRemaining = max(proteinGoal - consumedProtein, 0)

        return TodayCopy(
            headline: headline,
            subtitle: subtitle,
            calorieTitle: calorieTitle(consumedProtein: consumedProtein, proteinGoal: proteinGoal),
            calorieDetail: remaining == 0 ? "You reached your calorie target for today." : "\(remaining) calories left for the day.",
            hydrationTitle: "\(bottle) check",
            emptyMealTitle: emptyMealTitle(theme: settings.themeVariant),
            emptyMealDetail: "Start with one quick note. A close estimate is enough.",
            primaryAction: "Log in plain English",
            firstInsightTitle: proteinRemaining == 0 ? "Protein handled" : "Protein check",
            firstInsightValue: proteinRemaining == 0 ? "Target hit" : "\(proteinRemaining)g left",
            secondInsightTitle: "Consistency",
            secondInsightValue: mealCount == 0 ? "One log starts it" : "\(mealCount) logged"
        )
    }

    private static func headline(name: String?, hour: Int, theme: ThemeVariant) -> String {
        if let name {
            if hour < 12 { return "Morning, \(name)" }
            if hour < 17 { return "Quick check, \(name)" }
            return "Evening check, \(name)"
        }

        switch theme {
        case .sageGreen:
            return hour < 12 ? "Morning fuel check" : "Steady fuel check"
        case .babyYellow:
            return hour < 12 ? "Bright start" : "Golden reset"
        case .babyBlueEspresso:
            return hour < 12 ? "Coffee and fuel" : "Calm fuel check"
        }
    }

    private static func subtitle(mealCount: Int, waterOunces: Int, waterGoalOunces: Int) -> String {
        if mealCount == 0 && waterOunces == 0 {
            return "Log the next thing you eat. Keep it simple."
        }

        if waterOunces >= waterGoalOunces {
            return "Hydration is handled. Food can stay simple."
        }

        if mealCount == 0 {
            return "Water started. Add food whenever you are ready."
        }

        return "You have a rhythm. Keep the next log easy."
    }

    private static func emptyMealTitle(theme: ThemeVariant) -> String {
        switch theme {
        case .sageGreen:
            return "Start with a simple log"
        case .babyYellow:
            return "First fuel note"
        case .babyBlueEspresso:
            return "First food check"
        }
    }

    private static func calorieTitle(consumedProtein: Int, proteinGoal: Int) -> String {
        if consumedProtein >= proteinGoal {
            return "Protein target hit"
        }
        if consumedProtein == 0 {
            return "Fuel plan"
        }
        return "Daily fuel"
    }
}
