import Foundation

protocol FoodCorrectionStore {
    func corrections(matching normalizedPhrase: String) async throws -> [FoodCorrectionRecord]
    func save(_ record: FoodCorrectionRecord) async throws
}

struct FoodCorrectionRecord: Sendable {
    var originalPhrase: String
    var normalizedPhrase: String
    var correctionKey: String
    var canonicalFoodName: String
    var sourceRawValue: String
    var providerCandidateID: String?
    var providerID: String?
    var providerDataType: String?
    var rejectedCandidateIDs: [String]
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

    static func normalized(_ phrase: String) -> String {
        FoodCorrection.normalized(phrase)
    }

    static func correctionKey(normalizedPhrase: String, canonicalFoodName: String) -> String {
        FoodCorrection.correctionKey(
            normalizedPhrase: normalizedPhrase,
            canonicalFoodName: canonicalFoodName
        )
    }

    init(
        originalPhrase: String,
        normalizedPhrase: String? = nil,
        canonicalFoodName: String,
        source: FoodLogSource,
        providerCandidateID: String? = nil,
        providerID: String? = nil,
        providerDataType: String? = nil,
        rejectedCandidateIDs: [String] = [],
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
        let normalizedValue = normalizedPhrase ?? Self.normalized(originalPhrase)
        let grams = max(typicalGrams, 1)
        self.originalPhrase = originalPhrase
        self.normalizedPhrase = normalizedValue
        self.correctionKey = Self.correctionKey(
            normalizedPhrase: normalizedValue,
            canonicalFoodName: canonicalFoodName
        )
        self.canonicalFoodName = canonicalFoodName
        self.sourceRawValue = source.rawValue
        self.providerCandidateID = providerCandidateID
        self.providerID = providerID
        self.providerDataType = providerDataType
        self.rejectedCandidateIDs = rejectedCandidateIDs
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

    init?(parsedItem: ParsedFoodItem, originalPhrase: String) {
        let trimmedPhrase = originalPhrase.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = parsedItem.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPhrase.isEmpty, !trimmedName.isEmpty else { return nil }

        let grams = max(parsedItem.estimatedGrams, 1)
        self.init(
            originalPhrase: trimmedPhrase,
            canonicalFoodName: trimmedName,
            source: parsedItem.source,
            providerCandidateID: parsedItem.providerCandidateID,
            providerID: parsedItem.providerID,
            providerDataType: parsedItem.providerDataType,
            rejectedCandidateIDs: parsedItem.candidateOptions
                .map(\.id)
                .filter { $0 != parsedItem.providerCandidateID },
            usdaFDCID: parsedItem.source == .usda
                ? parsedItem.providerID.flatMap(Int.init)
                : nil,
            usdaDataType: parsedItem.source == .usda
                ? parsedItem.providerDataType
                : nil,
            brandOwner: parsedItem.brandOwner,
            servingLabel: parsedItem.estimatedServing,
            typicalGrams: grams,
            minSuggestedGrams: min(parsedItem.minSuggestedGrams, grams),
            maxSuggestedGrams: max(parsedItem.maxSuggestedGrams, grams),
            caloriesPer100g: FoodCorrection.per100g(total: Double(parsedItem.estimatedCalories), grams: grams),
            proteinPer100g: FoodCorrection.per100g(total: parsedItem.estimatedProtein, grams: grams),
            carbsPer100g: FoodCorrection.per100g(total: parsedItem.estimatedCarbs, grams: grams),
            fatPer100g: FoodCorrection.per100g(total: parsedItem.estimatedFat, grams: grams),
            confidence: parsedItem.confidence
        )
    }

    func parsedItem(sourcePhrase: String? = nil) -> ParsedFoodItem {
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
            source: .correctionMemory,
            providerCandidateID: providerCandidateID,
            providerID: providerID,
            providerDataType: providerDataType,
            brandOwner: brandOwner
        )
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
}

actor EphemeralFoodCorrectionStore: FoodCorrectionStore {
    static let shared = EphemeralFoodCorrectionStore()

    private var recordsByPhrase: [String: [FoodCorrectionRecord]] = [:]

    func corrections(matching normalizedPhrase: String) async throws -> [FoodCorrectionRecord] {
        recordsByPhrase[FoodCorrectionRecord.normalized(normalizedPhrase)] ?? []
    }

    func save(_ record: FoodCorrectionRecord) async throws {
        var savedRecord = record
        var records = recordsByPhrase[record.normalizedPhrase, default: []]

        if let index = records.firstIndex(where: { $0.correctionKey == record.correctionKey }) {
            savedRecord.createdAt = records[index].createdAt
            savedRecord.useCount = records[index].useCount + 1
            records.remove(at: index)
        } else {
            savedRecord.useCount = 1
        }

        savedRecord.updatedAt = .now
        savedRecord.lastUsedAt = .now
        records.append(savedRecord)
        recordsByPhrase[record.normalizedPhrase] = records
    }
}

enum FoodCorrectionStoreProvider {
    static var shared: FoodCorrectionStore {
        EphemeralFoodCorrectionStore.shared
    }
}
