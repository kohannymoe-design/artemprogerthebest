import CoreData
import SwiftUI

class CoreDataStack: ObservableObject {
    static let shared = CoreDataStack()
    
    lazy var persistentContainer: NSPersistentContainer = {
        // Create the model programmatically if the .xcdatamodeld file is not found in bundle
        let model = createManagedObjectModel()
        let container = NSPersistentContainer(name: "MoneyConversationModel", managedObjectModel: model)
        
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data store failed to load: \(error.localizedDescription)")
                print("Error details: \(error)")
                print("Store URL: \(description.url?.absoluteString ?? "nil")")
            } else {
                print("Core Data store loaded successfully")
                print("Store URL: \(description.url?.absoluteString ?? "nil")")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }()
    
    private func createManagedObjectModel() -> NSManagedObjectModel {
        // Try to load from bundle first
        if let modelURL = Bundle.main.url(forResource: "MoneyConversationModel", withExtension: "momd"),
           let model = NSManagedObjectModel(contentsOf: modelURL) {
            print("Loaded model from bundle")
            return model
        }
        
        // Create model programmatically
        print("Creating model programmatically")
        let model = NSManagedObjectModel()
        
        // Conversation Entity
        let conversationEntity = NSEntityDescription()
        conversationEntity.name = "Conversation"
        conversationEntity.managedObjectClassName = "Conversation"
        
        let conversationId = NSAttributeDescription()
        conversationId.name = "id"
        conversationId.attributeType = .UUIDAttributeType
        conversationId.isOptional = false
        
        let conversationTitle = NSAttributeDescription()
        conversationTitle.name = "title"
        conversationTitle.attributeType = .stringAttributeType
        conversationTitle.isOptional = false
        
        let conversationDate = NSAttributeDescription()
        conversationDate.name = "date"
        conversationDate.attributeType = .dateAttributeType
        conversationDate.isOptional = false
        
        let conversationGoal = NSAttributeDescription()
        conversationGoal.name = "goal"
        conversationGoal.attributeType = .stringAttributeType
        conversationGoal.isOptional = true
        
        let conversationOutcome = NSAttributeDescription()
        conversationOutcome.name = "outcome"
        conversationOutcome.attributeType = .stringAttributeType
        conversationOutcome.isOptional = true
        
        let conversationEmotionalRating = NSAttributeDescription()
        conversationEmotionalRating.name = "emotionalRating"
        conversationEmotionalRating.attributeType = .integer16AttributeType
        conversationEmotionalRating.isOptional = true
        conversationEmotionalRating.defaultValue = 5
        
        let conversationNotes = NSAttributeDescription()
        conversationNotes.name = "notes"
        conversationNotes.attributeType = .stringAttributeType
        conversationNotes.isOptional = true
        
        let conversationIsResolved = NSAttributeDescription()
        conversationIsResolved.name = "isResolved"
        conversationIsResolved.attributeType = .booleanAttributeType
        conversationIsResolved.isOptional = true
        
        conversationEntity.properties = [
            conversationId, conversationTitle, conversationDate,
            conversationGoal, conversationOutcome, conversationEmotionalRating,
            conversationNotes, conversationIsResolved
        ]
        
        // Contact Entity
        let contactEntity = NSEntityDescription()
        contactEntity.name = "Contact"
        contactEntity.managedObjectClassName = "Contact"
        
        let contactId = NSAttributeDescription()
        contactId.name = "id"
        contactId.attributeType = .UUIDAttributeType
        contactId.isOptional = false
        
        let contactName = NSAttributeDescription()
        contactName.name = "name"
        contactName.attributeType = .stringAttributeType
        contactName.isOptional = false
        
        let contactPhotoData = NSAttributeDescription()
        contactPhotoData.name = "photoData"
        contactPhotoData.attributeType = .binaryDataAttributeType
        contactPhotoData.isOptional = true
        
        let contactRelationshipTag = NSAttributeDescription()
        contactRelationshipTag.name = "relationshipTag"
        contactRelationshipTag.attributeType = .stringAttributeType
        contactRelationshipTag.isOptional = true
        
        contactEntity.properties = [contactId, contactName, contactPhotoData, contactRelationshipTag]
        
        // Category Entity
        let categoryEntity = NSEntityDescription()
        categoryEntity.name = "Category"
        categoryEntity.managedObjectClassName = "Category"
        
        let categoryId = NSAttributeDescription()
        categoryId.name = "id"
        categoryId.attributeType = .UUIDAttributeType
        categoryId.isOptional = false
        
        let categoryName = NSAttributeDescription()
        categoryName.name = "name"
        categoryName.attributeType = .stringAttributeType
        categoryName.isOptional = false
        
        let categoryIconName = NSAttributeDescription()
        categoryIconName.name = "iconName"
        categoryIconName.attributeType = .stringAttributeType
        categoryIconName.isOptional = true
        
        let categoryAccentColor = NSAttributeDescription()
        categoryAccentColor.name = "accentColor"
        categoryAccentColor.attributeType = .stringAttributeType
        categoryAccentColor.isOptional = true
        
        categoryEntity.properties = [categoryId, categoryName, categoryIconName, categoryAccentColor]
        
        // TemplatePhrase Entity
        let templatePhraseEntity = NSEntityDescription()
        templatePhraseEntity.name = "TemplatePhrase"
        templatePhraseEntity.managedObjectClassName = "TemplatePhrase"
        
        let templatePhraseId = NSAttributeDescription()
        templatePhraseId.name = "id"
        templatePhraseId.attributeType = .UUIDAttributeType
        templatePhraseId.isOptional = false
        
        let templatePhraseText = NSAttributeDescription()
        templatePhraseText.name = "text"
        templatePhraseText.attributeType = .stringAttributeType
        templatePhraseText.isOptional = false
        
        templatePhraseEntity.properties = [templatePhraseId, templatePhraseText]
        
        // Relationships
        let conversationToContacts = NSRelationshipDescription()
        conversationToContacts.name = "contacts"
        conversationToContacts.destinationEntity = contactEntity
        conversationToContacts.maxCount = 0 // toMany
        conversationToContacts.deleteRule = .nullifyDeleteRule
        
        let contactToConversations = NSRelationshipDescription()
        contactToConversations.name = "conversations"
        contactToConversations.destinationEntity = conversationEntity
        contactToConversations.maxCount = 0 // toMany
        contactToConversations.deleteRule = .nullifyDeleteRule
        
        conversationToContacts.inverseRelationship = contactToConversations
        contactToConversations.inverseRelationship = conversationToContacts
        
        let conversationToCategory = NSRelationshipDescription()
        conversationToCategory.name = "category"
        conversationToCategory.destinationEntity = categoryEntity
        conversationToCategory.maxCount = 1 // toOne
        conversationToCategory.deleteRule = .nullifyDeleteRule
        
        let categoryToConversations = NSRelationshipDescription()
        categoryToConversations.name = "conversations"
        categoryToConversations.destinationEntity = conversationEntity
        categoryToConversations.maxCount = 0 // toMany
        categoryToConversations.deleteRule = .nullifyDeleteRule
        
        conversationToCategory.inverseRelationship = categoryToConversations
        categoryToConversations.inverseRelationship = conversationToCategory
        
        let categoryToTemplatePhrases = NSRelationshipDescription()
        categoryToTemplatePhrases.name = "templatePhrases"
        categoryToTemplatePhrases.destinationEntity = templatePhraseEntity
        categoryToTemplatePhrases.maxCount = 0 // toMany
        categoryToTemplatePhrases.deleteRule = .cascadeDeleteRule
        
        let templatePhraseToCategory = NSRelationshipDescription()
        templatePhraseToCategory.name = "category"
        templatePhraseToCategory.destinationEntity = categoryEntity
        templatePhraseToCategory.maxCount = 1 // toOne
        templatePhraseToCategory.deleteRule = .nullifyDeleteRule
        
        categoryToTemplatePhrases.inverseRelationship = templatePhraseToCategory
        templatePhraseToCategory.inverseRelationship = categoryToTemplatePhrases
        
        conversationEntity.properties.append(conversationToContacts)
        conversationEntity.properties.append(conversationToCategory)
        contactEntity.properties.append(contactToConversations)
        categoryEntity.properties.append(categoryToConversations)
        categoryEntity.properties.append(categoryToTemplatePhrases)
        templatePhraseEntity.properties.append(templatePhraseToCategory)
        
        model.entities = [conversationEntity, contactEntity, categoryEntity, templatePhraseEntity]
        
        return model
    }
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func save() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
                print("Context saved successfully")
            } catch {
                print("Error saving context: \(error.localizedDescription)")
                print("Full error: \(error)")
            }
        }
    }
    
    func delete(_ object: NSManagedObject) {
        viewContext.delete(object)
        save()
    }
}

