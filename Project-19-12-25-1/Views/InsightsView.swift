import SwiftUI
import Charts
import UIKit
import CoreData

struct InsightsView: View {
    var viewModel: ConversationViewModel
    
    var conversationsPerMonth: [(month: String, count: Int)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: viewModel.conversations) { conversation in
            let date = conversation.conversationDate ?? Date()
            return calendar.dateInterval(of: .month, for: date)?.start ?? date
        }
        
        return grouped.map { (date, conversations) in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            return (month: formatter.string(from: date), count: conversations.count)
        }
        .sorted { $0.month < $1.month }
    }
    
    var emotionalTrend: [(date: Date, rating: Double)] {
        viewModel.conversations
            .sorted { ($0.conversationDate ?? Date()) < ($1.conversationDate ?? Date()) }
            .map { (date: $0.conversationDate ?? Date(), rating: Double($0.conversationEmotionalRating)) }
    }
    
    var successRate: Double {
        let successful = viewModel.conversations.filter { Int($0.conversationEmotionalRating) >= 8 }.count
        guard !viewModel.conversations.isEmpty else { return 0 }
        return Double(successful) / Double(viewModel.conversations.count) * 100
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Summary stats
                    HStack(spacing: 16) {
                        StatCard(
                            title: "Total",
                            value: "\(viewModel.conversationsCount())",
                            icon: "bubble.left.and.bubble.right",
                            color: AppColors.trustBlue
                        )
                        StatCard(
                            title: "Success Rate",
                            value: "\(Int(successRate))%",
                            icon: "chart.line.uptrend.xyaxis",
                            color: AppColors.calmGreen
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Most discussed
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Most Discussed")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.horizontal, 20)
                        
                        HStack(spacing: 16) {
                            if let contact = viewModel.mostDiscussedContact() {
                                InsightCard(
                                    title: "Person",
                                    value: contact.contactName ?? "Unknown",
                                    icon: "person.fill",
                                    color: AppColors.trustBlue
                                )
                            }
                            
                            if let category = viewModel.mostDiscussedCategory() {
                                InsightCard(
                                    title: "Topic",
                                    value: category.categoryName ?? "Unknown",
                                    icon: category.categoryIconName ?? "folder",
                                    color: Color(hex: category.categoryAccentColor ?? "4A7C9B")
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Conversations per month chart
                    if !conversationsPerMonth.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Conversations per Month")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.horizontal, 20)
                            
                            Chart {
                                ForEach(Array(conversationsPerMonth.enumerated()), id: \.offset) { index, data in
                                    // Using offset here is OK as it's for chart data, not Core Data objects
                                    BarMark(
                                        x: .value("Month", data.month),
                                        y: .value("Count", data.count)
                                    )
                                    .foregroundStyle(AppColors.trustBlue)
                                    .cornerRadius(8)
                                }
                            }
                            .frame(height: 200)
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(AppColors.cardBackground)
                                    .shadow(color: AppColors.shadowColor, radius: 8, x: 0, y: 2)
                            )
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // Emotional trend
                    if !emotionalTrend.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Emotional Trend")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.horizontal, 20)
                            
                            Chart {
                                ForEach(Array(emotionalTrend.enumerated()), id: \.offset) { index, data in
                                    // Using offset here is OK as it's for chart data, not Core Data objects
                                    LineMark(
                                        x: .value("Date", data.date, unit: .day),
                                        y: .value("Rating", data.rating)
                                    )
                                    .foregroundStyle(AppColors.calmGreen)
                                    .interpolationMethod(.catmullRom)
                                    
                                    AreaMark(
                                        x: .value("Date", data.date, unit: .day),
                                        y: .value("Rating", data.rating)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [AppColors.calmGreen.opacity(0.3), AppColors.calmGreen.opacity(0.0)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .interpolationMethod(.catmullRom)
                                }
                            }
                            .frame(height: 200)
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(AppColors.cardBackground)
                                    .shadow(color: AppColors.shadowColor, radius: 8, x: 0, y: 2)
                            )
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // Average rating
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Average Emotional Rating")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.horizontal, 20)
                        
                        HStack {
                            Text("\(String(format: "%.1f", viewModel.averageEmotionalRating()))")
                                .font(.system(size: 48, weight: .medium))
                                .foregroundColor(AppColors.trustBlue)
                            Text("/ 10")
                                .font(.system(size: 24))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(40)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(AppColors.cardBackground)
                                .shadow(color: AppColors.shadowColor, radius: 8, x: 0, y: 2)
                        )
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 20)
            }
            .background(AppColors.backgroundLight)
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.loadData()
            }
            .withErrorHandling(viewModel.errorHandler)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
            
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppColors.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

struct InsightCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
            
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                Text(value)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColors.cardBackground)
                .shadow(color: AppColors.shadowColorLight, radius: 4, x: 0, y: 2)
        )
    }
}

#Preview {
    InsightsView(viewModel: ConversationViewModel(context: CoreDataStack.shared.viewContext))
}

