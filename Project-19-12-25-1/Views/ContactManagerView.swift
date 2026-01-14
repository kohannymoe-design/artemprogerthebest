import SwiftUI
import UIKit
import CoreData

struct ContactManagerView: View {
    var viewModel: ConversationViewModel
    @State private var showingAddContact = false
    @State private var searchText = ""
    
    var filteredContacts: [NSManagedObject] {
        if searchText.isEmpty {
            return viewModel.contacts
        }
        return viewModel.contacts.filter { contact in
            (contact.contactName ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredContacts, id: \.objectID) { contact in
                    NavigationLink(destination: ContactDetailView(contact: contact, viewModel: viewModel)) {
                        ContactListRow(contact: contact, viewModel: viewModel)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.deleteContact(filteredContacts[index])
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search contacts")
            .navigationTitle("Contacts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showingAddContact = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddContact) {
                AddContactView(viewModel: viewModel)
            }
            .onAppear {
                viewModel.loadData()
            }
            .withErrorHandling(viewModel.errorHandler)
        }
    }
}

struct ContactListRow: View {
    let contact: NSManagedObject
    let viewModel: ConversationViewModel
    
    var conversationCount: Int {
        viewModel.conversationsWithContact(contact).count
    }
    
    var body: some View {
        HStack(spacing: 16) {
            if let photoData = contact.contactPhotoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(AppColors.trustBlue.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(String((contact.contactName ?? "?").prefix(1)))
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(AppColors.trustBlue)
                    )
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(contact.contactName ?? "Unknown")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                
                if let tag = contact.contactRelationshipTag {
                    Text(tag)
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Text("\(conversationCount) conversation\(conversationCount == 1 ? "" : "s")")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct ContactDetailView: View {
    let contact: NSManagedObject
    var viewModel: ConversationViewModel
    @State private var showingEdit = false
    
    var conversations: [NSManagedObject] {
        viewModel.conversationsWithContact(contact)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Contact header
                VStack(spacing: 16) {
                    if let photoData = contact.contactPhotoData, let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(AppColors.trustBlue.opacity(0.2))
                            .frame(width: 120, height: 120)
                            .overlay(
                                Text(String((contact.contactName ?? "?").prefix(1)))
                                    .font(.system(size: 48, weight: .medium))
                                    .foregroundColor(AppColors.trustBlue)
                            )
                    }
                    
                    Text(contact.contactName ?? "Unknown")
                        .font(.system(size: 28, weight: .medium))
                    
                    if let tag = contact.contactRelationshipTag {
                        Text(tag)
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    Text("\(conversations.count) conversation\(conversations.count == 1 ? "" : "s")")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(20)
                
                // Conversations list
                VStack(alignment: .leading, spacing: 12) {
                    Text("Conversations")
                        .font(.system(size: 22, weight: .medium))
                        .padding(.horizontal, 20)
                    
                    if conversations.isEmpty {
                        EmptyStateView(
                            title: "No conversations",
                            message: "This contact has no conversations yet",
                            icon: "bubble.left.and.bubble.right"
                        )
                        .padding(.horizontal, 20)
                    } else {
                        ForEach(conversations, id: \.objectID) { conversation in
                            NavigationLink(destination: ConversationDetailView(conversation: conversation, viewModel: viewModel)) {
                                ConversationCard(conversation: conversation)
                                    .padding(.horizontal, 20)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 20)
        }
        .background(AppColors.backgroundLight)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    showingEdit = true
                }) {
                    Text("Edit")
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditContactView(contact: contact, viewModel: viewModel)
        }
    }
}

struct EditContactView: View {
    let contact: NSManagedObject
    @Environment(\.dismiss) var dismiss
    var viewModel: ConversationViewModel
    @State private var name: String = ""
    @State private var relationshipTag: String = ""
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Contact Information") {
                    TextField("Name", text: $name)
                    TextField("Relationship", text: $relationshipTag)
                }
                
                Section("Photo") {
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        HStack {
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                            } else if let photoData = contact.contactPhotoData, let uiImage = UIImage(data: photoData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "photo.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(AppColors.trustBlue)
                            }
                            Text(selectedImage == nil ? "Change Photo" : "Update Photo")
                                .foregroundColor(AppColors.trustBlue)
                        }
                    }
                }
            }
            .navigationTitle("Edit Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveContact()
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .onAppear {
                name = contact.contactName ?? ""
                relationshipTag = contact.contactRelationshipTag ?? ""
            }
        }
    }
    
    private func saveContact() {
        contact.contactName = name
        contact.contactRelationshipTag = relationshipTag.isEmpty ? nil : relationshipTag
        if let image = selectedImage {
            contact.contactPhotoData = ImageProcessor.compressImage(image)
        }
        viewModel.updateContact(contact)
        dismiss()
    }
}

#Preview {
    ContactManagerView(viewModel: ConversationViewModel(context: CoreDataStack.shared.viewContext))
}

