import Foundation
import UIKit

struct DataValidator {
    static func validateTitle(_ title: String) -> ValidationResult {
        if title.isEmpty {
            return .failure("Title cannot be empty")
        }
        if title.count > AppConstants.Validation.maxTitleLength {
            return .failure("Title must be \(AppConstants.Validation.maxTitleLength) characters or less")
        }
        return .success
    }
    
    static func validateGoal(_ goal: String) -> ValidationResult {
        if goal.count > AppConstants.Validation.maxGoalLength {
            return .failure("Goal must be \(AppConstants.Validation.maxGoalLength) characters or less")
        }
        return .success
    }
    
    static func validateOutcome(_ outcome: String) -> ValidationResult {
        if outcome.count > AppConstants.Validation.maxOutcomeLength {
            return .failure("Outcome must be \(AppConstants.Validation.maxOutcomeLength) characters or less")
        }
        return .success
    }
    
    static func validateNotes(_ notes: String) -> ValidationResult {
        if notes.count > AppConstants.Validation.maxNotesLength {
            return .failure("Notes must be \(AppConstants.Validation.maxNotesLength) characters or less")
        }
        return .success
    }
    
    static func validateName(_ name: String) -> ValidationResult {
        if name.isEmpty {
            return .failure("Name cannot be empty")
        }
        if name.count > AppConstants.Validation.maxNameLength {
            return .failure("Name must be \(AppConstants.Validation.maxNameLength) characters or less")
        }
        return .success
    }
    
    static func validateRelationshipTag(_ tag: String) -> ValidationResult {
        if tag.count > AppConstants.Validation.maxRelationshipTagLength {
            return .failure("Relationship tag must be \(AppConstants.Validation.maxRelationshipTagLength) characters or less")
        }
        return .success
    }
    
    static func validateCategoryName(_ name: String) -> ValidationResult {
        if name.isEmpty {
            return .failure("Category name cannot be empty")
        }
        if name.count > AppConstants.Validation.maxCategoryNameLength {
            return .failure("Category name must be \(AppConstants.Validation.maxCategoryNameLength) characters or less")
        }
        return .success
    }
    
    static func validateTemplatePhrase(_ text: String) -> ValidationResult {
        if text.isEmpty {
            return .failure("Template phrase cannot be empty")
        }
        if text.count > AppConstants.Validation.maxTemplatePhraseLength {
            return .failure("Template phrase must be \(AppConstants.Validation.maxTemplatePhraseLength) characters or less")
        }
        return .success
    }
    
    static func validateEmotionalRating(_ rating: Int16) -> ValidationResult {
        if rating < AppConstants.Defaults.minEmotionalRating || rating > AppConstants.Defaults.maxEmotionalRating {
            return .failure("Emotional rating must be between \(AppConstants.Defaults.minEmotionalRating) and \(AppConstants.Defaults.maxEmotionalRating)")
        }
        return .success
    }
    
    static func validateDate(_ date: Date) -> ValidationResult {
        let maxFutureDate = Date().addingTimeInterval(AppConstants.maxFutureDateOffset)
        if date > maxFutureDate {
            return .failure("Date cannot be more than 1 year in the future")
        }
        return .success
    }
    
    static func validateImage(_ data: Data) -> ValidationResult {
        if !ImageProcessor.validateImageSize(data) {
            return .failure("Image size must be \(AppConstants.Validation.maxImageSize / (1024 * 1024))MB or less")
        }
        return .success
    }
}

enum ValidationResult {
    case success
    case failure(String)
    
    var isValid: Bool {
        if case .success = self {
            return true
        }
        return false
    }
    
    var errorMessage: String? {
        if case .failure(let message) = self {
            return message
        }
        return nil
    }
}
