//
//  ContentView.swift
//  LogbookOne
//
//  Created by Tony Shaw on 5/3/25.
//

import SwiftUI
import CoreData

// Extension to check if the device has a home indicator (iPhone X and later)
extension UIDevice {
    var hasHomeIndicator: Bool {
        if #available(iOS 15.0, *) {
            // Use the recommended approach for iOS 15+
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) else {
                return false
            }
            return keyWindow.safeAreaInsets.bottom > 0
        } else {
            // Fallback for iOS versions before 15.0
            let windows = UIApplication.shared.windows
            let keyWindow = windows.first(where: { $0.isKeyWindow })
            return keyWindow?.safeAreaInsets.bottom ?? 0 > 0
        }
    }
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        ZStack {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
    }
}

struct MainTabView: View {
    @State private var showingQuickAdd = false
    @State private var selectedTab = 0
    
    // Environment to pass to the various views
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var clientFormState: ClientFormState
    
    // References to view state
    @State private var tasksViewShowingAdd = false
    
    var body: some View {
        ZStack {
            // Tab view as base layer
            TabView(selection: $selectedTab) {
                NavigationStack {
                    DashboardView()
                        .environment(\.managedObjectContext, viewContext)
                }
                .tabItem {
                    Label("Today", systemImage: "house")
                }
                .tag(0)
                
                NavigationStack {
                    TasksView()
                        .environment(\.managedObjectContext, viewContext)
                }
                .tabItem {
                    Label("Tasks", systemImage: "checkmark.circle")
                }
                .tag(1)
                
                NavigationStack {
                    NotesView()
                        .environment(\.managedObjectContext, viewContext)
                }
                .tabItem {
                    Label("Notes", systemImage: "doc.text")
                }
                .tag(2)
                
                NavigationStack {
                    PaymentsView()
                        .environment(\.managedObjectContext, viewContext)
                }
                .tabItem {
                    Label("Payments", systemImage: "dollarsign.circle")
                }
                .tag(3)
                
                NavigationStack {
                    ClientListView()
                        .environment(\.managedObjectContext, viewContext)
                        .environmentObject(clientFormState)
                }
                .tabItem {
                    Label("Clients", systemImage: "person.3")
                }
                .tag(4)
            }
            .tint(Color.themeAccent)
            .environment(\.managedObjectContext, viewContext)
            .environmentObject(clientFormState)
            .onChange(of: selectedTab) { oldValue, newValue in
                // Request layout update with a simple approach
                DispatchQueue.main.async {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
            .onAppear {
                // Let the specialized UITabBarAppearance from LogbookOneApp take precedence
                // Only adjust generic settings here
                UITabBar.appearance().backgroundColor = nil
                UITabBar.appearance().isTranslucent = true
            }
            
            // Separate floating button layer with better visibility control
            ZStack {
                // Only show on tabs 0-3 (Today, Tasks, Notes, Payments)
                // Tab 4 is now Clients
                if [0, 1, 2, 3].contains(selectedTab) {
                    VStack {
                        Spacer() // Push to bottom
                        HStack {
                            Spacer() // Push to right
                            QuickActionButton(showingSheet: $showingQuickAdd, currentTab: selectedTab)
                                .id(selectedTab) // Force recreation when tab changes
                        }
                        // Use more bottom padding and add extra for devices with home indicator
                        .padding(.bottom, UIDevice.current.hasHomeIndicator ? 100 : 85)
                    }
                }
            }
            .ignoresSafeArea(.all)
        }
        .sheet(isPresented: $showingQuickAdd) {
            Group {
                switch selectedTab {
                case 0: // Dashboard
                    QuickAddView()
                case 1: // Tasks
                    QuickAddView(initialEntryType: .task)
                case 2: // Notes
                    QuickAddView(initialEntryType: .note)
                case 3: // Payments
                    QuickAddView(initialEntryType: .payment)
                default:
                    // Fallback for any other tab (though this shouldn't happen)
                    QuickAddView()
                }
            }
            .presentationDragIndicator(.hidden)
            .presentationDetents([.height(420)])
            .presentationBackground(Color(uiColor: .systemBackground))
            .presentationCornerRadius(24)
            .interactiveDismissDisabled(false)
            .environment(\.managedObjectContext, viewContext)
        }
        // Global client form presentation
        .sheet(isPresented: $clientFormState.showingAddClient) {
            ClientFormView()
                .environment(\.managedObjectContext, viewContext)
                .presentationDragIndicator(.hidden)
                .presentationDetents([.height(420)])
                .presentationBackground(Color(uiColor: .systemBackground))
                .presentationCornerRadius(24)
                .interactiveDismissDisabled(false)
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
