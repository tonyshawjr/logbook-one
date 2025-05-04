//
//  ContentView.swift
//  LogbookOne
//
//  Created by Tony Shaw on 5/3/25.
//

import SwiftUI
import CoreData

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
        .onAppear {
            // Set app appearance to match Mogul style
            configureAppAppearance()
        }
    }
    
    private func configureAppAppearance() {
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        tabBarAppearance.backgroundColor = UIColor(Color.cardBackground)
        tabBarAppearance.shadowColor = UIColor.clear
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Configure navigation bar appearance
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithDefaultBackground()
        navigationBarAppearance.backgroundColor = UIColor(Color.appBackground)
        navigationBarAppearance.shadowColor = UIColor.clear
        
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
    }
}

struct MainTabView: View {
    @State private var showingQuickAdd = false
    @State private var selectedTab = 0
    
    // Environment to pass to the various views
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    DashboardView()
                }
                .tabItem {
                    Label("Today", systemImage: "house")
                }
                .tag(0)
                
                NavigationStack {
                    TasksView()
                }
                .tabItem {
                    Label("Tasks", systemImage: "checkmark.circle")
                }
                .tag(1)
                
                NavigationStack {
                    NotesView()
                }
                .tabItem {
                    Label("Notes", systemImage: "doc.text")
                }
                .tag(2)
                
                NavigationStack {
                    PaymentsView()
                }
                .tabItem {
                    Label("Payments", systemImage: "dollarsign.circle")
                }
                .tag(3)
                
                NavigationStack {
                    ClientListView()
                }
                .tabItem {
                    Label("Clients", systemImage: "person.3")
                }
                .tag(4)
            }
            .tint(Color.appAccent)
            .environment(\.managedObjectContext, viewContext)
            .onChange(of: selectedTab) { oldValue, newValue in
                print("Tab changed from \(oldValue) to \(newValue)")
            }
            
            // Use the QuickActionButton component
            QuickActionButton(showingSheet: $showingQuickAdd, currentTab: selectedTab)
        }
        .sheet(isPresented: $showingQuickAdd) {
            Group {
                switch selectedTab {
                case 0: // Dashboard - show general quick add
                    QuickAddView()
                case 1: // Tasks
                    QuickAddView(initialEntryType: .task)
                case 2: // Notes
                    QuickAddView(initialEntryType: .note)
                case 3: // Payments
                    QuickAddView(initialEntryType: .payment)
                case 4: // Clients
                    ClientFormView()
                default:
                    Text("Nothing to add on this screen")
                }
            }
            .presentationDragIndicator(.visible)
            .presentationDetents([.medium])
            .environment(\.managedObjectContext, viewContext)
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
