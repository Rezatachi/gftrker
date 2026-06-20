import Foundation

extension Calendar {
    static let app = Calendar.autoupdatingCurrent
}

extension Date {
    var startOfDay: Date {
        Calendar.app.startOfDay(for: self)
    }

    var friendlyDay: String {
        formatted(.dateTime.weekday(.wide).month(.wide).day())
    }
}

extension Sequence where Element == Meal {
    func onDay(_ date: Date) -> [Meal] {
        filter { Calendar.app.isDate($0.date, inSameDayAs: date) }
    }
}

extension Sequence where Element == WaterEntry {
    func onDay(_ date: Date) -> [WaterEntry] {
        filter { Calendar.app.isDate($0.date, inSameDayAs: date) }
    }
}

