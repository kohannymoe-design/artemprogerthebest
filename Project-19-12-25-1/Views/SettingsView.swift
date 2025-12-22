import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @StateObject private var themeManager = ThemeManager()
    var viewModel: ConversationViewModel
    @State private var showingResetAlert = false
    @AppStorage("currencyDisplay") private var currencyDisplay: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Theme", selection: $themeManager.selectedTheme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.rawValue.capitalized).tag(theme)
                        }
                    }
                }
                
                Section("Preferences") {
                    TextField("Currency (optional)", text: $currencyDisplay)
                        .keyboardType(.default)
                }
                
                Section("Data") {
                    Button(action: {
                        exportBackup()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export Backup")
                        }
                        .foregroundColor(AppColors.trustBlue)
                    }
                    
                    Button(action: {
                        importBackup()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Import Backup")
                        }
                        .foregroundColor(AppColors.trustBlue)
                    }
                }
                
                Section("Danger Zone") {
                    Button(role: .destructive, action: {
                        showingResetAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Reset All Data")
                        }
                    }
                }
                
                Section {
                    VStack(spacing: 8) {
                        Text("Money Conversation Manager")
                            .font(.system(size: 16, weight: .medium))
                        Text("Version 1.0.0")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                        Text("A calm space for reflecting on money conversations")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Reset All Data", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("This will permanently delete all your conversations, contacts, and categories. This action cannot be undone.")
            }
        }
    }
    
    private func exportBackup() {
        do {
            let exportData = ExportData(
                conversations: viewModel.conversations,
                contacts: viewModel.contacts,
                categories: viewModel.categories,
                templatePhrases: viewModel.templatePhrases
            )
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            
            let jsonData = try encoder.encode(exportData)
            
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("MoneyConversations_Backup_\(Date().timeIntervalSince1970).json")
            
            try jsonData.write(to: tempURL)
            
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(activityVC, animated: true)
            }
        } catch {
            print("Error exporting backup: \(error)")
        }
    }
    
    private func importBackup() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.json])
        documentPicker.delegate = ImportDelegate(viewModel: viewModel)
        documentPicker.allowsMultipleSelection = false
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(documentPicker, animated: true)
        }
    }
    
    private func resetAllData() {
        // Delete all Core Data entities
        for conversation in viewModel.conversations {
            CoreDataStack.shared.delete(conversation)
        }
        for contact in viewModel.contacts {
            CoreDataStack.shared.delete(contact)
        }
        for category in viewModel.categories {
            CoreDataStack.shared.delete(category)
        }
        for phrase in viewModel.templatePhrases {
            CoreDataStack.shared.delete(phrase)
        }
        viewModel.loadData()
    }
}

#Preview {
    SettingsView(viewModel: ConversationViewModel(context: CoreDataStack.shared.viewContext))
}

