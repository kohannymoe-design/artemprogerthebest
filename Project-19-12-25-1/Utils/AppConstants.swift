import Foundation
import SwiftUI

struct AppConstants {
    // Validation limits
    struct Validation {
        static let maxTitleLength = 200
        static let maxGoalLength = 1000
        static let maxOutcomeLength = 1000
        static let maxNotesLength = 2000
        static let maxNameLength = 100
        static let maxRelationshipTagLength = 50
        static let maxCategoryNameLength = 50
        static let maxTemplatePhraseLength = 500
        static let maxImageSize: Int64 = 5 * 1024 * 1024 // 5MB
        static let imageCompressionQuality: CGFloat = 0.7
        static let maxImageDimension: CGFloat = 1024
    }
    
    // Default values
    struct Defaults {
        static let defaultEmotionalRating: Int16 = 5
        static let minEmotionalRating: Int16 = 1
        static let maxEmotionalRating: Int16 = 10
        static let splashScreenDuration: TimeInterval = 2.0
        static let itemsPerPage = 20
    }
    
    // Icon options
    static let availableIcons = [
        "folder", "dollarsign.circle", "house", "briefcase", "heart",
        "person.2", "chart.bar", "creditcard", "gift", "cart",
        "banknote", "wallet.pass", "bag", "tag", "star"
    ]
    
    // Color options
    static let availableColors: [(name: String, hex: String)] = [
        ("Trust Blue", "4A7C9B"),
        ("Calm Green", "6B9E78"),
        ("Soft Beige", "D4A574"),
        ("Warm Orange", "E8A87C"),
        ("Gentle Purple", "9B7CAA"),
        ("Coral", "FF6B6B"),
        ("Sky Blue", "4ECDC4"),
        ("Lavender", "A8A8D8")
    ]
    
    // Date validation
    static let maxFutureDateOffset: TimeInterval = 365 * 24 * 60 * 60 // 1 year in future
}
