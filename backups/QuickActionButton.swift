import SwiftUI

struct QuickActionButton: View {
    @Binding var showingSheet: Bool
    var currentTab: Int
    
    var body: some View {
        // Show button on all tabs
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    // Use haptic feedback when pressing button
                    let impactMed = UIImpactFeedbackGenerator(style: .medium)
                    impactMed.impactOccurred()
                    
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
                .padding(.bottom, 80) // Position above tab bar
            }
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