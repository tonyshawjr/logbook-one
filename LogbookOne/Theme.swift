import SwiftUI

// Central theme model that manages all colors
struct AppTheme {
    let background: Color
    let card: Color
    
    let primaryText: Color
    let secondaryText: Color
    
    let accent: Color
    let success: Color
    let warning: Color
    let danger: Color
    
    let task: Color
    let note: Color
    let payment: Color
}

// Light theme definition
let LightTheme = AppTheme(
    background: Color(hex: "#F5F5F0"),   // light warm gray
    card: Color.white,
    
    primaryText: Color(hex: "#1C1C1E"),  // deep neutral black/blue
    secondaryText: Color(hex: "#5A5F71"), // slightly desaturated blue-gray
    
    accent: Color(hex: "#007AFF"),       // iOS system blue
    success: Color(hex: "#21C162"),      // success green
    warning: Color(hex: "#FFD166"),      // warning amber
    danger: Color(hex: "#F65C5C"),       // danger red
    
    task: Color(hex: "#4C78FF"),         // task blue
    note: Color(hex: "#FFA552"),         // note orange
    payment: Color(hex: "#21C162")       // payment green
)

// Dark theme definition
let DarkTheme = AppTheme(
    background: Color(hex: "#1E1E1E"),   // almost black
    card: Color(hex: "#121212"),         // darker card background
    
    primaryText: Color.white,            // white text
    secondaryText: Color(hex: "#A3A3A3"), // medium gray for secondary text
    
    accent: Color(hex: "#007AFF"),       // iOS system blue
    success: Color(hex: "#21C162"),      // success green
    warning: Color(hex: "#FFD166"),      // warning amber
    danger: Color(hex: "#F65C5C"),       // danger red
    
    task: Color(hex: "#4C78FF"),         // task blue 
    note: Color(hex: "#FFA552"),         // note orange
    payment: Color(hex: "#21C162")       // payment green
)

// Environment key to access the theme
struct ThemeKey: EnvironmentKey {
    static let defaultValue = LightTheme
}

extension EnvironmentValues {
    var theme: AppTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// Global current theme class that can be accessed outside of SwiftUI views
class CurrentTheme: ObservableObject {
    static let shared = CurrentTheme()
    @Published private var isDarkMode = false
    private var appearanceCheckTimer: Timer?
    
    func getCurrentTheme(isDark: Bool) -> AppTheme {
        if isDarkMode != isDark {
            isDarkMode = isDark
            // Force update notifications
            objectWillChange.send()
            
            // Post a notification that theme has changed
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("ThemeColorChange"), object: nil)
            }
        }
        return isDark ? DarkTheme : LightTheme
    }
    
    var activeTheme: AppTheme {
        isDarkMode ? DarkTheme : LightTheme
    }
    
    // Initialize with current system appearance and set up monitoring
    private init() {
        self.isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        
        // Listen for app returning to foreground (common time for appearance changes)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(checkAppearance),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        // Set up a timer with longer interval - more efficient
        self.appearanceCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.checkAppearance()
        }
    }
    
    @objc private func checkAppearance() {
        // Check current trait collection
        let newIsDark = UITraitCollection.current.userInterfaceStyle == .dark
        if self.isDarkMode != newIsDark {
            // Only update if there's an actual change
            let _ = self.getCurrentTheme(isDark: newIsDark)
        }
    }
    
    deinit {
        appearanceCheckTimer?.invalidate()
        appearanceCheckTimer = nil
        NotificationCenter.default.removeObserver(self)
    }
}

// Extension for backward compatibility with existing code
extension Color {
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
    
    // Legacy color extensions for backward compatibility
    // These static properties now use the CurrentTheme singleton instead of @Environment
    static var themeBackground: Color { 
        return CurrentTheme.shared.activeTheme.background
    }
    static var themeCard: Color { 
        return CurrentTheme.shared.activeTheme.card
    }
    static var themePrimary: Color { 
        return CurrentTheme.shared.activeTheme.primaryText
    }
    static var themeSecondary: Color { 
        return CurrentTheme.shared.activeTheme.secondaryText
    }
    static var themeAccent: Color { 
        return CurrentTheme.shared.activeTheme.accent
    }
    static var themeSuccess: Color { 
        return CurrentTheme.shared.activeTheme.success
    }
    static var themeWarning: Color { 
        return CurrentTheme.shared.activeTheme.warning
    }
    static var themeDanger: Color { 
        return CurrentTheme.shared.activeTheme.danger
    }
    static var themeTask: Color { 
        return CurrentTheme.shared.activeTheme.task
    }
    static var themeNote: Color { 
        return CurrentTheme.shared.activeTheme.note
    }
    static var themePayment: Color { 
        return CurrentTheme.shared.activeTheme.payment
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

// Add a convenient view modifier for refreshing on theme changes
struct CurrentThemeModifier: ViewModifier {
    @ObservedObject var themeManager = CurrentTheme.shared
    
    func body(content: Content) -> some View {
        content
            .environmentObject(themeManager)
            .onReceive(themeManager.objectWillChange) { _ in
                // Let color changes happen naturally, don't force view refresh
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ThemeColorChange"))) { _ in
                // Let color changes happen naturally, don't force view refresh
            }
    }
}

// Extension to make it easy to apply the theme manager
extension View {
    func withCurrentTheme() -> some View {
        self.modifier(CurrentThemeModifier())
    }
} 