import SwiftUI
import CoreData

struct PreparationHelperView: View {
    var viewModel: ConversationViewModel
    @State private var selectedCategory: NSManagedObject?
    @State private var showingAddTemplate = false
    
    var similarConversations: [NSManagedObject] {
        guard let category = selectedCategory else { return [] }
        return viewModel.conversationsInCategory(category)
            .sorted { ($0.conversationDate ?? Date()) > ($1.conversationDate ?? Date()) }
            .prefix(5)
            .map { $0 }
    }
    
    var templatePhrases: [NSManagedObject] {
        if let category = selectedCategory {
            return viewModel.templatePhrases.filter { phrase in
                if let phraseCategory = phrase.templatePhraseCategory {
                    return phraseCategory == category
                }
                return false
            }
        }
        return viewModel.templatePhrases
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Category selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select Topic")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                        
                        if viewModel.categories.isEmpty {
                            Text("No categories yet. Create one to get started.")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.textSecondary)
                                .padding(20)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(AppColors.mediumGray.opacity(0.1))
                                )
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(viewModel.categories, id: \.objectID) { category in
                                        CategoryChip(
                                            category: category,
                                            isSelected: selectedCategory == category
                                        ) {
                                            selectedCategory = category
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                    
                    if let category = selectedCategory {
                        // Similar past conversations
                        if !similarConversations.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Similar Past Conversations")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(AppColors.textPrimary)
                                    .padding(.horizontal, 20)
                                
                                ForEach(similarConversations, id: \.objectID) { conversation in
                                    NavigationLink(destination: ConversationDetailView(conversation: conversation, viewModel: viewModel)) {
                                        PastConversationCard(conversation: conversation)
                                            .padding(.horizontal, 20)
                                    }
                                }
                            }
                            .padding(.top, 8)
                        }
                        
                        // Template phrases
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Template Phrases")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(AppColors.textPrimary)
                                
                                Spacer()
                                
                                Button(action: {
                                    showingAddTemplate = true
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(AppColors.trustBlue)
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            if templatePhrases.isEmpty {
                                Text("No template phrases yet. Add some to help you prepare.")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppColors.textSecondary)
                                    .padding(20)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(AppColors.mediumGray.opacity(0.1))
                                    )
                                    .padding(.horizontal, 20)
                            } else {
                                ForEach(templatePhrases, id: \.objectID) { phrase in
                                    TemplatePhraseCard(phrase: phrase, viewModel: viewModel)
                                        .padding(.horizontal, 20)
                                }
                            }
                        }
                        .padding(.top, 8)
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "lightbulb")
                                .font(.system(size: 48))
                                .foregroundColor(AppColors.textSecondary.opacity(0.5))
                            Text("Select a topic to see preparation tips")
                                .font(.system(size: 16))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(40)
                    }
                }
                .padding(.vertical, 20)
            }
            .background(AppColors.backgroundLight)
            .navigationTitle("Preparation Helper")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAddTemplate) {
                AddTemplatePhraseView(viewModel: viewModel, category: selectedCategory)
            }
            .onAppear {
                viewModel.loadData()
            }
            .withErrorHandling(viewModel.errorHandler)
        }
    }
}

struct CategoryChip: View {
    let category: NSManagedObject
    let isSelected: Bool
    let action: () -> Void
    
    var accentColor: Color {
        if let colorHex = category.categoryAccentColor {
            return Color(hex: colorHex)
        }
        return AppColors.trustBlue
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.categoryIconName ?? "folder")
                    .font(.system(size: 16))
                Text(category.categoryName ?? "Unknown")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : AppColors.textPrimary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(isSelected ? accentColor : AppColors.mediumGray.opacity(0.2))
            )
        }
    }
}

struct PastConversationCard: View {
    let conversation: NSManagedObject
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if let date = conversation.conversationDate {
                    Text(date, style: .date)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer()
                Text("Rating: \(Int(conversation.conversationEmotionalRating))/10")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
            }
            
            if let goal = conversation.conversationGoal, !goal.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Goal:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                    Text(goal)
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textPrimary)
                }
            }
            
            if let outcome = conversation.conversationOutcome, !outcome.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Outcome:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                    Text(outcome)
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.cardBackground)
                .shadow(color: AppColors.shadowColorLight, radius: 4, x: 0, y: 2)
        )
    }
}

struct TemplatePhraseCard: View {
    let phrase: NSManagedObject
    let viewModel: ConversationViewModel
    
    var body: some View {
        HStack {
            Text(phrase.templatePhraseText ?? "")
                .font(.system(size: 16))
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            Button(action: {
                viewModel.deleteTemplatePhrase(phrase)
            }) {
                Image(systemName: "trash")
                    .foregroundColor(AppColors.error)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.softBeige.opacity(0.5))
        )
    }
}

struct AddTemplatePhraseView: View {
    @Environment(\.dismiss) var dismiss
    var viewModel: ConversationViewModel
    let category: NSManagedObject?
    @State private var text: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Template Phrase") {
                    TextField("Enter a helpful phrase or question", text: $text, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                if category != nil {
                    Section {
                        HStack {
                            Text("Category:")
                            Spacer()
                            Text(category?.categoryName ?? "Unknown")
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
            }
            .navigationTitle("New Template Phrase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePhrase()
                    }
                    .disabled(text.isEmpty)
                }
            }
        }
    }
    
    private func savePhrase() {
        viewModel.createTemplatePhrase(text: text, category: category)
        dismiss()
    }
}

#Preview {
    PreparationHelperView(viewModel: ConversationViewModel(context: CoreDataStack.shared.viewContext))
}

