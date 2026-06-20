import Foundation
import UserNotifications

enum NotificationService {
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
            content.title = "Water check"
            content.body = "Take a few sips now. Future you will appreciate it."
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
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: reminderIDs)
    }

    private static var reminderIDs: [String] {
        stride(from: 0, through: 23, by: 1).map(reminderID)
    }

    private static func reminderID(_ hour: Int) -> String {
        "water-reminder-\(hour)"
    }
}
