import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Binding var showQuickAddMenu: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            // Left side tabs
            TabButton(
                icon: "house",
                text: "Today",
                isSelected: selectedTab == 0,
                action: { selectedTab = 0 }
            )
            
            TabButton(
                icon: "checkmark.circle",
                text: "Tasks",
                isSelected: selectedTab == 1,
                action: { selectedTab = 1 }
            )
            
            // Center add button - takes up space
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                showQuickAddMenu = true
            }) {
                ZStack {
                    Circle()
                        .fill(Color.themeAccent)
                        .frame(width: 65, height: 65)
                        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .offset(y: -18) // Lift it up so it overlaps the bar
            .frame(maxWidth: .infinity)
            
            // Right side tabs
            TabButton(
                icon: "doc.text",
                text: "Notes",
                isSelected: selectedTab == 2,
                action: { selectedTab = 2 }
            )
            
            TabButton(
                icon: "dollarsign.circle",
                text: "Payments",
                isSelected: selectedTab == 3,
                action: { selectedTab = 3 }
            )
        }
        .frame(height: 49)
        .padding(.horizontal, 8)
        .background(
            Color.themeBackground
                .shadow(color: Color.black.opacity(0.1), radius: 0, x: 0, y: -0.5)
                .frame(height: UIDevice.current.hasHomeIndicator ? 83 : 49)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

struct TabButton: View {
    let icon: String
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .symbolRenderingMode(.hierarchical)
                
                Text(text)
                    .font(.caption2)
            }
            .foregroundColor(isSelected ? .themeAccent : .gray)
            .frame(maxWidth: .infinity)
        }
    }
}

// Quick Add Menu that appears when center button is tapped
struct QuickAddMenu: View {
    @Binding var isPresented: Bool
    @Binding var selectedType: LogEntryType?
    
    var body: some View {
        VStack(spacing: 0) {
            // Menu content
            VStack(spacing: 1) {
                MenuButton(
                    icon: "checkmark.circle.fill",
                    title: "New Task",
                    color: .themeAccent,
                    action: {
                        selectedType = .task
                        isPresented = false
                    }
                )
                
                Divider()
                
                MenuButton(
                    icon: "doc.text.fill",
                    title: "New Note",
                    color: .blue,
                    action: {
                        selectedType = .note
                        isPresented = false
                    }
                )
                
                Divider()
                
                MenuButton(
                    icon: "dollarsign.circle.fill",
                    title: "New Payment",
                    color: .green,
                    action: {
                        selectedType = .payment
                        isPresented = false
                    }
                )
            }
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            .padding()
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
        )
    }
    
    struct MenuButton: View {
        let icon: String
        let title: String
        let color: Color
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                HStack(spacing: 16) {
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                        .frame(width: 30)
                    
                    Text(title)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}