import Foundation
import CoreData

// Type-safe extensions for Core Data entities
extension NSManagedObject {
    // Conversation properties
    var conversationId: UUID? {
        get { value(forKey: "id") as? UUID }
        set { setValue(newValue, forKey: "id") }
    }
    
    var conversationTitle: String? {
        get { value(forKey: "title") as? String }
        set { setValue(newValue, forKey: "title") }
    }
    
    var conversationDate: Date? {
        get { value(forKey: "date") as? Date }
        set { setValue(newValue, forKey: "date") }
    }
    
    var conversationGoal: String? {
        get { value(forKey: "goal") as? String }
        set { setValue(newValue, forKey: "goal") }
    }
    
    var conversationOutcome: String? {
        get { value(forKey: "outcome") as? String }
        set { setValue(newValue, forKey: "outcome") }
    }
    
    var conversationEmotionalRating: Int16 {
        get { (value(forKey: "emotionalRating") as? Int16) ?? 5 }
        set { setValue(newValue, forKey: "emotionalRating") }
    }
    
    var conversationNotes: String? {
        get { value(forKey: "notes") as? String }
        set { setValue(newValue, forKey: "notes") }
    }
    
    var conversationIsResolved: Bool {
        get { (value(forKey: "isResolved") as? Bool) ?? false }
        set { setValue(newValue, forKey: "isResolved") }
    }
    
    var conversationContacts: NSSet? {
        get { value(forKey: "contacts") as? NSSet }
        set { setValue(newValue, forKey: "contacts") }
    }
    
    var conversationCategory: NSManagedObject? {
        get { value(forKey: "category") as? NSManagedObject }
        set { setValue(newValue, forKey: "category") }
    }
    
    // Contact properties
    var contactId: UUID? {
        get { value(forKey: "id") as? UUID }
        set { setValue(newValue, forKey: "id") }
    }
    
    var contactName: String? {
        get { value(forKey: "name") as? String }
        set { setValue(newValue, forKey: "name") }
    }
    
    var contactRelationshipTag: String? {
        get { value(forKey: "relationshipTag") as? String }
        set { setValue(newValue, forKey: "relationshipTag") }
    }
    
    var contactPhotoData: Data? {
        get { value(forKey: "photoData") as? Data }
        set { setValue(newValue, forKey: "photoData") }
    }
    
    // Category properties
    var categoryId: UUID? {
        get { value(forKey: "id") as? UUID }
        set { setValue(newValue, forKey: "id") }
    }
    
    var categoryName: String? {
        get { value(forKey: "name") as? String }
        set { setValue(newValue, forKey: "name") }
    }
    
    var categoryIconName: String? {
        get { value(forKey: "iconName") as? String }
        set { setValue(newValue, forKey: "iconName") }
    }
    
    var categoryAccentColor: String? {
        get { value(forKey: "accentColor") as? String }
        set { setValue(newValue, forKey: "accentColor") }
    }
    
    // TemplatePhrase properties
    var templatePhraseId: UUID? {
        get { value(forKey: "id") as? UUID }
        set { setValue(newValue, forKey: "id") }
    }
    
    var templatePhraseText: String? {
        get { value(forKey: "text") as? String }
        set { setValue(newValue, forKey: "text") }
    }
    
    var templatePhraseCategory: NSManagedObject? {
        get { value(forKey: "category") as? NSManagedObject }
        set { setValue(newValue, forKey: "category") }
    }
}

