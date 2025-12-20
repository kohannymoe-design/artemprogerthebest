import SwiftUI
import PDFKit
import UIKit
import CoreData
import UniformTypeIdentifiers

struct ExportView: View {
    var viewModel: ConversationViewModel
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var showingPDFShare = false
    @State private var pdfURL: URL?
    @State private var shareItems: [Any] = []
    
    var years: [Int] {
        let years = Set(viewModel.conversations.compactMap { conversation in
            Calendar.current.component(.year, from: conversation.conversationDate ?? Date())
        })
        return Array(years).sorted(by: >)
    }
    
    var conversationsForYear: [NSManagedObject] {
        viewModel.conversations.filter { conversation in
            Calendar.current.component(.year, from: conversation.conversationDate ?? Date()) == selectedYear
        }
        .sorted { ($0.conversationDate ?? Date()) < ($1.conversationDate ?? Date()) }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Export Year") {
                    Picker("Year", selection: $selectedYear) {
                        ForEach(years, id: \.self) { year in
                            Text("\(year)").tag(year)
                        }
                    }
                    
                    Button(action: {
                        exportYearToPDF()
                    }) {
                        HStack {
                            Image(systemName: "doc.fill")
                            Text("Export \(selectedYear) to PDF")
                        }
                        .foregroundColor(AppColors.trustBlue)
                    }
                }
                
                Section("Export Single Conversation") {
                    if conversationsForYear.isEmpty {
                        Text("No conversations for selected year")
                            .foregroundColor(AppColors.textSecondary)
                    } else {
                        ForEach(conversationsForYear, id: \.objectID) { conversation in
                            NavigationLink(destination: ConversationExportCardView(conversation: conversation)) {
                                HStack {
                                    Text(conversation.conversationTitle ?? "Untitled")
                                    Spacer()
                                    if let date = conversation.conversationDate {
                                        Text(date, style: .date)
                                            .font(.system(size: 12))
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Section("Data Management") {
                    Button(action: {
                        exportDataToJSON()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export All Data (JSON)")
                        }
                        .foregroundColor(AppColors.trustBlue)
                    }
                    
                    Button(action: {
                        importDataFromJSON()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Import Data (JSON)")
                        }
                        .foregroundColor(AppColors.trustBlue)
                    }
                }
            }
            .navigationTitle("Export & Backup")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingPDFShare) {
                ShareSheet(items: shareItems)
            }
            .onAppear {
                viewModel.loadData()
            }
            .withErrorHandling(viewModel.errorHandler)
        }
    }
    
    private func exportYearToPDF() {
        guard !conversationsForYear.isEmpty else {
            viewModel.errorHandler.handle(AppError.exportError("No conversations to export for selected year"))
            return
        }
        
        // Create PDF
        let pdfCreator = PDFCreator(conversations: conversationsForYear, year: selectedYear)
        guard let url = pdfCreator.createPDF() else {
            viewModel.errorHandler.handle(AppError.exportError("Failed to create PDF"))
            return
        }
        
        // Verify file exists and has content
        guard FileManager.default.fileExists(atPath: url.path) else {
            viewModel.errorHandler.handle(AppError.exportError("PDF file was not created"))
            return
        }
        
        // Get file attributes to verify it's not empty
        if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
           let fileSize = attributes[.size] as? Int64,
           fileSize > 0 {
            // Set state and show sheet
            pdfURL = url
            shareItems = [url]
            showingPDFShare = true
        } else {
            viewModel.errorHandler.handle(AppError.exportError("PDF file is empty"))
        }
    }
    
    private func exportDataToJSON() {
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
                .appendingPathComponent("MoneyConversations_\(Date().timeIntervalSince1970).json")
            
            try jsonData.write(to: tempURL)
            
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(activityVC, animated: true)
            }
        } catch {
            print("Error exporting JSON: \(error)")
        }
    }
    
    private func importDataFromJSON() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.json])
        documentPicker.delegate = ImportDelegate(viewModel: viewModel)
        documentPicker.allowsMultipleSelection = false
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(documentPicker, animated: true)
        }
    }
}

struct ConversationExportCardView: View {
    let conversation: NSManagedObject
    @State private var showingShare = false
    @State private var shareImage: UIImage?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Card preview
                if let image = shareImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding()
                } else {
                    ConversationShareCard(conversation: conversation)
                        .padding()
                        .onAppear {
                            generateShareImage()
                        }
                }
                
                Button(action: {
                    if let image = shareImage {
                        shareImage(image)
                    }
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Card")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(AppColors.trustBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 20)
        }
        .background(AppColors.backgroundLight)
        .navigationTitle("Export Conversation")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingShare) {
            if let image = shareImage {
                ShareSheet(items: [image])
            }
        }
    }
    
    private func generateShareImage() {
        // Generate shareable card image
        let card = ConversationShareCard(conversation: conversation)
            .frame(width: 400, height: 600)
            .background(AppColors.cardBackground)
        
        let renderer = ImageRenderer(content: card)
        renderer.scale = 2.0
        shareImage = renderer.uiImage
    }
    
    private func shareImage(_ image: UIImage) {
        showingShare = true
    }
}

struct ConversationShareCard: View {
    let conversation: NSManagedObject
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Money Conversation")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
            
            Text(conversation.conversationTitle ?? "Untitled")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            
            if let date = conversation.conversationDate {
                Text(date.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Divider()
            
            if let goal = conversation.conversationGoal, !goal.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Goal")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                    Text(goal)
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.textPrimary)
                }
            }
            
            if let outcome = conversation.conversationOutcome, !outcome.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Outcome")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                    Text(outcome)
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.textPrimary)
                }
            }
            
            HStack {
                Text("Emotional Rating:")
                    .font(.system(size: 14, weight: .medium))
                Text("\(Int(conversation.conversationEmotionalRating))/10")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.trustBlue)
            }
            
            Spacer()
            
            Text("Money Conversation Manager")
                .font(.system(size: 12))
                .foregroundColor(AppColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(30)
        .background(AppColors.cardBackground)
        .cornerRadius(24)
    }
}

struct PDFCreator {
    let conversations: [NSManagedObject]
    let year: Int
    
    func createPDF() -> URL? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Money Conversation Manager",
            kCGPDFContextAuthor: "User",
            kCGPDFContextTitle: "My Money Conversations \(year)"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = 72
            let margin: CGFloat = 72
            let contentWidth = pageWidth - (margin * 2)
            
            // Title
            let title = "My Money Conversations \(year)"
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.label
            ]
            let titleSize = title.size(withAttributes: titleAttributes)
            title.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttributes)
            yPosition += titleSize.height + 30
            
            // Conversations
            for (index, conversation) in conversations.enumerated() {
                // Check if we need a new page
                if yPosition > pageHeight - 300 {
                    context.beginPage()
                    yPosition = 72
                }
                
                let conversationText = formatConversation(conversation)
                let textRect = CGRect(x: margin, y: yPosition, width: contentWidth, height: pageHeight - yPosition - 40)
                
                let boundingRect = conversationText.boundingRect(
                    with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    context: nil
                )
                
                // Draw text
                conversationText.draw(in: textRect)
                yPosition += boundingRect.height + 40
                
                // Add separator line if not last
                if index < conversations.count - 1 {
                    let lineY = yPosition - 20
                    if lineY < pageHeight - 50 {
                        context.cgContext.setStrokeColor(UIColor.separator.cgColor)
                        context.cgContext.setLineWidth(0.5)
                        context.cgContext.move(to: CGPoint(x: margin, y: lineY))
                        context.cgContext.addLine(to: CGPoint(x: pageWidth - margin, y: lineY))
                        context.cgContext.strokePath()
                        yPosition += 10
                    }
                }
            }
        }
        
        let fileName = "MoneyConversations_\(year)_\(Date().timeIntervalSince1970).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: tempURL)
            print("PDF created successfully at: \(tempURL.path)")
            print("File exists: \(FileManager.default.fileExists(atPath: tempURL.path))")
            print("File size: \(data.count) bytes")
            return tempURL
        } catch {
            print("Error creating PDF: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func formatConversation(_ conversation: NSManagedObject) -> NSAttributedString {
        let text = NSMutableAttributedString()
        
        if let title = conversation.conversationTitle {
            let titleAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .bold),
                .foregroundColor: UIColor.label
            ]
            text.append(NSAttributedString(string: "\(title)\n", attributes: titleAttr))
        }
        
        if let date = conversation.conversationDate {
            let dateAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.secondaryLabel
            ]
            text.append(NSAttributedString(string: "\(date.formatted(date: .abbreviated, time: .shortened))\n\n", attributes: dateAttr))
        }
        
        if let goal = conversation.conversationGoal, !goal.isEmpty {
            text.append(NSAttributedString(string: "Goal: \(goal)\n", attributes: defaultAttributes()))
        }
        
        if let outcome = conversation.conversationOutcome, !outcome.isEmpty {
            text.append(NSAttributedString(string: "Outcome: \(outcome)\n", attributes: defaultAttributes()))
        }
        
        text.append(NSAttributedString(string: "Emotional Rating: \(Int(conversation.conversationEmotionalRating))/10\n\n", attributes: defaultAttributes()))
        
        return text
    }
    
    private func defaultAttributes() -> [NSAttributedString.Key: Any] {
        [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.label
        ]
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // For iPad
        if let popover = controller.popoverPresentationController {
            popover.sourceView = UIView()
            popover.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        controller.completionWithItemsHandler = { _, _, _, _ in
            dismiss()
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Export/Import Data Models
struct ExportData: Codable {
    let conversations: [ConversationExport]
    let contacts: [ContactExport]
    let categories: [CategoryExport]
    let templatePhrases: [TemplatePhraseExport]
    let exportDate: Date
    let version: String
    
    init(conversations: [NSManagedObject], contacts: [NSManagedObject], categories: [NSManagedObject], templatePhrases: [NSManagedObject]) {
        self.conversations = conversations.map { ConversationExport(from: $0) }
        self.contacts = contacts.map { ContactExport(from: $0) }
        self.categories = categories.map { CategoryExport(from: $0) }
        self.templatePhrases = templatePhrases.map { TemplatePhraseExport(from: $0) }
        self.exportDate = Date()
        self.version = "1.0"
    }
}

struct ConversationExport: Codable {
    let id: UUID
    let title: String
    let date: Date
    let goal: String?
    let outcome: String?
    let emotionalRating: Int16
    let notes: String?
    let isResolved: Bool
    let contactIds: [UUID]
    let categoryId: UUID?
    
    init(from object: NSManagedObject) {
        self.id = object.conversationId ?? UUID()
        self.title = object.conversationTitle ?? ""
        self.date = object.conversationDate ?? Date()
        self.goal = object.conversationGoal
        self.outcome = object.conversationOutcome
        self.emotionalRating = object.conversationEmotionalRating
        self.notes = object.conversationNotes
        self.isResolved = object.conversationIsResolved
        
        if let contacts = object.conversationContacts as? NSSet {
            self.contactIds = contacts.compactMap { ($0 as? NSManagedObject)?.contactId }
        } else {
            self.contactIds = []
        }
        
        self.categoryId = object.conversationCategory?.categoryId
    }
}

struct ContactExport: Codable {
    let id: UUID
    let name: String
    let relationshipTag: String?
    let photoData: Data?
    
    init(from object: NSManagedObject) {
        self.id = object.contactId ?? UUID()
        self.name = object.contactName ?? ""
        self.relationshipTag = object.contactRelationshipTag
        self.photoData = object.contactPhotoData
    }
}

struct CategoryExport: Codable {
    let id: UUID
    let name: String
    let iconName: String?
    let accentColor: String?
    
    init(from object: NSManagedObject) {
        self.id = object.categoryId ?? UUID()
        self.name = object.categoryName ?? ""
        self.iconName = object.categoryIconName
        self.accentColor = object.categoryAccentColor
    }
}

struct TemplatePhraseExport: Codable {
    let id: UUID
    let text: String
    let categoryId: UUID?
    
    init(from object: NSManagedObject) {
        self.id = object.templatePhraseId ?? UUID()
        self.text = object.templatePhraseText ?? ""
        self.categoryId = object.templatePhraseCategory?.categoryId
    }
}

// MARK: - Import Delegate
class ImportDelegate: NSObject, UIDocumentPickerDelegate {
    let viewModel: ConversationViewModel
    
    init(viewModel: ConversationViewModel) {
        self.viewModel = viewModel
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        
        do {
            let jsonData = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let exportData = try decoder.decode(ExportData.self, from: jsonData)
            
            // Import data
            DispatchQueue.main.async {
                self.importData(exportData)
            }
        } catch {
            print("Error importing JSON: \(error)")
        }
    }
    
    private func importData(_ data: ExportData) {
        // Create mapping dictionaries
        var contactIdMap: [UUID: NSManagedObject] = [:]
        var categoryIdMap: [UUID: NSManagedObject] = [:]
        
        // Import contacts
        for contactExport in data.contacts {
            if let contact = viewModel.createContact(
                name: contactExport.name,
                relationshipTag: contactExport.relationshipTag,
                photoData: contactExport.photoData
            ) {
                contactIdMap[contactExport.id] = contact
            }
        }
        
        // Import categories
        for categoryExport in data.categories {
            if let category = viewModel.createCategory(
                name: categoryExport.name,
                iconName: categoryExport.iconName ?? "folder",
                accentColor: categoryExport.accentColor ?? "4A7C9B"
            ) {
                categoryIdMap[categoryExport.id] = category
            }
        }
        
        // Import template phrases
        for phraseExport in data.templatePhrases {
            let category = phraseExport.categoryId.flatMap { categoryIdMap[$0] }
            _ = viewModel.createTemplatePhrase(text: phraseExport.text, category: category)
        }
        
        // Import conversations
        for conversationExport in data.conversations {
            let contacts = Set(conversationExport.contactIds.compactMap { contactIdMap[$0] })
            let category = conversationExport.categoryId.flatMap { categoryIdMap[$0] }
            
            viewModel.createConversation(
                title: conversationExport.title,
                contacts: contacts,
                date: conversationExport.date,
                category: category,
                goal: conversationExport.goal ?? "",
                outcome: conversationExport.outcome ?? "",
                emotionalRating: conversationExport.emotionalRating,
                notes: conversationExport.notes
            )
        }
        
        viewModel.loadData()
    }
}

#Preview {
    ExportView(viewModel: ConversationViewModel(context: CoreDataStack.shared.viewContext))
}

