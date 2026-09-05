import SwiftUI
import UIKit

// Shared spacing roles keep nested views from accumulating arbitrary padding.
enum EditorialSpacing {
    static let inline: CGFloat = 4
    static let related: CGFloat = 8
    static let content: CGFloat = 12
    static let row: CGFloat = 14
    static let page: CGFloat = 20
    static let section: CGFloat = 24
}

enum EditorialTheme {
    static let paper = adaptiveColor(
        light: .white,
        dark: UIColor(red: 0.065, green: 0.075, blue: 0.09, alpha: 1)
    )
    static let surface = adaptiveColor(
        light: .white,
        dark: UIColor(red: 0.065, green: 0.075, blue: 0.09, alpha: 1)
    )
    static let ink = adaptiveColor(
        light: UIColor(red: 0.12, green: 0.15, blue: 0.19, alpha: 1),
        dark: UIColor(red: 0.94, green: 0.95, blue: 0.97, alpha: 1)
    )
    static let mutedInk = adaptiveColor(
        light: UIColor(red: 0.39, green: 0.43, blue: 0.48, alpha: 1),
        dark: UIColor(red: 0.66, green: 0.70, blue: 0.76, alpha: 1)
    )
    static let rule = adaptiveColor(
        light: UIColor(red: 0.12, green: 0.15, blue: 0.19, alpha: 0.10),
        dark: UIColor(white: 1, alpha: 0.12)
    )
    static let subtleSurface = adaptiveColor(
        light: UIColor(red: 0.95, green: 0.96, blue: 0.975, alpha: 1),
        dark: UIColor(red: 0.12, green: 0.14, blue: 0.17, alpha: 1)
    )
    static let accent = adaptiveColor(
        light: UIColor(red: 0.15, green: 0.34, blue: 0.62, alpha: 1),
        dark: UIColor(red: 0.48, green: 0.69, blue: 0.98, alpha: 1)
    )
    static let negative = adaptiveColor(
        light: UIColor(red: 0.74, green: 0.18, blue: 0.22, alpha: 1),
        dark: UIColor(red: 1, green: 0.49, blue: 0.51, alpha: 1)
    )
    static let onAccent = adaptiveColor(
        light: .white,
        dark: UIColor(red: 0.06, green: 0.10, blue: 0.17, alpha: 1)
    )
    static let positive = adaptiveColor(
        light: UIColor(red: 0.08, green: 0.40, blue: 0.30, alpha: 1),
        dark: UIColor(red: 0.36, green: 0.79, blue: 0.61, alpha: 1)
    )

    static let metadata = Font.system(.caption, design: .default, weight: .medium)
    static let smallCaps = Font.system(.caption2, design: .default, weight: .bold)

    static func headline(
        _ style: Font.TextStyle,
        weight: Font.Weight = .bold
    ) -> Font {
        .system(style, design: .default, weight: weight)
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

    static func timestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = utcPlusEightTimeZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss 'UTC+8'"
        return formatter.string(from: date)
    }

    static func newsTime(_ date: Date) -> String {
        calendarTime(date)
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
        calendar: Calendar = Calendar(identifier: .gregorian),
        locale: Locale = Locale(identifier: "en_US_POSIX"),
        timeZone: TimeZone = TimeZone(secondsFromGMT: 8 * 60 * 60)!
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
        case .high: EditorialTheme.negative
        case .medium: Color(red: 0.72, green: 0.31, blue: 0.05)
        case .low: EditorialTheme.positive
        case .holiday: EditorialTheme.mutedInk
        case .unknown: EditorialTheme.mutedInk
        }
    }
}
