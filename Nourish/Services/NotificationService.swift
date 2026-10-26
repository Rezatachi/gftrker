import Foundation
import UserNotifications

enum NotificationService {
    static let hydrationTitles = [
        "Water check",
        "Hydration break",
        "Take a sip",
        "Tiny reset",
        "Bottle check"
    ]

    static let hydrationMessages = [
        "Take a few sips now. Future you will appreciate it.",
        "Hydration check. Two or three sips is enough to keep the streak moving.",
        "A few sips now will make later feel easier.",
        "Your water bottle called. A few sips will do.",
        "Pause, breathe, and drink a little water.",
        "Small sip, steady day.",
        "A quick hydration break can help you reset.",
        "喝水!",
    ]

    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func scheduleWaterReminders(startHour: Int, endHour: Int) async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: reminderIDs)
        guard await requestAuthorization(), startHour <= endHour else { return }

        for hour in stride(from: startHour, through: endHour, by: 1) {
            let content = UNMutableNotificationContent()
            content.title = randomTitle(seed: hour)
            content.body = randomBody(seed: hour)
            content.sound = .default

            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: reminderID(hour), content: content, trigger: trigger)
            try? await UNUserNotificationCenter.current().add(request)
        }
    }

    static func cancelWaterReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: reminderIDs + legacyDebugReminderIDs)
    }

    private static var reminderIDs: [String] {
        stride(from: 0, through: 23, by: 1).map(reminderID)
    }

    private static var legacyDebugReminderIDs: [String] {
        (0..<20).map { "debug-water-reminder-\($0)" }
    }

    private static func reminderID(_ hour: Int) -> String {
        "water-reminder-\(hour)"
    }

    private static func randomTitle(seed: Int) -> String {
        hydrationTitles[stableIndex(seed: seed, count: hydrationTitles.count)]
    }

    private static func randomBody(seed: Int) -> String {
        hydrationMessages[stableIndex(seed: seed, count: hydrationMessages.count)]
    }

    private static func stableIndex(seed: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        let mixed = abs(seed &* 1_103_515_245 &+ Calendar.current.component(.day, from: .now) &* 12_345)
        return mixed % count
    }
}
