import Foundation
import SwiftData

@Model
final class UserSettings {
    var id: UUID = UUID()
    /// Day boundary hour (0-23). Default 5 means the day switches at 5:00 AM.
    var dayBoundaryHour: Int = 5
    var geminiAPIKey: String = ""

    init(dayBoundaryHour: Int = 5) {
        self.id = UUID()
        self.dayBoundaryHour = dayBoundaryHour
    }

    /// Returns the logical date for a given timestamp, adjusted by dayBoundaryHour.
    /// For example, if boundary is 5:00 AM, a post at 2:00 AM on March 12 belongs to March 11.
    func logicalDate(for date: Date) -> Date {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        if hour < dayBoundaryHour {
            // Belongs to previous day
            let previousDay = calendar.date(byAdding: .day, value: -1, to: date)!
            return calendar.startOfDay(for: previousDay)
        }
        return calendar.startOfDay(for: date)
    }
}
