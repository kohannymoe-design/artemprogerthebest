import SwiftUI
import UIKit
import CoreData

struct ContactPickerView: View {
    @Binding var contacts: [NSManagedObject]
    @Binding var selectedContacts: Set<NSManagedObject>
    var viewModel: ConversationViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingAddContact = false
    @State private var searchText = ""
    
    var filteredContacts: [NSManagedObject] {
        if searchText.isEmpty {
            return contacts
        }
        return contacts.filter { contact in
            (contact.contactName ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button(action: {
                        showingAddContact = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("New Contact")
                        }
                        .foregroundColor(AppColors.trustBlue)
                    }
                }
                
                Section("Contacts") {
                    ForEach(filteredContacts, id: \.objectID) { contact in
                        ContactRow(
                            contact: contact,
                            isSelected: selectedContacts.contains(contact)
                        ) {
                            if selectedContacts.contains(contact) {
                                selectedContacts.remove(contact)
                            } else {
                                selectedContacts.insert(contact)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search contacts")
            .navigationTitle("Select People")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddContact) {
                AddContactView(viewModel: viewModel) {
                    // Reload contacts after creating new one
                    viewModel.loadContacts()
                    contacts = viewModel.contacts
                }
            }
            .onAppear {
                viewModel.loadContacts()
                contacts = viewModel.contacts
            }
            .onChange(of: viewModel.contacts) { oldValue, newValue in
                contacts = newValue
            }
        }
    }
}

struct ContactRow: View {
    let contact: NSManagedObject
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let photoData = contact.contactPhotoData, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(AppColors.trustBlue.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text(String((contact.contactName ?? "?").prefix(1)))
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(AppColors.trustBlue)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.contactName ?? "Unknown")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                    if let tag = contact.contactRelationshipTag {
                        Text(tag)
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.trustBlue)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AddContactView: View {
    @Environment(\.dismiss) var dismiss
    var viewModel: ConversationViewModel
    var onContactCreated: (() -> Void)?
    @State private var name: String = ""
    @State private var relationshipTag: String = ""
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Contact Information") {
                    TextField("Name", text: $name)
                    TextField("Relationship (e.g., Partner, Family)", text: $relationshipTag)
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
                            } else {
                                Image(systemName: "photo.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(AppColors.trustBlue)
                            }
                            Text(selectedImage == nil ? "Add Photo" : "Change Photo")
                                .foregroundColor(AppColors.trustBlue)
                        }
                    }
                }
            }
            .navigationTitle("New Contact")
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
                    .disabled(name.isEmpty)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
        }
    }
    
    private func saveContact() {
        let photoData = selectedImage.flatMap { ImageProcessor.compressImage($0) }
        if viewModel.createContact(
            name: name,
            relationshipTag: relationshipTag.isEmpty ? nil : relationshipTag,
            photoData: photoData
        ) != nil {
            onContactCreated?()
        }
        dismiss()
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct ContactPickerViewWrapper: View {
    @State var viewModel: ConversationViewModel
    @Binding var selectedContacts: Set<NSManagedObject>
    @State private var contacts: [NSManagedObject] = []
    
    var body: some View {
        ContactPickerView(
            contacts: $contacts,
            selectedContacts: $selectedContacts,
            viewModel: viewModel
        )
        .onAppear {
            viewModel.loadContacts()
            contacts = viewModel.contacts
        }
    }
}

#Preview {
    ContactPickerView(
        contacts: .constant([]),
        selectedContacts: .constant([]),
        viewModel: ConversationViewModel(context: CoreDataStack.shared.viewContext)
    )
}

