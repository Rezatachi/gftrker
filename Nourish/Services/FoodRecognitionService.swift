import UIKit

struct FoodDetectionResult: Identifiable, Hashable {
    let id = UUID()
    var foodName: String
    var estimatedServing: String
    var confidence: Double
    var estimatedCalories: Int?
}

protocol FoodRecognitionService {
    func detectFoods(in image: UIImage) async throws -> [FoodDetectionResult]
}

struct MockFoodRecognitionService: FoodRecognitionService {
    func detectFoods(in image: UIImage) async throws -> [FoodDetectionResult] {
        [
            FoodDetectionResult(foodName: "Greek yogurt bowl", estimatedServing: "1 bowl", confidence: 0.82, estimatedCalories: 340),
            FoodDetectionResult(foodName: "Blueberries", estimatedServing: "1/2 cup", confidence: 0.74, estimatedCalories: 42),
            FoodDetectionResult(foodName: "Granola", estimatedServing: "1/4 cup", confidence: 0.67, estimatedCalories: 130)
        ]
    }
}

struct OpenAIFoodRecognitionService: FoodRecognitionService {
    func detectFoods(in image: UIImage) async throws -> [FoodDetectionResult] {
        // Future implementation: call a secure backend or user-provided client. Do not ship API keys in the app.
        []
    }
}

