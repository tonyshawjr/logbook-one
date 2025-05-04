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
            .tint(Color.themeAccent)
            .environment(\.managedObjectContext, viewContext)
            .onChange(of: selectedTab) { oldValue, newValue in
                print("Tab changed from \(oldValue) to \(newValue)")
            }
            
            // Use the QuickActionButton component
            if selectedTab != 1 { // Hide when on Tasks tab
                QuickActionButton(showingSheet: $showingQuickAdd, currentTab: selectedTab)
            }
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
            .presentationDragIndicator(.hidden)
            .presentationDetents([.height(420)])
            .presentationBackground(Color(uiColor: .systemBackground))
            .presentationCornerRadius(24)
            .interactiveDismissDisabled(false)
            .environment(\.managedObjectContext, viewContext)
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
