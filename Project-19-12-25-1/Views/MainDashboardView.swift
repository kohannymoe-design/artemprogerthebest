import SwiftUI
import CoreData

struct MainDashboardView: View {
    var viewModel: ConversationViewModel
    @State private var showingAddConversation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Statistics header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(viewModel.conversationsCount()) money conversations logged")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                    }
                    
                    // Summary cards
                    HStack(spacing: 16) {
                        SummaryCard(
                            title: "Total",
                            value: "\(viewModel.conversationsCount())",
                            subtitle: "conversations",
                            color: AppColors.trustBlue,
                            icon: "bubble.left.and.bubble.right"
                        )
                        SummaryCard(
                            title: "Average",
                            value: String(format: "%.1f", viewModel.averageEmotionalRating()),
                            subtitle: "rating",
                            color: AppColors.calmGreen,
                            icon: "star.fill"
                        )
                        SummaryCard(
                            title: "Resolved",
                            value: "\(resolvedCount)",
                            subtitle: "completed",
                            color: AppColors.softBeige,
                            icon: "checkmark.circle.fill"
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Recent conversations
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Conversations")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.horizontal, 20)
                        
                    if viewModel.conversations.isEmpty {
                        EmptyStateView(
                            title: "No conversations yet",
                            message: "Tap the + button to add your first conversation",
                            icon: "bubble.left.and.bubble.right"
                        )
                        .padding(.horizontal, 20)
                    } else {
                        ForEach(Array(viewModel.conversations.prefix(10)), id: \.objectID) { conversation in
                            NavigationLink(destination: ConversationDetailView(conversation: conversation, viewModel: viewModel)) {
                                ConversationCard(conversation: conversation)
                                    .padding(.horizontal, 20)
                            }
                        }
                    }
                    }
                    .padding(.top, 8)
                }
                .padding(.bottom, 100)
            }
            .background(AppColors.backgroundLight)
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .overlay(alignment: .bottomTrailing) {
                Button(action: {
                    showingAddConversation = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 64, height: 64)
                        .background(AppColors.trustBlue)
                        .clipShape(Circle())
                        .shadow(color: AppColors.shadowColorStrong, radius: 8, x: 0, y: 4)
                }
                .padding(24)
            }
            .sheet(isPresented: $showingAddConversation) {
                ConversationFormView(viewModel: viewModel, conversation: nil)
            }
            .onAppear {
                viewModel.loadData()
            }
            .withErrorHandling(viewModel.errorHandler)
        }
    }
    
    private var resolvedCount: Int {
        viewModel.conversations.filter { $0.conversationIsResolved }.count
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(AppColors.textSecondary.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColors.cardBackground)
                .shadow(color: AppColors.shadowColor, radius: 8, x: 0, y: 2)
        )
    }
}

struct ConversationCard: View {
    let conversation: NSManagedObject
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(conversation.conversationTitle ?? "Untitled")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                
                if let date = conversation.conversationDate {
                    Text(date, style: .date)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            Spacer()
            
            outcomeEmoji(for: conversation)
                .font(.system(size: 32))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppColors.cardBackground)
                .shadow(color: AppColors.shadowColor, radius: 8, x: 0, y: 2)
        )
    }
    
    private func outcomeEmoji(for conversation: NSManagedObject) -> Text {
        let rating = Int(conversation.conversationEmotionalRating)
        if rating >= 8 {
            return Text("😊")
        } else if rating >= 5 {
            return Text("😐")
        } else {
            return Text("😔")
        }
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let icon: String
    
    init(title: String = "No data", message: String = "Add your first item", icon: String = "folder") {
        self.title = title
        self.message = message
        self.icon = icon
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(AppColors.textSecondary.opacity(0.5))
            Text(title)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    MainDashboardView(viewModel: ConversationViewModel(context: CoreDataStack.shared.viewContext))
}

