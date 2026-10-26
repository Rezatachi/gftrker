import Foundation

protocol FoodParsingService {
    func parseFoodLogMessage(_ text: String) async throws -> ParsedFoodResult
}

struct ParsedFoodResult: Identifiable {
    let id: UUID
    let originalText: String
    var items: [ParsedFoodItem]
    let createdAt: Date
    var status: ParsedFoodResultStatus

    init(
        id: UUID = UUID(),
        originalText: String,
        items: [ParsedFoodItem],
        createdAt: Date = .now,
        status: ParsedFoodResultStatus = .pendingReview
    ) {
        self.id = id
        self.originalText = originalText
        self.items = items
        self.createdAt = createdAt
        self.status = status
    }
}

enum ParsedFoodResultStatus {
    case pendingReview
    case confirmed
    case discarded
}

struct ParsedFoodCandidate: Identifiable {
    let id: String
    var providerID: String?
    var providerDataType: String?
    var brandOwner: String?
    var name: String
    var detectedQuantity: String
    var estimatedServing: String
    var estimatedGrams: Double
    var minSuggestedGrams: Double
    var maxSuggestedGrams: Double
    var estimatedCalories: Int
    var estimatedProtein: Double
    var estimatedCarbs: Double
    var estimatedFat: Double
    var confidence: Double
    var source: FoodLogSource

    init(
        id: String,
        providerID: String? = nil,
        providerDataType: String? = nil,
        brandOwner: String? = nil,
        name: String,
        detectedQuantity: String,
        estimatedServing: String,
        estimatedGrams: Double,
        minSuggestedGrams: Double,
        maxSuggestedGrams: Double,
        estimatedCalories: Int,
        estimatedProtein: Double,
        estimatedCarbs: Double = 0,
        estimatedFat: Double = 0,
        confidence: Double,
        source: FoodLogSource
    ) {
        self.id = id
        self.providerID = providerID
        self.providerDataType = providerDataType
        self.brandOwner = brandOwner
        self.name = name
        self.detectedQuantity = detectedQuantity
        self.estimatedServing = estimatedServing
        self.estimatedGrams = estimatedGrams
        self.minSuggestedGrams = minSuggestedGrams
        self.maxSuggestedGrams = maxSuggestedGrams
        self.estimatedCalories = estimatedCalories
        self.estimatedProtein = estimatedProtein
        self.estimatedCarbs = estimatedCarbs
        self.estimatedFat = estimatedFat
        self.confidence = confidence
        self.source = source
    }

    func parsedItem(
        sourcePhrase: String?,
        candidateOptions: [ParsedFoodCandidate]
    ) -> ParsedFoodItem {
        ParsedFoodItem(
            name: name,
            sourcePhrase: sourcePhrase,
            detectedQuantity: detectedQuantity,
            estimatedServing: estimatedServing,
            estimatedGrams: estimatedGrams,
            minSuggestedGrams: minSuggestedGrams,
            maxSuggestedGrams: maxSuggestedGrams,
            estimatedCalories: estimatedCalories,
            estimatedProtein: estimatedProtein,
            estimatedCarbs: estimatedCarbs,
            estimatedFat: estimatedFat,
            confidence: confidence,
            source: source,
            providerCandidateID: id,
            providerID: providerID,
            providerDataType: providerDataType,
            brandOwner: brandOwner,
            candidateOptions: candidateOptions
        )
    }
}

struct ParsedFoodItem: Identifiable {
    let id: UUID
    var name: String
    var sourcePhrase: String?
    var detectedQuantity: String
    var estimatedServing: String
    var estimatedGrams: Double
    var minSuggestedGrams: Double
    var maxSuggestedGrams: Double
    var estimatedCalories: Int
    var estimatedProtein: Double
    var estimatedCarbs: Double
    var estimatedFat: Double
    var confidence: Double
    var source: FoodLogSource
    var providerCandidateID: String?
    var providerID: String?
    var providerDataType: String?
    var brandOwner: String?
    var candidateOptions: [ParsedFoodCandidate]

    init(
        id: UUID = UUID(),
        name: String,
        sourcePhrase: String? = nil,
        detectedQuantity: String,
        estimatedServing: String,
        estimatedGrams: Double,
        minSuggestedGrams: Double,
        maxSuggestedGrams: Double,
        estimatedCalories: Int,
        estimatedProtein: Double,
        estimatedCarbs: Double = 0,
        estimatedFat: Double = 0,
        confidence: Double,
        source: FoodLogSource = .chat,
        providerCandidateID: String? = nil,
        providerID: String? = nil,
        providerDataType: String? = nil,
        brandOwner: String? = nil,
        candidateOptions: [ParsedFoodCandidate] = []
    ) {
        self.id = id
        self.name = name
        self.sourcePhrase = sourcePhrase
        self.detectedQuantity = detectedQuantity
        self.estimatedServing = estimatedServing
        self.estimatedGrams = estimatedGrams
        self.minSuggestedGrams = minSuggestedGrams
        self.maxSuggestedGrams = maxSuggestedGrams
        self.estimatedCalories = estimatedCalories
        self.estimatedProtein = estimatedProtein
        self.estimatedCarbs = estimatedCarbs
        self.estimatedFat = estimatedFat
        self.confidence = confidence
        self.source = source
        self.providerCandidateID = providerCandidateID
        self.providerID = providerID
        self.providerDataType = providerDataType
        self.brandOwner = brandOwner
        self.candidateOptions = candidateOptions
    }
}

enum FoodParsingError: LocalizedError {
    case emptyMessage
    case needsClarification(String)
    case unavailable

    var errorDescription: String? {
        switch self {
        case .emptyMessage:
            "Tell me what you ate first."
        case .needsClarification(let message):
            message
        case .unavailable:
            "Food parsing is not available yet."
        }
    }
}
