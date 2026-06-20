import Foundation

enum LocalFoodDatabase {
    static let entries: [FoodNutritionEntry] = [
        entry("Greek yogurt", ["greek yogurt", "yogurt", "plain yogurt"], 59, 10, 3.6, 0.4, [
            serving("1 cup", 225, 180, 250),
            serving("small bowl", 170, 140, 200)
        ]),
        entry("Mochi", ["mochi", "mochi ball", "mochi pieces"], 260, 2.5, 58, 1, [
            serving("1 piece", 35, 25, 45)
        ]),
        entry("Protein bar", ["protein bar", "protein bars", "bar", "quest bar", "rxbar"], 360, 33, 35, 10, [
            serving("1 bar", 60, 50, 70)
        ]),
        entry("Oikos protein yogurt", ["oikos", "oikos yogurt", "oikos pro", "protein yogurt"], 83, 14, 6, 0.3, [
            serving("1 cup", 170, 150, 190),
            serving("1 container", 150, 130, 180)
        ]),
        entry("Siggi's skyr", ["siggis", "siggi's", "skyr", "icelandic yogurt"], 75, 12, 6, 0.2, [
            serving("1 cup", 170, 150, 200),
            serving("1 container", 150, 130, 180)
        ]),
        entry("Yogurt bowl", ["yogurt bowl", "greek yogurt bowl", "protein yogurt bowl"], 120, 10, 13, 3, [
            serving("bowl", 300, 230, 420),
            serving("small bowl", 220, 170, 300)
        ]),
        entry("Built protein bar", ["built bar", "built protein bar"], 350, 30, 38, 8, [
            serving("1 bar", 49, 42, 60)
        ]),
        entry("Barebells protein bar", ["barebells", "barebells bar", "barebells protein bar"], 360, 33, 32, 12, [
            serving("1 bar", 55, 50, 65)
        ]),
        entry("Protein chips", ["protein chips", "quest chips"], 365, 43, 18, 13, [
            serving("1 bag", 32, 28, 40)
        ]),
        entry("Chicken breast", ["chicken breast", "chicken"], 165, 31, 0, 3.6, [
            serving("4 oz", 113, 90, 140),
            serving("palm-size serving", 120, 90, 150)
        ]),
        entry("Salmon", ["salmon"], 208, 20, 0, 13, [
            serving("4 oz", 113, 90, 140),
            serving("fillet", 160, 120, 220)
        ]),
        entry("Eggs", ["egg", "eggs"], 143, 13, 1.1, 10, [
            serving("1 egg", 50, 42, 58)
        ]),
        entry("Rice", ["rice", "white rice", "brown rice"], 130, 2.7, 28, 0.3, [
            serving("1 cup", 158, 130, 190),
            serving("bowl", 220, 160, 300)
        ]),
        entry("Pasta", ["pasta", "noodles"], 158, 5.8, 31, 0.9, [
            serving("1 cup", 140, 110, 180),
            serving("bowl", 220, 160, 300)
        ]),
        entry("Avocado", ["avocado"], 160, 2, 8.5, 14.7, [
            serving("half avocado", 75, 55, 100),
            serving("1 avocado", 150, 120, 200)
        ]),
        entry("Banana", ["banana", "bananas"], 89, 1.1, 23, 0.3, [
            serving("1 banana", 118, 90, 150)
        ]),
        entry("Apple", ["apple", "apples"], 52, 0.3, 14, 0.2, [
            serving("1 apple", 180, 140, 220)
        ]),
        entry("Oatmeal", ["oatmeal", "oats"], 68, 2.4, 12, 1.4, [
            serving("1 cup", 234, 180, 280),
            serving("bowl", 250, 180, 320)
        ]),
        entry("Overnight oats", ["overnight oats"], 120, 5, 18, 3, [
            serving("jar", 300, 240, 380),
            serving("bowl", 280, 220, 360)
        ]),
        entry("Granola", ["granola"], 471, 10, 64, 20, [
            serving("1/2 cup", 55, 40, 75)
        ]),
        entry("Peanut butter", ["peanut butter", "pb"], 588, 25, 20, 50, [
            serving("1 tbsp", 16, 12, 22),
            serving("spoonful", 20, 12, 30)
        ]),
        entry("Almond butter", ["almond butter"], 614, 21, 19, 56, [
            serving("1 tbsp", 16, 12, 22),
            serving("spoonful", 20, 12, 30)
        ]),
        entry("Salad", ["salad", "green salad"], 20, 1.2, 3.5, 0.2, [
            serving("bowl", 180, 100, 300),
            serving("plate", 240, 140, 360)
        ]),
        entry("Sweet potato", ["sweet potato", "yam"], 86, 1.6, 20, 0.1, [
            serving("medium", 130, 100, 180)
        ]),
        entry("Tofu", ["tofu"], 144, 17, 3, 9, [
            serving("1 cup", 250, 200, 300),
            serving("serving", 150, 100, 220)
        ]),
        entry("Steak", ["steak"], 271, 25, 0, 19, [
            serving("4 oz", 113, 90, 140)
        ]),
        entry("Turkey", ["turkey", "turkey breast"], 135, 29, 0, 1, [
            serving("serving", 113, 90, 140)
        ]),
        entry("Cottage cheese", ["cottage cheese"], 98, 11, 3.4, 4.3, [
            serving("1 cup", 226, 180, 260),
            serving("small bowl", 170, 140, 210)
        ]),
        entry("Protein shake", ["protein shake", "protein smoothie"], 48, 9, 1.5, 0.5, [
            serving("1 shake", 330, 250, 450),
            serving("1 scoop", 31, 25, 40)
        ]),
        entry("Smoothie bowl", ["smoothie bowl", "acai bowl", "açaí bowl"], 110, 2, 22, 2, [
            serving("bowl", 450, 330, 620),
            serving("small bowl", 320, 240, 430)
        ]),
        entry("Protein pancakes", ["protein pancakes", "protein pancake"], 190, 14, 22, 5, [
            serving("serving", 160, 120, 220),
            serving("2 pancakes", 140, 110, 190)
        ]),
        entry("Egg bites", ["egg bites", "egg white bites", "starbucks egg bites"], 170, 12, 9, 10, [
            serving("2 bites", 130, 110, 150),
            serving("serving", 130, 110, 150)
        ]),
        entry("Avocado toast", ["avocado toast", "avo toast"], 210, 6, 23, 11, [
            serving("1 slice", 120, 90, 170),
            serving("2 slices", 240, 180, 330)
        ]),
        entry("Milk", ["milk", "whole milk"], 61, 3.2, 4.8, 3.3, [
            serving("1 cup", 244, 220, 260)
        ]),
        entry("Oat milk", ["oat milk"], 50, 1, 6.7, 2, [
            serving("1 cup", 240, 220, 260),
            serving("splash", 45, 20, 70)
        ]),
        entry("Almond milk", ["almond milk"], 15, 0.6, 0.3, 1.2, [
            serving("1 cup", 240, 220, 260)
        ]),
        entry("Matcha", ["matcha", "matcha latte"], 1, 0, 0, 0, [
            serving("1 cup", 240, 220, 300)
        ]),
        entry("Coffee", ["coffee", "espresso", "latte"], 1, 0.1, 0, 0, [
            serving("1 cup", 240, 180, 300)
        ]),
        entry("Cold brew", ["cold brew", "iced coffee"], 1, 0.1, 0, 0, [
            serving("medium", 475, 350, 600),
            serving("large", 590, 450, 720)
        ]),
        entry("Iced latte", ["iced latte", "latte with milk"], 45, 2.2, 4.2, 2, [
            serving("medium", 475, 350, 600),
            serving("large", 590, 450, 720)
        ]),
        entry("Oat milk latte", ["oat milk latte", "iced oat milk latte"], 62, 1.2, 8, 2.5, [
            serving("medium", 475, 350, 600),
            serving("large", 590, 450, 720)
        ]),
        entry("Vanilla latte", ["vanilla latte", "iced vanilla latte"], 74, 2.1, 11, 2, [
            serving("medium", 475, 350, 600),
            serving("large", 590, 450, 720)
        ]),
        entry("Broccoli", ["broccoli"], 35, 2.4, 7, 0.4, [
            serving("1 cup", 90, 70, 120)
        ]),
        entry("Toast", ["toast", "bread", "slice of toast"], 265, 9, 49, 3.2, [
            serving("1 slice", 35, 28, 45)
        ]),
        entry("Chicken rice bowl", ["chicken rice bowl", "chicken bowl"], 150, 12, 17, 4, [
            serving("bowl", 450, 330, 620),
            serving("small bowl", 320, 240, 430)
        ]),
        entry("Burrito bowl", ["burrito bowl", "chipotle bowl"], 155, 9, 18, 5, [
            serving("bowl", 500, 380, 700)
        ]),
        entry("Poke bowl", ["poke bowl", "salmon poke", "tuna poke"], 140, 11, 18, 3.5, [
            serving("bowl", 500, 380, 680)
        ]),
        entry("Sushi roll", ["sushi", "sushi roll", "california roll", "salmon roll"], 145, 5, 26, 2, [
            serving("1 roll", 190, 150, 240),
            serving("6 pieces", 190, 150, 240)
        ]),
        entry("Caesar salad", ["caesar salad", "chicken caesar"], 165, 9, 8, 11, [
            serving("bowl", 350, 250, 520),
            serving("plate", 420, 300, 620)
        ]),
        entry("Turkey sandwich", ["turkey sandwich", "turkey wrap"], 210, 15, 24, 6, [
            serving("sandwich", 220, 170, 300),
            serving("wrap", 240, 180, 320)
        ]),
        entry("Burger", ["burger", "cheeseburger"], 260, 15, 20, 14, [
            serving("1 burger", 230, 180, 320)
        ]),
        entry("Fries", ["fries", "french fries"], 312, 3.4, 41, 15, [
            serving("small", 75, 55, 100),
            serving("medium", 115, 90, 150)
        ])
    ]

    private static func entry(
        _ name: String,
        _ aliases: [String],
        _ calories: Double,
        _ protein: Double,
        _ carbs: Double,
        _ fat: Double,
        _ servings: [FoodServing]
    ) -> FoodNutritionEntry {
        FoodNutritionEntry(
            canonicalName: name,
            aliases: aliases,
            caloriesPer100g: calories,
            proteinPer100g: protein,
            carbsPer100g: carbs,
            fatPer100g: fat,
            commonServings: servings
        )
    }

    private static func serving(_ label: String, _ grams: Double, _ min: Double, _ max: Double) -> FoodServing {
        FoodServing(label: label, grams: grams, minGrams: min, maxGrams: max)
    }
}
