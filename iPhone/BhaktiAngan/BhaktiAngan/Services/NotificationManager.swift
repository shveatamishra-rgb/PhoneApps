import Foundation
import UserNotifications

enum NotificationManager {
    static let dailyIdentifier = "divine-stillness.daily-darshan"

    static func requestAndSchedule(
        hour: Int,
        minute: Int,
        title: String = "Your daily darshan is ready",
        body: String = "Take one quiet minute for mantra, prayer, and stillness."
    ) async throws {
        let center = UNUserNotificationCenter.current()
        let allowed = try await center.requestAuthorization(options: [.alert, .badge, .sound])
        guard allowed else { throw NotificationError.permissionDenied }

        center.removePendingNotificationRequests(withIdentifiers: [dailyIdentifier])

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: dailyIdentifier,
            content: content,
            trigger: trigger
        )
        try await center.add(request)
    }

    static func disableDailyReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [dailyIdentifier])
    }
}

enum NotificationError: LocalizedError {
    case permissionDenied

    var errorDescription: String? {
        "Notifications are disabled. You can enable them in iPhone Settings."
    }
}
