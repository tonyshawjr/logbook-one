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
    
    var body: some View {
        ZStack {
            TabView {
                NavigationStack {
                    DashboardView()
                }
                .tabItem {
                    Label("Today", systemImage: "house")
                }
                
                NavigationStack {
                    TasksView()
                }
                .tabItem {
                    Label("Tasks", systemImage: "checkmark.circle")
                }
                
                NavigationStack {
                    ClientListView()
                }
                .tabItem {
                    Label("Clients", systemImage: "person.3")
                }
                
                NavigationStack {
                    PaymentsView()
                }
                .tabItem {
                    Label("Payments", systemImage: "dollarsign.circle")
                }
                
                NavigationStack {
                    ExportView()
                }
                .tabItem {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
            }
            .tint(Color.appAccent)
            
            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingQuickAdd = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.appAccent)
                            .clipShape(Circle())
                            .shadow(color: Color.appAccent.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 80) // Position above tab bar
                }
            }
        }
        .sheet(isPresented: $showingQuickAdd) {
            QuickAddView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
