import SwiftUI
import CoreData

@main
struct Project_19_12_25_1App: App {
    @StateObject private var themeManager = ThemeManager()
    @State private var showSplash = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashScreenView()
                        .transition(.opacity)
                } else {
                    MainTabView(themeManager: themeManager)
                        .preferredColorScheme(themeManager.currentTheme.colorScheme)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.Defaults.splashScreenDuration) {
                    withAnimation {
                        showSplash = false
                    }
                }
            }
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
