import SwiftUI

// Extension for consistent colors throughout the app
extension Color {
    // Main backgrounds
    static let themeBackground = Color("appBackground")
    static let themeCard = Color("cardBackground")
    
    // Text colors
    static let themePrimary = Color("primaryText")
    static let themeSecondary = Color("secondaryText")
    
    // Accent colors
    static let themeAccent = Color("appAccent")
    static let themeSuccess = Color("success")
    static let themeWarning = Color("warning")
    static let themeDanger = Color("danger")
    
    // Task type colors - more muted, sophisticated palette
    static let themeTask = Color("taskColor")
    static let themeNote = Color("noteColor")
    static let themePayment = Color("paymentColor")
    
    // Helper to create color from hex code
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Extension for consistent text styles - more refined typography
extension Font {
    static let appTitle = Font.system(.largeTitle, design: .default).weight(.bold)
    static let appTitle2 = Font.system(.title2, design: .default).weight(.bold)
    static let appTitle3 = Font.system(.title3, design: .default).weight(.semibold)
    static let appHeadline = Font.system(.headline, design: .default).weight(.semibold)
    static let appSubheadline = Font.system(.subheadline, design: .default).weight(.medium)
    static let appBody = Font.system(.body, design: .default)
    static let appCallout = Font.system(.callout, design: .default)
    static let appCaption = Font.system(.caption, design: .default)
}

// Extension for consistent view modifiers
extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .background(Color.themeCard)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .padding(.horizontal)
    }
    
    func primaryButtonStyle() -> some View {
        self
            .font(.appHeadline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.themeAccent)
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: Color.themeAccent.opacity(0.3), radius: 5, x: 0, y: 2)
            .padding(.horizontal)
    }
    
    func secondaryButtonStyle() -> some View {
        self
            .font(.appHeadline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.themeCard)
            .foregroundColor(.themeAccent)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.themeAccent.opacity(0.5), lineWidth: 1)
            )
            .padding(.horizontal)
    }
}

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    let buttonText: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: systemImage)
                .font(.system(size: 70))
                .foregroundColor(Color.themeSecondary.opacity(0.3))
                .padding(.bottom, 10)
            
            Text(title)
                .font(.appTitle2)
                .foregroundColor(.themePrimary)
            
            Text(message)
                .font(.appBody)
                .foregroundColor(.themeSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: action) {
                Text(buttonText)
                    .primaryButtonStyle()
            }
            .padding(.top, 10)
            
            Spacer()
        }
        .frame(minHeight: 400)
    }
} 