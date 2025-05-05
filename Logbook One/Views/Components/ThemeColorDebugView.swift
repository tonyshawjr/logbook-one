import SwiftUI

/// A utility view to display the theme colors for debugging purposes
struct ThemeColorDebugView: View {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerView
                
                Group {
                    colorSection(title: "Background Colors", colors: [
                        ("background", theme.background),
                        ("card", theme.card)
                    ])
                    
                    colorSection(title: "Text Colors", colors: [
                        ("primaryText", theme.primaryText),
                        ("secondaryText", theme.secondaryText)
                    ])
                    
                    colorSection(title: "UI Colors", colors: [
                        ("accent", theme.accent),
                        ("success", theme.success),
                        ("warning", theme.warning),
                        ("danger", theme.danger)
                    ])
                    
                    colorSection(title: "Type Colors", colors: [
                        ("task", theme.task),
                        ("note", theme.note),
                        ("payment", theme.payment)
                    ])
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(theme.background)
        .navigationTitle("Theme Colors")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("Current Theme")
                .font(.appTitle2)
                .foregroundColor(theme.primaryText)
            
            Text(colorScheme == .dark ? "Dark Mode" : "Light Mode")
                .font(.appHeadline)
                .foregroundColor(theme.accent)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(theme.card)
                .cornerRadius(20)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(theme.card)
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private func colorSection(title: String, colors: [(name: String, color: Color)]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.appHeadline)
                .foregroundColor(theme.primaryText)
                .padding(.bottom, 4)
            
            ForEach(colors, id: \.name) { colorItem in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(colorItem.color)
                        .frame(width: 60, height: 40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(theme.secondaryText.opacity(0.2), lineWidth: 1)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(colorItem.name)
                            .font(.appBody)
                            .foregroundColor(theme.primaryText)
                    }
                    
                    Spacer()
                }
                .padding(12)
                .background(theme.card)
                .cornerRadius(12)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ThemeColorDebugView()
    }
} 