import SwiftUI
import CoreData

struct CategoryManagerView: View {
    var viewModel: ConversationViewModel
    @State private var showingAddCategory = false
    @State private var searchText = ""
    
    var filteredCategories: [NSManagedObject] {
        if searchText.isEmpty {
            return viewModel.categories
        }
        return viewModel.categories.filter { category in
            (category.categoryName ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredCategories, id: \.objectID) { category in
                    CategoryListRow(category: category, viewModel: viewModel)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.deleteCategory(filteredCategories[index])
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search categories")
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showingAddCategory = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                AddCategoryView(viewModel: viewModel)
            }
            .onAppear {
                viewModel.loadData()
            }
            .withErrorHandling(viewModel.errorHandler)
        }
    }
}

struct CategoryListRow: View {
    let category: NSManagedObject
    let viewModel: ConversationViewModel
    
    var conversationCount: Int {
        viewModel.conversationsInCategory(category).count
    }
    
    var accentColor: Color {
        if let colorHex = category.categoryAccentColor {
            return Color(hex: colorHex)
        }
        return AppColors.trustBlue
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: category.categoryIconName ?? "folder")
                    .font(.system(size: 24))
                    .foregroundColor(accentColor)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(category.categoryName ?? "Unknown")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                
                        Text(conversationCount == 0 ? "No conversations" : "\(conversationCount) conversation\(conversationCount == 1 ? "" : "s")")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct AddCategoryView: View {
    @Environment(\.dismiss) var dismiss
    var viewModel: ConversationViewModel
    @State private var name: String = ""
    @State private var iconName: String = "folder"
    @State private var accentColor: String = "4A7C9B"
    
    let iconOptions = AppConstants.availableIcons
    let colorOptions = AppConstants.availableColors
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Category Information") {
                    TextField("Name", text: $name)
                }
                
                Section("Icon") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(iconOptions, id: \.self) { icon in
                                Button(action: {
                                    iconName = icon
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(iconName == icon ? Color(hex: accentColor).opacity(0.3) : AppColors.mediumGray.opacity(0.2))
                                            .frame(width: 60, height: 60)
                                        
                                        Image(systemName: icon)
                                            .font(.system(size: 28))
                                            .foregroundColor(iconName == icon ? Color(hex: accentColor) : AppColors.textSecondary)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Section("Color") {
                    ForEach(colorOptions, id: \.0) { colorOption in
                        Button(action: {
                            accentColor = colorOption.1
                        }) {
                            HStack {
                                Circle()
                                    .fill(Color(hex: colorOption.1))
                                    .frame(width: 30, height: 30)
                                
                                Text(colorOption.0)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                Spacer()
                                
                                if accentColor == colorOption.1 {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(AppColors.trustBlue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveCategory()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveCategory() {
        viewModel.createCategory(name: name, iconName: iconName, accentColor: accentColor)
        dismiss()
    }
}

#Preview {
    CategoryManagerView(viewModel: ConversationViewModel(context: CoreDataStack.shared.viewContext))
}

