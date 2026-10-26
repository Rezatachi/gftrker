import Foundation

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

private struct EvaluationCase: Decodable {
    let message: String
    let items: [ExpectedItem]
}

private struct ExpectedItem: Decodable {
    let name: String
    let grams: Double
    let acceptableNames: [String]?
    let maxPercentError: Double?
    let minConfidence: Double?
    let allowedSources: [FoodLogSource]?

    var acceptedNormalizedNames: Set<String> {
        Set(([name] + (acceptableNames ?? [])).map(QuantityParser.normalize))
    }

    var allowedPercentError: Double {
        maxPercentError ?? 0.20
    }
}

private struct EvaluationThresholds {
    let exactCaseAccuracy = 0.95
    let itemRecall = 0.95
    let itemPrecision = 0.95
    let tolerancePassRate = 0.95
    let gramMAPE = 0.15
    let gramP95APE = 0.20
    let sourceCompliance = 0.95
    let confidenceCompliance = 0.95
}

private struct EvaluationMetrics {
    var exactCountMatches = 0
    var matchedFoods = 0
    var expectedFoods = 0
    var actualFoods = 0
    var tolerancePasses = 0
    var toleranceChecks = 0
    var sourcePasses = 0
    var sourceChecks = 0
    var confidencePasses = 0
    var confidenceChecks = 0
    var absolutePercentageErrors: [Double] = []
    var failures: [String] = []

    var extractionAccuracy: Double {
        Double(exactCountMatches) / Double(max(caseCount, 1))
    }

    var itemRecall: Double {
        Double(matchedFoods) / Double(max(expectedFoods, 1))
    }

    var itemPrecision: Double {
        Double(matchedFoods) / Double(max(actualFoods, 1))
    }

    var tolerancePassRate: Double {
        Double(tolerancePasses) / Double(max(toleranceChecks, 1))
    }

    var gramMAPE: Double {
        absolutePercentageErrors.reduce(0, +) / Double(max(absolutePercentageErrors.count, 1))
    }

    var gramP95APE: Double {
        guard !absolutePercentageErrors.isEmpty else { return 0 }
        let sorted = absolutePercentageErrors.sorted()
        let index = min(Int(ceil(Double(sorted.count) * 0.95)) - 1, sorted.count - 1)
        return sorted[max(index, 0)]
    }

    var sourceCompliance: Double {
        Double(sourcePasses) / Double(max(sourceChecks, 1))
    }

    var confidenceCompliance: Double {
        Double(confidencePasses) / Double(max(confidenceChecks, 1))
    }

    var caseCount = 0
}

@main
private struct MatcherEvaluation {
    static func main() async throws {
        let datasetURL = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "")
        let cases = try JSONDecoder().decode(
            [EvaluationCase].self,
            from: Data(contentsOf: datasetURL)
        )

        let parser = LocalFoodDatabaseParsingService()
        let thresholds = EvaluationThresholds()
        var metrics = EvaluationMetrics()
        metrics.caseCount = cases.count

        for testCase in cases {
            let parsed = try? await parser.parseFoodLogMessage(testCase.message)
            let actualItems = parsed?.items ?? []
            metrics.expectedFoods += testCase.items.count
            metrics.actualFoods += actualItems.count

            if actualItems.count == testCase.items.count {
                metrics.exactCountMatches += 1
            } else {
                metrics.failures.append(
                    "COUNT \"\(testCase.message)\": expected \(testCase.items.count), got \(actualItems.count)"
                )
            }

            evaluateCase(
                testCase,
                actualItems: actualItems,
                metrics: &metrics
            )
        }

        print("Cases: \(cases.count)")
        print(String(format: "Exact-count accuracy: %.1f%%", metrics.extractionAccuracy * 100))
        print(String(format: "Item recall: %.1f%%", metrics.itemRecall * 100))
        print(String(format: "Item precision: %.1f%%", metrics.itemPrecision * 100))
        print(String(format: "Within-tolerance rate: %.1f%%", metrics.tolerancePassRate * 100))
        print(String(format: "Gram MAPE: %.1f%%", metrics.gramMAPE * 100))
        print(String(format: "Gram p95 APE: %.1f%%", metrics.gramP95APE * 100))
        if metrics.sourceChecks > 0 {
            print(String(format: "Source compliance: %.1f%%", metrics.sourceCompliance * 100))
        }
        if metrics.confidenceChecks > 0 {
            print(String(format: "Confidence compliance: %.1f%%", metrics.confidenceCompliance * 100))
        }

        if !metrics.failures.isEmpty {
            print("\nFailures:")
            metrics.failures.prefix(30).forEach { print("- \($0)") }
        }

        guard metrics.failures.isEmpty,
              metrics.extractionAccuracy >= thresholds.exactCaseAccuracy,
              metrics.itemRecall >= thresholds.itemRecall,
              metrics.itemPrecision >= thresholds.itemPrecision,
              metrics.tolerancePassRate >= thresholds.tolerancePassRate,
              metrics.gramMAPE <= thresholds.gramMAPE,
              metrics.gramP95APE <= thresholds.gramP95APE,
              metrics.sourceCompliance >= thresholds.sourceCompliance,
              metrics.confidenceCompliance >= thresholds.confidenceCompliance else {
            Foundation.exit(1)
        }
    }

    private static func evaluateCase(
        _ testCase: EvaluationCase,
        actualItems: [ParsedFoodItem],
        metrics: inout EvaluationMetrics
    ) {
        var unmatchedIndices = Set(actualItems.indices)

        for expected in testCase.items {
            guard let bestIndex = bestMatchIndex(
                for: expected,
                actualItems: actualItems,
                unmatchedIndices: unmatchedIndices
            ) else {
                let actualNames = actualItems.map(\.name)
                metrics.failures.append(
                    "MATCH \"\(testCase.message)\": missing \(expected.name); got \(actualNames)"
                )
                continue
            }

            unmatchedIndices.remove(bestIndex)
            let actual = actualItems[bestIndex]
            let error = absolutePercentageError(expected: expected.grams, actual: actual.estimatedGrams)

            metrics.matchedFoods += 1
            metrics.absolutePercentageErrors.append(error)
            metrics.toleranceChecks += 1

            if error <= expected.allowedPercentError {
                metrics.tolerancePasses += 1
            } else {
                metrics.failures.append(
                    String(
                        format: "GRAMS \"%@\": %@ expected %.1fg, got %.1fg (%.1f%% error, max %.1f%%)",
                        testCase.message,
                        expected.name,
                        expected.grams,
                        actual.estimatedGrams,
                        error * 100,
                        expected.allowedPercentError * 100
                    )
                )
            }

            if let allowedSources = expected.allowedSources {
                metrics.sourceChecks += 1
                if allowedSources.contains(actual.source) {
                    metrics.sourcePasses += 1
                } else {
                    let expectedSources = allowedSources.map(\.rawValue)
                    metrics.failures.append(
                        "SOURCE \"\(testCase.message)\": \(expected.name) expected \(expectedSources), got \(actual.source.rawValue)"
                    )
                }
            }

            if let minConfidence = expected.minConfidence {
                metrics.confidenceChecks += 1
                if actual.confidence >= minConfidence {
                    metrics.confidencePasses += 1
                } else {
                    metrics.failures.append(
                        String(
                            format: "CONFIDENCE \"%@\": %@ expected >= %.2f, got %.2f",
                            testCase.message,
                            expected.name,
                            minConfidence,
                            actual.confidence
                        )
                    )
                }
            }
        }

        if !unmatchedIndices.isEmpty {
            let extras = unmatchedIndices.map { actualItems[$0].name }
            metrics.failures.append(
                "EXTRA \"\(testCase.message)\": unexpected items \(extras)"
            )
        }
    }

    private static func bestMatchIndex(
        for expected: ExpectedItem,
        actualItems: [ParsedFoodItem],
        unmatchedIndices: Set<Int>
    ) -> Int? {
        unmatchedIndices
            .filter { expected.acceptedNormalizedNames.contains(QuantityParser.normalize(actualItems[$0].name)) }
            .min {
                absolutePercentageError(expected: expected.grams, actual: actualItems[$0].estimatedGrams)
                    < absolutePercentageError(expected: expected.grams, actual: actualItems[$1].estimatedGrams)
            }
    }

    private static func absolutePercentageError(expected: Double, actual: Double) -> Double {
        abs(actual - expected) / max(expected, 1)
    }
}
