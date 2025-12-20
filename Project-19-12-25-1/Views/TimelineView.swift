import SwiftUI
import CoreData

struct TimelineView: View {
    var viewModel: ConversationViewModel
    @State private var selectedPerson: NSManagedObject?
    @State private var selectedCategory: NSManagedObject?
    @State private var selectedOutcome: OutcomeFilter = .all
    @State private var showingPersonPicker = false
    @State private var showingCategoryPicker = false
    
    enum OutcomeFilter: String, CaseIterable {
        case all = "All"
        case successful = "Successful"
        case difficult = "Difficult"
        case neutral = "Neutral"
    }
    
    var filteredConversations: [NSManagedObject] {
        var conversations = viewModel.conversations
        
        if let person = selectedPerson {
            conversations = conversations.filter { conversation in
                if let contacts = conversation.conversationContacts as? NSSet {
                    return contacts.contains(person)
                }
                return false
            }
        }
        
        if let category = selectedCategory {
            conversations = conversations.filter { conversation in
                if let convCategory = conversation.conversationCategory {
                    return convCategory == category
                }
                return false
            }
        }
        
        switch selectedOutcome {
        case .successful:
            conversations = conversations.filter { Int($0.conversationEmotionalRating) >= 8 }
        case .difficult:
            conversations = conversations.filter { Int($0.conversationEmotionalRating) < 5 }
        case .neutral:
            conversations = conversations.filter { Int($0.conversationEmotionalRating) >= 5 && Int($0.conversationEmotionalRating) < 8 }
        case .all:
            break
        }
        
        return conversations.sorted { ($0.conversationDate ?? Date()) > ($1.conversationDate ?? Date()) }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterChip(
                            title: "Person",
                            value: selectedPerson?.contactName ?? "All",
                            isActive: selectedPerson != nil
                        ) {
                            showingPersonPicker = true
                        }
                        
                        FilterChip(
                            title: "Category",
                            value: selectedCategory?.categoryName ?? "All",
                            isActive: selectedCategory != nil
                        ) {
                            showingCategoryPicker = true
                        }
                        
                        ForEach(OutcomeFilter.allCases, id: \.self) { outcome in
                            FilterChip(
                                title: outcome.rawValue,
                                value: "",
                                isActive: selectedOutcome == outcome
                            ) {
                                selectedOutcome = outcome
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                .background(AppColors.cardBackground)
                
                Divider()
                
                // Timeline
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(filteredConversations, id: \.objectID) { conversation in
                            TimelineItemView(
                                conversation: conversation,
                                viewModel: viewModel,
                                isFirst: filteredConversations.first?.objectID == conversation.objectID
                            )
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
            .background(AppColors.backgroundLight)
            .navigationTitle("Timeline")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingPersonPicker) {
                PersonPickerView(
                    contacts: viewModel.contacts,
                    selectedPerson: $selectedPerson
                )
            }
            .sheet(isPresented: $showingCategoryPicker) {
                CategoryPickerView(
                    categories: viewModel.categories,
                    selectedCategory: $selectedCategory
                )
            }
            .onAppear {
                viewModel.loadData()
            }
            .withErrorHandling(viewModel.errorHandler)
        }
    }
}

struct PersonPickerView: View {
    let contacts: [NSManagedObject]
    @Binding var selectedPerson: NSManagedObject?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Button(action: {
                    selectedPerson = nil
                    dismiss()
                }) {
                    HStack {
                        Text("All")
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        if selectedPerson == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(AppColors.trustBlue)
                        }
                    }
                }
                
                ForEach(contacts, id: \.objectID) { contact in
                    Button(action: {
                        selectedPerson = contact
                        dismiss()
                    }) {
                        HStack {
                            if let photoData = contact.contactPhotoData, let uiImage = UIImage(data: photoData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(AppColors.trustBlue.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text(String((contact.contactName ?? "?").prefix(1)))
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(AppColors.trustBlue)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(contact.contactName ?? "Unknown")
                                    .foregroundColor(AppColors.textPrimary)
                                if let tag = contact.contactRelationshipTag {
                                    Text(tag)
                                        .font(.system(size: 12))
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }
                            
                            Spacer()
                            
                            if selectedPerson == contact {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppColors.trustBlue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Person")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct CategoryPickerView: View {
    let categories: [NSManagedObject]
    @Binding var selectedCategory: NSManagedObject?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Button(action: {
                    selectedCategory = nil
                    dismiss()
                }) {
                    HStack {
                        Text("All")
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        if selectedCategory == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(AppColors.trustBlue)
                        }
                    }
                }
                
                ForEach(categories, id: \.objectID) { category in
                    Button(action: {
                        selectedCategory = category
                        dismiss()
                    }) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: category.categoryAccentColor ?? "4A7C9B").opacity(0.2))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: category.categoryIconName ?? "folder")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(hex: category.categoryAccentColor ?? "4A7C9B"))
                            }
                            
                            Text(category.categoryName ?? "Unknown")
                                .foregroundColor(AppColors.textPrimary)
                            
                            Spacer()
                            
                            if selectedCategory == category {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppColors.trustBlue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct FilterChip: View {
    let title: String
    let value: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                if !value.isEmpty {
                    Text(value)
                        .font(.system(size: 12))
                        .opacity(0.7)
                }
            }
            .foregroundColor(isActive ? .white : AppColors.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isActive ? AppColors.trustBlue : AppColors.mediumGray.opacity(0.2))
            )
        }
    }
}

struct TimelineItemView: View {
    let conversation: NSManagedObject
    let viewModel: ConversationViewModel
    let isFirst: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline line
            VStack(spacing: 0) {
                Circle()
                    .fill(AppColors.trustBlue)
                    .frame(width: 12, height: 12)
                
                if !isFirst {
                    Rectangle()
                        .fill(AppColors.mediumGray.opacity(0.3))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 12)
            
            // Content
            NavigationLink(destination: ConversationDetailView(conversation: conversation, viewModel: viewModel)) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(conversation.conversationTitle ?? "Untitled")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                    
                    if let date = conversation.conversationDate {
                        Text(date.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    HStack(spacing: 8) {
                        if let category = conversation.conversationCategory {
                            HStack(spacing: 4) {
                                Image(systemName: category.categoryIconName ?? "folder")
                                    .font(.system(size: 12))
                                Text(category.categoryName ?? "")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(Color(hex: category.categoryAccentColor ?? "4A7C9B"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color(hex: category.categoryAccentColor ?? "4A7C9B").opacity(0.1))
                            )
                        }
                        
                        Text("Rating: \(Int(conversation.conversationEmotionalRating))/10")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.cardBackground)
                        .shadow(color: AppColors.shadowColorLight, radius: 4, x: 0, y: 2)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
}

#Preview {
    TimelineView(viewModel: ConversationViewModel(context: CoreDataStack.shared.viewContext))
}

