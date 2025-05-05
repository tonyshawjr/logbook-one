import SwiftUI

struct QuickActionButton: View {
    // The tabs where this button should be shown (0=Today, 1=Tasks, 2=Notes, 3=Payments)
    // Clients is now tab 4, and there's no tab 5 or 6 anymore
    private let allowedTabs = [0, 1, 2, 3]
    
    @Binding var showingSheet: Bool
    var currentTab: Int
    
    var body: some View {
        // Only render actual content if we're on an allowed tab
        if allowedTabs.contains(currentTab) {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        // Use haptic feedback when pressing button
                        let impactMed = UIImpactFeedbackGenerator(style: .medium)
                        impactMed.impactOccurred()
                        
                        // Show the appropriate quick add sheet
                        showingSheet = true
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
                }
            }
            .background(Color.clear)
        } else {
            // Return an empty view for tabs where the button shouldn't appear
            EmptyView()
        }
    }
}

// Custom button style for smoother press animation
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

#Preview {
    QuickActionButton(showingSheet: .constant(false), currentTab: 0)
} 