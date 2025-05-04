import SwiftUI
import UIKit

struct MoreView: View {
    @State private var showingClients = false
    @State private var showingSettings = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Menu items - removed redundant section title
                VStack(spacing: 0) {
                    // Clients button
                    Button(action: {
                        showingClients = true
                    }) {
                        MoreMenuItemView(
                            icon: "person.3.fill",
                            iconColor: .blue,
                            title: "Clients"
                        )
                    }
                    
                    Divider()
                        .padding(.leading, 64)
                    
                    // Settings button
                    Button(action: {
                        showingSettings = true
                    }) {
                        MoreMenuItemView(
                            icon: "gear",
                            iconColor: .gray,
                            title: "Settings"
                        )
                    }
                }
                .background(Color.themeCard)
                .cornerRadius(16)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color.themeBackground.ignoresSafeArea())
        .navigationTitle("More")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.themeBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .fullScreenCover(isPresented: $showingClients) {
            ZStack {
                NavigationStack {
                    ClientDetailedView()
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showingClients = false
                                }
                            }
                        }
                }
            }
        }
        .fullScreenCover(isPresented: $showingSettings) {
            CustomSettingsView()
        }
    }
}

// A custom container for Settings to create a custom navigation bar
struct CustomSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background color
            Color.themeBackground.ignoresSafeArea()
            
            // Content
            VStack(spacing: 0) {
                // Custom navigation bar with no separator
                HStack {
                    // Large headline "Settings" text
                    Text("Settings")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Done button
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.green)
                    .font(.headline)
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 16)
                .background(Color.themeBackground)
                
                // Main content
                SettingsView()
                    .background(Color.themeBackground)
            }
        }
    }
}

struct MoreMenuItemView: View {
    let icon: String
    let iconColor: Color
    let title: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            // Title
            Text(title)
                .font(.appHeadline)
                .foregroundColor(.themePrimary)
            
            Spacer()
            
            // Arrow
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.themeSecondary.opacity(0.5))
        }
        .padding(.vertical, 16)
        .padding(.horizontal)
        .contentShape(Rectangle())
    }
}

// Self-contained Clients view that includes its own add button functionality
struct ClientDetailedView: View {
    @State private var showingAddClient = false
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        ZStack {
            // Main content
            ClientListView()
            
            // Add the floating action button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        // Use haptic feedback when pressing button
                        let impactMed = UIImpactFeedbackGenerator(style: .medium)
                        impactMed.impactOccurred()
                        
                        showingAddClient = true
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
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .sheet(isPresented: $showingAddClient) {
            ClientFormView()
                .environment(\.managedObjectContext, viewContext)
                .presentationDragIndicator(.hidden)
                .presentationDetents([.height(420)])
                .presentationBackground(Color(uiColor: .systemBackground))
                .presentationCornerRadius(24)
        }
    }
}

#Preview {
    MoreView()
} 