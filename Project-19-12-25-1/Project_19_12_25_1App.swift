import SwiftUI
import CoreData
import Combine

@main
struct Project_19_12_25_1App: App {
    @StateObject private var themeManager = ThemeManager()
    
    @State private var showSplash = true
    @State private var showError = false
    
    @State private var targetUrlString: String?
    @State private var configState: ConfigRetrievalState = .pending
    @State private var currentViewState: ApplicationViewState = .initialScreen
    
    var body: some Scene {
        WindowGroup {
            
            ZStack {
                switch currentViewState {
                case .initialScreen:
                    SplashScreenView()
                        .transition(.opacity)
                    
                case .primaryInterface:
                    MainTabView(themeManager: themeManager)
                        .preferredColorScheme(themeManager.currentTheme.colorScheme)
                    
                case .browserContent(let urlString):
                    if let validUrl = URL(string: urlString) {
                        BrowserContentView(targetUrl: validUrl.absoluteString)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black)
                            .ignoresSafeArea(.all, edges: .bottom)
                    } else {
                        Text("Invalid URL")
                    }
                    
                case .failureMessage(let errorMessage):
                    VStack(spacing: 20) {
                        Text("Error")
                            .font(.title)
                            .foregroundColor(.red)
                        Text(errorMessage)
                        Button("Retry") {
                            Task { await fetchConfigurationAndNavigate() }
                        }
                    }
                    .padding()
                }
            }
            .task {
                await fetchConfigurationAndNavigate()
            }
            .onChange(of: configState, initial: true) { oldValue, newValue in
                if case .completed = newValue, let url = targetUrlString, !url.isEmpty {
                    Task {
                        await verifyUrlAndNavigate(targetUrl: url)
                    }
                }
            }
            
//            ZStack {
//                if showSplash {
//                    SplashScreenView()
//                        .transition(.opacity)
//                } else {
//                    MainTabView(themeManager: themeManager)
//                        .preferredColorScheme(themeManager.currentTheme.colorScheme)
//                }
//            }
//            .onAppear {
//                DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.Defaults.splashScreenDuration) {
//                    withAnimation {
//                        showSplash = false
//                    }
//                }
//            }
        }
    }
    
    private func fetchConfigurationAndNavigate() async {
        await MainActor.run { currentViewState = .initialScreen }
        
        let (url, state) = await DynamicConfigService.instance.retrieveTargetUrl()
        
        await MainActor.run {
            self.targetUrlString = url
            self.configState = state
        }
        
        if url == nil || url?.isEmpty == true {
            navigateToPrimaryInterface()
        }
    }
    
    private func navigateToPrimaryInterface() {
        withAnimation {
            currentViewState = .primaryInterface
        }
    }
    
    private func verifyUrlAndNavigate(targetUrl: String) async {
        guard let url = URL(string: targetUrl) else {
            navigateToPrimaryInterface()
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "HEAD"
        urlRequest.timeoutInterval = 10
        
        do {
            let (_, httpResponse) = try await URLSession.shared.data(for: urlRequest)
            
            if let response = httpResponse as? HTTPURLResponse,
               (200...299).contains(response.statusCode) {
                await MainActor.run {
                    currentViewState = .browserContent(targetUrl)
                }
            } else {
                navigateToPrimaryInterface()
            }
        } catch {
            navigateToPrimaryInterface()
        }
    }
}

struct MainTabView: View {
    @ObservedObject var themeManager: ThemeManager
    @State private var viewModel = ConversationViewModel(context: CoreDataStack.shared.viewContext)
    
    var body: some View {
        TabView {
            MainDashboardView(viewModel: viewModel)
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
            
            TimelineView(viewModel: viewModel)
                .tabItem {
                    Label("Timeline", systemImage: "clock.fill")
                }
            
            CalendarView(viewModel: viewModel)
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
            
            PreparationHelperView(viewModel: viewModel)
                .tabItem {
                    Label("Prepare", systemImage: "lightbulb.fill")
                }
            
            InsightsView(viewModel: viewModel)
                .tabItem {
                    Label("Insights", systemImage: "chart.bar.fill")
                }
            
            ContactManagerView(viewModel: viewModel)
                .tabItem {
                    Label("Contacts", systemImage: "person.2.fill")
                }
            
            CategoryManagerView(viewModel: viewModel)
                .tabItem {
                    Label("Categories", systemImage: "folder.fill")
                }
            
            ExportView(viewModel: viewModel)
                .tabItem {
                    Label("Export", systemImage: "square.and.arrow.up.fill")
                }
            
            SettingsView(viewModel: viewModel)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
        .onAppear {
            viewModel.loadData()
        }
    }
}
