import SwiftUI
import UIKit
import CoreData

struct ConversationFormView: View {
    @Environment(\.dismiss) var dismiss
    let viewModel: ConversationViewModel
    let conversation: NSManagedObject?
    
    @State private var title: String = ""
    @State private var selectedContacts: Set<NSManagedObject> = []
    @State private var date: Date = Date()
    @State private var selectedCategory: NSManagedObject?
    @State private var goal: String = ""
    @State private var outcome: String = ""
    @State private var emotionalRating: Double = 5.0
    @State private var notes: String = ""
    @State private var showingContactPicker = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Conversation Details") {
                    TextField("Title", text: $title)
                    
                    DatePicker("Date & Time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    
                    Picker("Category", selection: $selectedCategory) {
                        Text("None").tag(nil as NSManagedObject?)
                        ForEach(viewModel.categories, id: \.objectID) { category in
                            Text(category.categoryName ?? "Unknown").tag(category as NSManagedObject?)
                        }
                    }
                }
                
                Section("People") {
                    ForEach(Array(selectedContacts), id: \.objectID) { contact in
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
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(AppColors.trustBlue)
                                    )
                            }
                            VStack(alignment: .leading) {
                                Text(contact.contactName ?? "Unknown")
                                    .font(.system(size: 16, weight: .medium))
                                if let tag = contact.contactRelationshipTag {
                                    Text(tag)
                                        .font(.system(size: 12))
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }
                            Spacer()
                            Button(action: {
                                selectedContacts.remove(contact)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                    }
                    
                    Button(action: {
                        showingContactPicker = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Person")
                        }
                        .foregroundColor(AppColors.trustBlue)
                    }
                }
                
                Section("Preparation") {
                    TextField("Your goal before the talk", text: $goal, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Outcome") {
                    TextField("What actually happened", text: $outcome, axis: .vertical)
                        .lineLimit(3...6)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Emotional Rating: \(Int(emotionalRating))")
                            .font(.system(size: 16, weight: .medium))
                        
                        HStack {
                            Text("1")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.textSecondary)
                            Slider(value: $emotionalRating, in: 1...10, step: 1)
                            Text("10")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        // Breathing gauge visualization
                        EmotionalGaugeView(rating: Int(emotionalRating))
                    }
                }
                
                Section("Notes") {
                    TextField("Key notes, quotes, or reflections", text: $notes, axis: .vertical)
                        .lineLimit(5...10)
                }
            }
            .navigationTitle(conversation == nil ? "New Conversation" : "Edit Conversation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveConversation()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .sheet(isPresented: $showingContactPicker) {
                ContactPickerViewWrapper(
                    viewModel: viewModel,
                    selectedContacts: $selectedContacts
                )
            }
            .onAppear {
                if let conversation = conversation {
                    loadConversation(conversation)
                }
                viewModel.loadData()
            }
            .onChange(of: viewModel.categories) { _, _ in
                // Refresh when categories change
            }
            .withErrorHandling(viewModel.errorHandler)
        }
    }
    
    private func loadConversation(_ conversation: NSManagedObject) {
        title = conversation.conversationTitle ?? ""
        date = conversation.conversationDate ?? Date()
        selectedCategory = conversation.conversationCategory
        goal = conversation.conversationGoal ?? ""
        outcome = conversation.conversationOutcome ?? ""
        emotionalRating = Double(conversation.conversationEmotionalRating)
        notes = conversation.conversationNotes ?? ""
        
        if let contacts = conversation.conversationContacts as? NSSet {
            selectedContacts = Set(contacts.compactMap { $0 as? NSManagedObject })
        }
    }
    
    private func saveConversation() {
        if let conversation = conversation {
            conversation.conversationTitle = title
            conversation.conversationDate = date
            conversation.conversationCategory = selectedCategory
            conversation.conversationGoal = goal
            conversation.conversationOutcome = outcome
            conversation.conversationEmotionalRating = Int16(emotionalRating)
            conversation.conversationNotes = notes.isEmpty ? nil : notes
            conversation.conversationContacts = selectedContacts as NSSet
            viewModel.updateConversation(conversation)
        } else {
            viewModel.createConversation(
                title: title,
                contacts: selectedContacts,
                date: date,
                category: selectedCategory,
                goal: goal,
                outcome: outcome,
                emotionalRating: Int16(emotionalRating),
                notes: notes.isEmpty ? nil : notes
            )
        }
        dismiss()
    }
}

struct EmotionalGaugeView: View {
    let rating: Int
    @State private var breathingScale: CGFloat = 1.0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...10, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(index <= rating ? colorForRating(rating) : AppColors.mediumGray.opacity(0.3))
                    .frame(height: 24)
                    .scaleEffect(index == rating ? breathingScale : 1.0)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                breathingScale = 1.15
            }
        }
    }
    
    private func colorForRating(_ rating: Int) -> Color {
        if rating >= 8 {
            return AppColors.calmGreen
        } else if rating >= 5 {
            return AppColors.trustBlue
        } else {
            return AppColors.error
        }
    }
}

#Preview {
    ConversationFormView(viewModel: ConversationViewModel(context: CoreDataStack.shared.viewContext), conversation: nil)
}

