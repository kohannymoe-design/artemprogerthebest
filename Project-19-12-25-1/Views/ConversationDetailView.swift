import SwiftUI
import UIKit
import CoreData

struct ConversationDetailView: View {
    let conversation: NSManagedObject
    var viewModel: ConversationViewModel
    @State private var showingEdit = false
    @State private var showingFollowUp = false
    @State private var isResolved: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                goalOutcomeSection
                emotionalRatingSection
                notesSection
                actionsSection
            }
            .padding(.vertical, 20)
        }
        .background(AppColors.backgroundLight)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEdit) {
            ConversationFormView(viewModel: viewModel, conversation: conversation)
        }
        .sheet(isPresented: $showingFollowUp) {
            ConversationFormView(viewModel: viewModel, conversation: nil)
        }
        .withErrorHandling(viewModel.errorHandler)
        .onAppear {
            isResolved = conversation.conversationIsResolved
        }
    }
    
    init(conversation: NSManagedObject, viewModel: ConversationViewModel) {
        self.conversation = conversation
        self.viewModel = viewModel
        _isResolved = State(initialValue: conversation.conversationIsResolved)
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(conversation.conversationTitle ?? "Untitled")
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
            
            if let date = conversation.conversationDate {
                Label(date.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.textSecondary)
            }
            
            participantsView
        }
        .padding(20)
        .background(headerBackground)
    }
    
    private var headerBackground: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(AppColors.cardBackground)
            .shadow(color: AppColors.shadowColor, radius: 8, x: 0, y: 2)
    }
    
    @ViewBuilder
    private var participantsView: some View {
        if let contacts = conversation.conversationContacts as? NSSet, contacts.count > 0 {
            let contactArray = contacts.compactMap { $0 as? NSManagedObject }
            if !contactArray.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(contactArray, id: \.objectID) { contact in
                            ContactChip(contact: contact)
                        }
                    }
                }
            }
        }
    }
    
    private var goalOutcomeSection: some View {
        HStack(spacing: 16) {
            ComparisonCard(
                title: "Goal",
                content: conversation.conversationGoal ?? "No goal set",
                color: AppColors.trustBlue
            )
            ComparisonCard(
                title: "Outcome",
                content: conversation.conversationOutcome ?? "No outcome recorded",
                color: AppColors.calmGreen
            )
        }
        .padding(.horizontal, 20)
    }
    
    private var emotionalRatingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Emotional Rating")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
            
            EmotionalGaugeView(rating: Int(conversation.conversationEmotionalRating))
            
            Text("Rating: \(Int(conversation.conversationEmotionalRating))/10")
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(20)
        .background(ratingBackground)
        .padding(.horizontal, 20)
    }
    
    private var ratingBackground: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(AppColors.cardBackground)
            .shadow(color: AppColors.shadowColor, radius: 8, x: 0, y: 2)
    }
    
    @ViewBuilder
    private var notesSection: some View {
        if let notes = conversation.conversationNotes, !notes.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Notes")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(notes)
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.textPrimary)
                    .lineSpacing(4)
            }
            .padding(20)
            .background(notesBackground)
            .padding(.horizontal, 20)
        }
    }
    
    private var notesBackground: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(AppColors.cardBackground)
            .shadow(color: AppColors.shadowColor, radius: 8, x: 0, y: 2)
    }
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            editButton
            followUpButton
            resolveButton
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 20)
    }
    
    private var editButton: some View {
        Button(action: {
            showingEdit = true
        }) {
            HStack {
                Image(systemName: "pencil")
                Text("Edit Conversation")
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(AppColors.trustBlue)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private var followUpButton: some View {
        Button(action: {
            showingFollowUp = true
        }) {
            HStack {
                Image(systemName: "plus.circle")
                Text("Add Follow-up")
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(AppColors.trustBlue)
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(AppColors.trustBlue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private var resolveButton: some View {
        Button(action: {
            withAnimation {
                isResolved.toggle()
                conversation.conversationIsResolved = isResolved
                viewModel.updateConversation(conversation)
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: isResolved ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                Text(isResolved ? "Mark as Unresolved" : "Mark as Resolved")
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(isResolved ? AppColors.calmGreen : AppColors.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 50)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(isResolved ? AppColors.calmGreen.opacity(0.1) : AppColors.mediumGray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

struct ComparisonCard: View {
    let title: String
    let content: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)
            Text(content)
                .font(.system(size: 16))
                .foregroundColor(AppColors.textPrimary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(color.opacity(0.1))
        )
    }
}

struct ContactChip: View {
    let contact: NSManagedObject
    
    var body: some View {
        HStack(spacing: 8) {
            if let photoData = contact.contactPhotoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(AppColors.trustBlue.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(String((contact.contactName ?? "?").prefix(1)))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.trustBlue)
                    )
            }
            Text(contact.contactName ?? "Unknown")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(AppColors.mediumGray.opacity(0.2))
        )
    }
}

#Preview {
    NavigationStack {
        let entity = NSEntityDescription.entity(forEntityName: "Conversation", in: CoreDataStack.shared.viewContext)!
        let conversation = NSManagedObject(entity: entity, insertInto: nil)
        return ConversationDetailView(
            conversation: conversation,
            viewModel: ConversationViewModel(context: CoreDataStack.shared.viewContext)
        )
    }
}

