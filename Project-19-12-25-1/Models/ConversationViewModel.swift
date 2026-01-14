import Foundation
import CoreData
import SwiftUI
import UIKit

@Observable
class ConversationViewModel {
    var conversations: [NSManagedObject] = []
    var contacts: [NSManagedObject] = []
    var categories: [NSManagedObject] = []
    var templatePhrases: [NSManagedObject] = []
    
    private let context: NSManagedObjectContext
    private var notificationObserver: NSObjectProtocol?
    var errorHandler = ErrorHandler()
    
    init(context: NSManagedObjectContext) {
        self.context = context
        setupNotifications()
        // Load data on main thread
        DispatchQueue.main.async {
            self.loadData()
        }
    }
    
    deinit {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func setupNotifications() {
        // Observe Core Data context changes
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: CoreDataStack.shared.viewContext,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            // Reload all data when context saves
            self.loadData()
        }
    }
    
    func loadData() {
        loadConversations()
        loadContacts()
        loadCategories()
        loadTemplatePhrases()
    }
    
    func loadConversations(limit: Int? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let context = CoreDataStack.shared.viewContext
            let request = NSFetchRequest<NSManagedObject>(entityName: "Conversation")
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            
            // Optimize fetch request
            if let limit = limit {
                request.fetchLimit = limit
            }
            request.fetchBatchSize = AppConstants.Defaults.itemsPerPage
            request.returnsObjectsAsFaults = false
            
            do {
                self.conversations = try context.fetch(request)
                print("Loaded \(self.conversations.count) conversations")
            } catch {
                print("Error loading conversations: \(error)")
                self.errorHandler.handle(AppError.coreDataError("Failed to load conversations: \(error.localizedDescription)"))
            }
        }
    }
    
    func loadContacts() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let context = CoreDataStack.shared.viewContext
            let request = NSFetchRequest<NSManagedObject>(entityName: "Contact")
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            do {
                self.contacts = try context.fetch(request)
                print("Loaded \(self.contacts.count) contacts")
            } catch {
                print("Error loading contacts: \(error)")
                self.errorHandler.handle(AppError.coreDataError("Failed to load contacts: \(error.localizedDescription)"))
            }
        }
    }
    
    func loadCategories() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let context = CoreDataStack.shared.viewContext
            let request = NSFetchRequest<NSManagedObject>(entityName: "Category")
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            do {
                self.categories = try context.fetch(request)
                print("Loaded \(self.categories.count) categories")
            } catch {
                print("Error loading categories: \(error)")
                self.errorHandler.handle(AppError.coreDataError("Failed to load categories: \(error.localizedDescription)"))
            }
        }
    }
    
    func loadTemplatePhrases() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let context = CoreDataStack.shared.viewContext
            let request = NSFetchRequest<NSManagedObject>(entityName: "TemplatePhrase")
            do {
                self.templatePhrases = try context.fetch(request)
                print("Loaded \(self.templatePhrases.count) template phrases")
            } catch {
                print("Error loading template phrases: \(error)")
                self.errorHandler.handle(AppError.coreDataError("Failed to load template phrases: \(error.localizedDescription)"))
            }
        }
    }
    
    func createConversation(
        title: String,
        contacts: Set<NSManagedObject>,
        date: Date,
        category: NSManagedObject?,
        goal: String,
        outcome: String,
        emotionalRating: Int16,
        notes: String?
    ) {
        // Validate inputs
        if let error = validateConversationInputs(title: title, goal: goal, outcome: outcome, notes: notes, emotionalRating: emotionalRating, date: date) {
            errorHandler.handle(error)
            return
        }
        
        // Ensure persistent container is loaded
        _ = CoreDataStack.shared.persistentContainer
        
        let context = CoreDataStack.shared.viewContext
        
        // Verify context is valid
        guard context.persistentStoreCoordinator != nil else {
            errorHandler.handle(AppError.coreDataError("Core Data is not initialized"))
            return
        }
        
        guard let entity = NSEntityDescription.entity(forEntityName: "Conversation", in: context) else {
            errorHandler.handle(AppError.coreDataError("Conversation entity not found"))
            return
        }
        
        let conversation = NSManagedObject(entity: entity, insertInto: context)
        conversation.conversationId = UUID()
        conversation.conversationTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        conversation.conversationContacts = contacts.count > 0 ? contacts as NSSet : nil
        conversation.conversationDate = date
        conversation.conversationCategory = category
        conversation.conversationGoal = goal.isEmpty ? nil : goal.trimmingCharacters(in: .whitespacesAndNewlines)
        conversation.conversationOutcome = outcome.isEmpty ? nil : outcome.trimmingCharacters(in: .whitespacesAndNewlines)
        conversation.conversationEmotionalRating = emotionalRating
        conversation.conversationNotes = notes?.isEmpty == false ? notes?.trimmingCharacters(in: .whitespacesAndNewlines) : nil
        conversation.conversationIsResolved = false
        
        do {
            try context.save()
            print("Conversation created successfully: \(title)")
            self.loadConversations()
        } catch {
            print("Error saving conversation: \(error.localizedDescription)")
            context.rollback()
            errorHandler.handle(AppError.coreDataError("Failed to save conversation: \(error.localizedDescription)"))
        }
    }
    
    private func validateConversationInputs(title: String, goal: String, outcome: String, notes: String?, emotionalRating: Int16, date: Date) -> AppError? {
        let titleResult = DataValidator.validateTitle(title)
        if !titleResult.isValid {
            return AppError.validationError(titleResult.errorMessage ?? "Invalid title")
        }
        let goalResult = DataValidator.validateGoal(goal)
        if !goalResult.isValid {
            return AppError.validationError(goalResult.errorMessage ?? "Invalid goal")
        }
        let outcomeResult = DataValidator.validateOutcome(outcome)
        if !outcomeResult.isValid {
            return AppError.validationError(outcomeResult.errorMessage ?? "Invalid outcome")
        }
        if let notes = notes {
            let notesResult = DataValidator.validateNotes(notes)
            if !notesResult.isValid {
                return AppError.validationError(notesResult.errorMessage ?? "Invalid notes")
            }
        }
        let ratingResult = DataValidator.validateEmotionalRating(emotionalRating)
        if !ratingResult.isValid {
            return AppError.validationError(ratingResult.errorMessage ?? "Invalid emotional rating")
        }
        let dateResult = DataValidator.validateDate(date)
        if !dateResult.isValid {
            return AppError.validationError(dateResult.errorMessage ?? "Invalid date")
        }
        return nil
    }
    
    func updateConversation(_ conversation: NSManagedObject) {
        CoreDataStack.shared.save()
        self.loadConversations()
    }
    
    func deleteConversation(_ conversation: NSManagedObject) {
        CoreDataStack.shared.delete(conversation)
        self.loadConversations()
    }
    
    @discardableResult
    func createContact(name: String, relationshipTag: String?, photoData: Data?) -> NSManagedObject? {
        // Validate inputs
        let nameResult = DataValidator.validateName(name)
        if !nameResult.isValid {
            errorHandler.handle(AppError.validationError(nameResult.errorMessage ?? "Invalid name"))
            return nil
        }
        
        if let tag = relationshipTag, !tag.isEmpty {
            let tagResult = DataValidator.validateRelationshipTag(tag)
            if !tagResult.isValid {
                errorHandler.handle(AppError.validationError(tagResult.errorMessage ?? "Invalid relationship tag"))
                return nil
            }
        }
        
        // Process and validate image
        var processedPhotoData: Data? = nil
        if let photoData = photoData {
            let imageResult = DataValidator.validateImage(photoData)
            if !imageResult.isValid {
                errorHandler.handle(AppError.imageProcessingError(imageResult.errorMessage ?? "Image too large"))
                return nil
            }
            
            if let image = UIImage(data: photoData) {
                processedPhotoData = ImageProcessor.compressImage(image)
            } else {
                errorHandler.handle(AppError.imageProcessingError("Invalid image data"))
                return nil
            }
        }
        
        // Ensure persistent container is loaded
        _ = CoreDataStack.shared.persistentContainer
        
        let context = CoreDataStack.shared.viewContext
        
        // Verify context is valid
        guard context.persistentStoreCoordinator != nil else {
            errorHandler.handle(AppError.coreDataError("Core Data is not initialized"))
            return nil
        }
        
        // Verify entity exists
        guard let entity = NSEntityDescription.entity(forEntityName: "Contact", in: context) else {
            errorHandler.handle(AppError.coreDataError("Contact entity not found"))
            return nil
        }
        
        let contact = NSManagedObject(entity: entity, insertInto: context)
        contact.contactId = UUID()
        contact.contactName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        contact.contactRelationshipTag = relationshipTag?.trimmingCharacters(in: .whitespacesAndNewlines)
        contact.contactPhotoData = processedPhotoData
        
        do {
            try context.save()
            print("Contact created successfully: \(name)")
            self.loadContacts()
            return contact
        } catch {
            print("Error saving contact: \(error.localizedDescription)")
            context.rollback()
            errorHandler.handle(AppError.coreDataError("Failed to save contact: \(error.localizedDescription)"))
            return nil
        }
    }
    
    func updateContact(_ contact: NSManagedObject) {
        CoreDataStack.shared.save()
        self.loadContacts()
    }
    
    func deleteContact(_ contact: NSManagedObject) {
        CoreDataStack.shared.delete(contact)
        self.loadContacts()
    }
    
    @discardableResult
    func createCategory(name: String, iconName: String, accentColor: String) -> NSManagedObject? {
        // Validate inputs
        let nameResult = DataValidator.validateCategoryName(name)
        if !nameResult.isValid {
            errorHandler.handle(AppError.validationError(nameResult.errorMessage ?? "Invalid category name"))
            return nil
        }
        
        // Ensure persistent container is loaded
        _ = CoreDataStack.shared.persistentContainer
        
        let context = CoreDataStack.shared.viewContext
        
        // Verify context is valid
        guard context.persistentStoreCoordinator != nil else {
            errorHandler.handle(AppError.coreDataError("Core Data is not initialized"))
            return nil
        }
        
        // Verify entity exists
        guard let entity = NSEntityDescription.entity(forEntityName: "Category", in: context) else {
            errorHandler.handle(AppError.coreDataError("Category entity not found"))
            return nil
        }
        
        let category = NSManagedObject(entity: entity, insertInto: context)
        category.categoryId = UUID()
        category.categoryName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        category.categoryIconName = iconName
        category.categoryAccentColor = accentColor
        
        do {
            try context.save()
            print("Category created successfully: \(name)")
            self.loadCategories()
            return category
        } catch {
            print("Error saving category: \(error.localizedDescription)")
            context.rollback()
            errorHandler.handle(AppError.coreDataError("Failed to save category: \(error.localizedDescription)"))
            return nil
        }
    }
    
    func updateCategory(_ category: NSManagedObject) {
        CoreDataStack.shared.save()
        self.loadCategories()
    }
    
    func deleteCategory(_ category: NSManagedObject) {
        CoreDataStack.shared.delete(category)
        self.loadCategories()
    }
    
    @discardableResult
    func createTemplatePhrase(text: String, category: NSManagedObject?) -> NSManagedObject? {
        // Validate inputs
        let textResult = DataValidator.validateTemplatePhrase(text)
        if !textResult.isValid {
            errorHandler.handle(AppError.validationError(textResult.errorMessage ?? "Invalid template phrase"))
            return nil
        }
        
        // Ensure persistent container is loaded
        _ = CoreDataStack.shared.persistentContainer
        
        let context = CoreDataStack.shared.viewContext
        
        // Verify context is valid
        guard context.persistentStoreCoordinator != nil else {
            errorHandler.handle(AppError.coreDataError("Core Data is not initialized"))
            return nil
        }
        
        // Verify entity exists
        guard let entity = NSEntityDescription.entity(forEntityName: "TemplatePhrase", in: context) else {
            errorHandler.handle(AppError.coreDataError("TemplatePhrase entity not found"))
            return nil
        }
        
        let phrase = NSManagedObject(entity: entity, insertInto: context)
        phrase.templatePhraseId = UUID()
        phrase.templatePhraseText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        phrase.templatePhraseCategory = category
        
        do {
            try context.save()
            print("Template phrase created successfully: \(text)")
            self.loadTemplatePhrases()
            return phrase
        } catch {
            print("Error saving template phrase: \(error.localizedDescription)")
            context.rollback()
            errorHandler.handle(AppError.coreDataError("Failed to save template phrase: \(error.localizedDescription)"))
            return nil
        }
    }
    
    func deleteTemplatePhrase(_ phrase: NSManagedObject) {
        CoreDataStack.shared.delete(phrase)
        loadTemplatePhrases()
    }
    
    // Statistics
    func conversationsCount() -> Int {
        conversations.count
    }
    
    func conversationsWithContact(_ contact: NSManagedObject) -> [NSManagedObject] {
        conversations.filter { conversation in
            if let contacts = conversation.value(forKey: "contacts") as? NSSet {
                return contacts.contains(contact)
            }
            return false
        }
    }
    
    func conversationsInCategory(_ category: NSManagedObject) -> [NSManagedObject] {
        conversations.filter { conversation in
            if let convCategory = conversation.value(forKey: "category") as? NSManagedObject {
                return convCategory == category
            }
            return false
        }
    }
    
    func conversationsOnDate(_ date: Date) -> [NSManagedObject] {
        let calendar = Calendar.current
        return conversations.filter { conversation in
            if let convDate = conversation.conversationDate {
                return calendar.isDate(convDate, inSameDayAs: date)
            }
            return false
        }
    }
    
    func averageEmotionalRating() -> Double {
        let ratings = conversations.map { $0.conversationEmotionalRating }
        guard !ratings.isEmpty else { return 0 }
        return Double(ratings.reduce(0, +)) / Double(ratings.count)
    }
    
    func mostDiscussedContact() -> NSManagedObject? {
        var contactCounts: [NSManagedObject: Int] = [:]
        for conversation in conversations {
            if let contacts = conversation.value(forKey: "contacts") as? NSSet {
                for contact in contacts {
                    if let contactObj = contact as? NSManagedObject {
                        contactCounts[contactObj, default: 0] += 1
                    }
                }
            }
        }
        return contactCounts.max(by: { $0.value < $1.value })?.key
    }
    
    func mostDiscussedCategory() -> NSManagedObject? {
        var categoryCounts: [NSManagedObject: Int] = [:]
        for conversation in conversations {
            if let category = conversation.value(forKey: "category") as? NSManagedObject {
                categoryCounts[category, default: 0] += 1
            }
        }
        return categoryCounts.max(by: { $0.value < $1.value })?.key
    }
}

