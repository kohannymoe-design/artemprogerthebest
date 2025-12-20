import SwiftUI

enum AppTheme: String, CaseIterable {
    case light
    case dark
    case system
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

class ThemeManager: ObservableObject {
    @AppStorage("selectedTheme") var selectedTheme: AppTheme = .system
    
    var currentTheme: AppTheme {
        selectedTheme
    }
}

struct AppColors {
    // Trust Blue
    static let trustBlue = Color(hex: "4A7C9B")
    
    // Calm Green
    static let calmGreen = Color(hex: "6B9E78")
    
    // Soft Beige
    static let softBeige = Color(hex: "F5F1E8")
    
    // Neutral Grays
    static let lightGray = Color(hex: "F8F8F8")
    static let mediumGray = Color(hex: "E5E5E5")
    static let darkGray = Color(hex: "2C2C2C")
    
    // Backgrounds - адаптивные
    static var background: Color {
        Color(light: .white, dark: Color(hex: "1A1A1A"))
    }
    
    static var backgroundLight: Color {
        background
    }
    
    static var backgroundDark: Color {
        Color(hex: "1A1A1A")
    }
    
    // Card backgrounds - адаптивные
    static var cardBackground: Color {
        Color(light: .white, dark: Color(hex: "2C2C2C"))
    }
    
    // Shadow colors - адаптивные
    static var shadowColor: Color {
        Color(light: .black.opacity(0.05), dark: .black.opacity(0.3))
    }
    
    static var shadowColorLight: Color {
        Color(light: .black.opacity(0.05), dark: .black.opacity(0.2))
    }
    
    static var shadowColorStrong: Color {
        Color(light: .black.opacity(0.2), dark: .black.opacity(0.5))
    }
    
    // Text
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    
    // Accents
    static let accent = trustBlue
    static let success = calmGreen
    static let warning = Color(hex: "D4A574")
    static let error = Color(hex: "C97D7D")
}

extension Color {
    init(light: Color, dark: Color) {
        self.init(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

