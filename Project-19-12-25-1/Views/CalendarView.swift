import SwiftUI
import CoreData

struct CalendarView: View {
    var viewModel: ConversationViewModel
    @State private var selectedDate: Date = Date()
    @State private var currentMonth: Date = Date()
    
    var conversationsOnSelectedDate: [NSManagedObject] {
        viewModel.conversationsOnDate(selectedDate)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Month selector
                    HStack {
                        Button(action: {
                            withAnimation {
                                currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(AppColors.trustBlue)
                                .font(.system(size: 18, weight: .semibold))
                        }
                        
                        Spacer()
                        
                        Text(currentMonth.formatted(.dateTime.month(.wide).year()))
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation {
                                currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(AppColors.trustBlue)
                                .font(.system(size: 18, weight: .semibold))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(AppColors.cardBackground)
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // Calendar grid
                    CalendarGridView(
                        month: currentMonth,
                        conversations: viewModel.conversations,
                        selectedDate: $selectedDate
                    )
                    .padding(20)
                    .background(AppColors.cardBackground)
                    .cornerRadius(20)
                    .shadow(color: AppColors.shadowColor, radius: 8, x: 0, y: 2)
                    .padding(.horizontal, 20)
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Conversations for selected date
                    VStack(alignment: .leading, spacing: 12) {
                        Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 22, weight: .medium))
                            .padding(.horizontal, 20)
                        
                        if conversationsOnSelectedDate.isEmpty {
                            Text("No conversations on this date")
                                .font(.system(size: 16))
                                .foregroundColor(AppColors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(40)
                        } else {
                            ScrollView {
                                VStack(spacing: 12) {
                                    ForEach(conversationsOnSelectedDate, id: \.objectID) { conversation in
                                        NavigationLink(destination: ConversationDetailView(conversation: conversation, viewModel: viewModel)) {
                                            ConversationCard(conversation: conversation)
                                                .padding(.horizontal, 20)
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
                .background(AppColors.background)
                .navigationTitle("Calendar")
                .navigationBarTitleDisplayMode(.large)
                .onAppear {
                    viewModel.loadData()
                }
                .withErrorHandling(viewModel.errorHandler)
            }
        }
    }
    
    struct CalendarGridView: View {
        let month: Date
        let conversations: [NSManagedObject]
        @Binding var selectedDate: Date
        
        private let calendar = Calendar.current
        private let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        
        var daysInMonth: [Date?] {
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
            let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
            let firstWeekday = calendar.component(.weekday, from: startOfMonth) - 1
            
            var days: [Date?] = Array(repeating: nil, count: firstWeekday)
            
            for day in range {
                if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                    days.append(date)
                }
            }
            
            return days
        }
        
        func hasConversation(on date: Date) -> Bool {
            conversations.contains { conversation in
                calendar.isDate(conversation.conversationDate ?? Date(), inSameDayAs: date)
            }
        }
        
        var body: some View {
            VStack(spacing: 12) {
                // Weekday headers
                HStack(spacing: 0) {
                    ForEach(weekdays, id: \.self) { weekday in
                        Text(weekday)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.bottom, 4)
                
                // Calendar days
                let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(Array(daysInMonth.enumerated()), id: \.offset) { index, date in
                        if let date = date {
                            CalendarDayView(
                                date: date,
                                isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                hasConversation: hasConversation(on: date)
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedDate = date
                                }
                            }
                        } else {
                            Color.clear
                                .frame(height: 40)
                        }
                    }
                }
            }
        }
    }
    
    struct CalendarDayView: View {
        let date: Date
        let isSelected: Bool
        let hasConversation: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(AppColors.trustBlue)
                    } else {
                        Circle()
                            .fill(Color.clear)
                            .overlay(
                                Circle()
                                    .stroke(AppColors.mediumGray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .white : AppColors.textPrimary)
                    
                    if hasConversation && !isSelected {
                        Circle()
                            .fill(AppColors.calmGreen)
                            .frame(width: 5, height: 5)
                            .offset(y: 15)
                    }
                }
                .frame(width: 40, height: 40)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}
