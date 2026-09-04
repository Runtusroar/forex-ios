import SwiftUI
import UIKit

enum EditorialTheme {
    static let paper = adaptiveColor(
        light: UIColor(red: 0.965, green: 0.945, blue: 0.90, alpha: 1),
        dark: UIColor(red: 0.09, green: 0.085, blue: 0.075, alpha: 1)
    )
    static let ink = adaptiveColor(
        light: UIColor(red: 0.075, green: 0.07, blue: 0.06, alpha: 1),
        dark: UIColor(red: 0.94, green: 0.92, blue: 0.87, alpha: 1)
    )
    static let mutedInk = adaptiveColor(
        light: UIColor(red: 0.35, green: 0.33, blue: 0.29, alpha: 1),
        dark: UIColor(red: 0.69, green: 0.67, blue: 0.62, alpha: 1)
    )
    static let rule = adaptiveColor(
        light: UIColor(red: 0.45, green: 0.42, blue: 0.37, alpha: 0.72),
        dark: UIColor(red: 0.62, green: 0.59, blue: 0.53, alpha: 0.68)
    )
    static let subtleSurface = adaptiveColor(
        light: UIColor(red: 0.91, green: 0.88, blue: 0.81, alpha: 1),
        dark: UIColor(red: 0.14, green: 0.13, blue: 0.115, alpha: 1)
    )
    static let accent = adaptiveColor(
        light: UIColor(red: 0.48, green: 0.06, blue: 0.055, alpha: 1),
        dark: UIColor(red: 0.76, green: 0.25, blue: 0.22, alpha: 1)
    )

    static let metadata = Font.system(.caption, design: .default, weight: .medium)
    static let smallCaps = Font.system(.caption2, design: .default, weight: .bold)

    static func headline(
        _ style: Font.TextStyle,
        weight: Font.Weight = .bold
    ) -> Font {
        .system(style, design: .serif, weight: weight)
    }

    private static func adaptiveColor(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}

enum EditorialDateFormatter {
    static let utcPlusEightLabel = "UTC+8"

    private static var utcPlusEightTimeZone: TimeZone {
        TimeZone(secondsFromGMT: 8 * 60 * 60)!
    }

    static func newsTime(_ date: Date) -> String {
        "\(calendarTime(date)) \(utcPlusEightLabel)"
    }

    static func calendarTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = utcPlusEightTimeZone
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    static func calendarTime(_ event: CalendarEvent) -> String {
        event.sourceTimeText ?? calendarTime(event.eventAt)
    }

    static func calendarDay(_ date: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = utcPlusEightTimeZone
        return calendar.startOfDay(for: date)
    }

    static func calendarDayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = utcPlusEightTimeZone
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date).uppercased()
    }

    static func publicationDate(
        _ date: Date,
        calendar: Calendar = .current,
        locale: Locale = Locale(identifier: "en_US_POSIX"),
        timeZone: TimeZone = .current
    ) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date).uppercased(with: locale)
    }
}

extension Impact {
    var editorialLabel: String { rawValue.uppercased() }

    var editorialColor: Color {
        switch self {
        case .high: EditorialTheme.accent
        case .medium: Color(red: 0.72, green: 0.31, blue: 0.05)
        case .low: Color(red: 0.08, green: 0.36, blue: 0.27)
        case .holiday: EditorialTheme.mutedInk
        case .unknown: EditorialTheme.mutedInk
        }
    }
}
