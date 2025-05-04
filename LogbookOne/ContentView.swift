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
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Tab view
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
                    MoreView()
                }
                .tabItem {
                    Label("More", systemImage: "ellipsis")
                }
                .tag(4)
            }
            .tint(Color.themeAccent)
            .environment(\.managedObjectContext, viewContext)
            .onAppear {
                // Reset any unwanted tab bar appearance settings
                let appearance = UITabBarAppearance()
                appearance.configureWithDefaultBackground()
                UITabBar.appearance().standardAppearance = appearance
                UITabBar.appearance().scrollEdgeAppearance = appearance
                UITabBar.appearance().backgroundColor = nil
                UITabBar.appearance().isTranslucent = true
            }
            
            // Quick add button as a floating layer
            if selectedTab != 1 && selectedTab != 4 { // Hide when on Tasks or More tab
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            // Use haptic feedback when pressing button
                            let impactMed = UIImpactFeedbackGenerator(style: .medium)
                            impactMed.impactOccurred()
                            
                            showingQuickAdd = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(
                                    Circle()
                                        .fill(Color.themeAccent)
                                        .shadow(color: Color.themeAccent.opacity(0.3), radius: 5, x: 0, y: 3)
                                )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.trailing, 20)
                        .padding(.bottom, 80) // Position above tab bar
                    }
                }
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
                case 4: // More tab - show client form
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
