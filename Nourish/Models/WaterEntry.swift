import Foundation
import SwiftData

@Model
final class WaterEntry {
    var id: UUID
    var date: Date
    var glasses: Int
    var ounces: Int?

    init(id: UUID = UUID(), date: Date = .now, glasses: Int = 1, ounces: Int? = 12) {
        self.id = id
        self.date = date
        self.glasses = glasses
        self.ounces = ounces
    }

    var effectiveOunces: Int {
        ounces ?? max(glasses, 0) * 12
    }
}
