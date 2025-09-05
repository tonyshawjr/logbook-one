import SwiftUI
import CoreData

// Extension to check if the device has a home indicator (iPhone X and later)
extension UIDevice {
    var hasHomeIndicator: Bool {
        if #available(iOS 15.0, *) {
            // Use the recommended approach for iOS 15+
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) else {
                return false
            }
            return keyWindow.safeAreaInsets.bottom > 0
        } else {
            // Fallback for iOS versions before 15.0
            let windows = UIApplication.shared.windows
            let keyWindow = windows.first(where: { $0.isKeyWindow })
            return keyWindow?.safeAreaInsets.bottom ?? 0 > 0
        }
    }
}

// Notification name for refreshing views after quick add
extension Notification.Name {
    static let refreshAfterQuickAdd = Notification.Name("refreshAfterQuickAdd")
}

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
    @State private var selectedTab = 0
    @State private var refreshID = UUID()
    @State private var showQuickAddMenu = false
    @State private var showingQuickAddForm = false
    @State private var quickAddType: LogEntryType = .task
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var clientFormState: ClientFormState
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            Group {
                switch selectedTab {
                case 0:
                    NavigationStack {
                        DashboardView()
                            .environment(\.managedObjectContext, viewContext)
                            .id(refreshID)
                    }
                case 1:
                    NavigationStack {
                        TasksView()
                            .environment(\.managedObjectContext, viewContext)
                            .id(refreshID)
                    }
                case 2:
                    NavigationStack {
                        NotesView()
                            .environment(\.managedObjectContext, viewContext)
                            .id(refreshID)
                    }
                case 3:
                    NavigationStack {
                        PaymentsView()
                            .environment(\.managedObjectContext, viewContext)
                            .id(refreshID)
                    }
                default:
                    NavigationStack {
                        DashboardView()
                            .environment(\.managedObjectContext, viewContext)
                            .id(refreshID)
                    }
                }
            }
            
            // Custom tab bar with center button
            CustomTabBar(
                selectedTab: $selectedTab,
                showQuickAddMenu: $showQuickAddMenu
            )
        }
        .onChange(of: colorScheme) { oldValue, newValue in
            let _ = CurrentTheme.shared.getCurrentTheme(isDark: newValue == .dark)
            refreshID = UUID()
        }
        .onAppear {
            setupNotifications()
        }
        .onDisappear {
            removeNotifications()
        }
        // Sheet for Quick Add Menu - sliding up from bottom
        .sheet(isPresented: $showQuickAddMenu) {
            QuickAddMenuSheet(
                quickAddType: $quickAddType,
                showingQuickAddForm: $showingQuickAddForm
            )
            .presentationDetents([.height(280)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
            .presentationBackground(Color(uiColor: .systemBackground))
        }
        // Sheet for Quick Add Forms
        .sheet(isPresented: $showingQuickAddForm) {
            QuickAddView(initialEntryType: quickAddType)
                .presentationDragIndicator(.visible)
                .presentationDetents([.height(quickAddType == .task ? 420 : quickAddType == .payment ? 420 : 360)])
                .presentationBackground(Color(uiColor: .systemBackground))
                .presentationCornerRadius(24)
                .onDisappear {
                    NotificationCenter.default.post(name: .refreshAfterQuickAdd, object: nil)
                }
        }
        // Client form sheet
        .sheet(isPresented: $clientFormState.showingAddClient) {
            ClientFormView()
                .environment(\.managedObjectContext, viewContext)
                .presentationDragIndicator(.hidden)
                .presentationDetents([.height(420)])
                .presentationBackground(Color(uiColor: .systemBackground))
                .presentationCornerRadius(24)
                .onDisappear {
                    NotificationCenter.default.post(name: .refreshAfterQuickAdd, object: nil)
                }
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(forName: .refreshAfterQuickAdd, object: nil, queue: .main) { _ in
            refreshID = UUID()
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("ThemeColorChange"), object: nil, queue: .main) { _ in
            refreshID = UUID()
        }
        
        // Quick add notifications from other views
        NotificationCenter.default.addObserver(forName: Notification.Name("ShowAddTask"), object: nil, queue: .main) { _ in
            quickAddType = .task
            showingQuickAddForm = true
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name("ShowAddNote"), object: nil, queue: .main) { _ in
            quickAddType = .note
            showingQuickAddForm = true
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name("ShowAddPayment"), object: nil, queue: .main) { _ in
            quickAddType = .payment
            showingQuickAddForm = true
        }
    }
    
    private func removeNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
}

// Simplified Quick Add Menu Sheet
struct QuickAddMenuSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var quickAddType: LogEntryType
    @Binding var showingQuickAddForm: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 20)
            
            // Menu title
            Text("What would you like to add?")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
            
            // Menu options
            VStack(spacing: 0) {
                MenuButton(
                    icon: "checkmark.circle.fill",
                    title: "New Task",
                    color: .themeAccent,
                    action: {
                        quickAddType = .task
                        dismiss()
                        // Slightly faster transition for better continuity
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            showingQuickAddForm = true
                        }
                    }
                )
                
                Divider()
                    .padding(.horizontal)
                
                MenuButton(
                    icon: "doc.text.fill",
                    title: "New Note",
                    color: .blue,
                    action: {
                        quickAddType = .note
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            showingQuickAddForm = true
                        }
                    }
                )
                
                Divider()
                    .padding(.horizontal)
                
                MenuButton(
                    icon: "dollarsign.circle.fill",
                    title: "New Payment",
                    color: .green,
                    action: {
                        quickAddType = .payment
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            showingQuickAddForm = true
                        }
                    }
                )
            }
            
            Spacer()
        }
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
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}