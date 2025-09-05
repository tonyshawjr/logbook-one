import SwiftUI
import CoreLocation
import CoreData

// MARK: - Context Type
enum ContextType {
    case morning
    case working
    case driving
    case evening
    case deadline
    
    var icon: String {
        switch self {
        case .morning: return "sun.min.fill"
        case .working: return "briefcase.fill"
        case .driving: return "car.fill"
        case .evening: return "moon.fill"
        case .deadline: return "exclamationmark.triangle.fill"
        }
    }
    
    var defaultAction: LogEntryType {
        switch self {
        case .morning, .working, .deadline: return .task
        case .evening: return .payment
        case .driving: return .note
        }
    }
    
    var pulseColor: Color {
        switch self {
        case .morning: return Color(red: 1.0, green: 0.7, blue: 0.3) // Warm orange
        case .working: return .themeAccent
        case .driving: return Color(red: 0.3, green: 0.8, blue: 0.5) // Safe green
        case .evening: return Color(red: 0.5, green: 0.3, blue: 0.8) // Calm purple
        case .deadline: return Color(red: 0.9, green: 0.3, blue: 0.3) // Urgent red
        }
    }
}

// MARK: - Haptic Manager
class HapticManager {
    static let shared = HapticManager()
    
    enum HapticType {
        case light    // "I see you"
        case medium   // "Try this"
        case strong   // "Attention needed"
        case success
        case contextSwitch
    }
    
    func trigger(_ type: HapticType) {
        switch type {
        case .light:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        case .medium:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        case .strong:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case .contextSwitch:
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
    }
}

// MARK: - Custom Tab Bar
struct PulseTabBar: View {
    @Binding var selectedTab: Int
    @Binding var showRadialMenu: Bool
    @Binding var selectedQuickAction: LogEntryType?
    @State private var showingQuickAdd = false
    @State private var pulseAnimation = false
    @State private var currentContext: ContextType = .morning
    @State private var dragOffset: CGSize = .zero
    @State private var isPulling = false
    @State private var tabHapticFeedback: [Int: Bool] = [:]
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    // Tab items configuration
    private let tabs = [
        (name: "Today", icon: "house", tab: 0),
        (name: "Tasks", icon: "checkmark.circle", tab: 1),
        (name: "Notes", icon: "doc.text", tab: 2),
        (name: "Payments", icon: "dollarsign.circle", tab: 3)
    ]
    
    private var hasHomeIndicator: Bool {
        UIDevice.current.hasHomeIndicator
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background blur and separator
                VStack(spacing: 0) {
                    Divider()
                        .background(Color.gray.opacity(0.2))
                    
                    // Tab bar background
                    Rectangle()
                        .fill(Color.themeBackground)
                        .overlay(
                            Rectangle()
                                .fill(.ultraThinMaterial)
                                .opacity(0.98)
                        )
                }
                .frame(height: hasHomeIndicator ? 83 : 49)
                
                // Tab items and center pulse button
                HStack(spacing: 0) {
                    // First two tabs
                    ForEach(0..<2) { index in
                        TabBarItem(
                            tab: tabs[index],
                            selectedTab: $selectedTab,
                            showingQuickAdd: $showingQuickAdd,
                            hapticFeedback: $tabHapticFeedback
                        )
                    }
                    
                    // Center Pulse Button
                    PulseButton(
                        currentContext: $currentContext,
                        showRadialMenu: $showRadialMenu,
                        selectedQuickAction: $selectedQuickAction,
                        pulseAnimation: $pulseAnimation,
                        selectedTab: $selectedTab
                    )
                    
                    // Last two tabs
                    ForEach(2..<4) { index in
                        TabBarItem(
                            tab: tabs[index],
                            selectedTab: $selectedTab,
                            showingQuickAdd: $showingQuickAdd,
                            hapticFeedback: $tabHapticFeedback
                        )
                    }
                }
                .frame(height: 49)
                .padding(.bottom, hasHomeIndicator ? 34 : 0)
                
            
            }
            .frame(height: hasHomeIndicator ? 83 : 49)
        }
        .onAppear {
            updateContext()
            startPulseAnimation()
            
            // Update context periodically
            Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                updateContext()
            }
        }
        .sheet(item: $selectedQuickAction) { type in
            QuickAddView(initialEntryType: type)
                .presentationDragIndicator(.hidden)
                .presentationDetents([.height(type == .task ? 380 : 360)])
                .presentationBackground(Color(uiColor: .systemBackground))
                .presentationCornerRadius(24)
                .interactiveDismissDisabled(false)
                .onDisappear {
                    NotificationCenter.default.post(name: .refreshAfterQuickAdd, object: nil)
                }
        }
        // Pull gesture for quick-add panel
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height < -20 && !isPulling {
                        isPulling = true
                        HapticManager.shared.trigger(.light)
                    }
                    dragOffset = value.translation
                }
                .onEnded { value in
                    if value.translation.height < -50 {
                        // Show quick-add panel
                        showQuickAddPanel()
                    }
                    dragOffset = .zero
                    isPulling = false
                }
        )
    }
    
    private func updateContext() {
        let hour = Calendar.current.component(.hour, from: Date())
        let weekday = Calendar.current.component(.weekday, from: Date())
        
        // Check for deadlines
        if hasUpcomingDeadlines() {
            currentContext = .deadline
        } else if isDriving() {
            currentContext = .driving
        } else if hour >= 5 && hour < 12 {
            currentContext = .morning
        } else if hour >= 12 && hour < 17 && (weekday >= 2 && weekday <= 6) {
            currentContext = .working
        } else {
            currentContext = .evening
        }
        
        // Trigger context switch haptic
        HapticManager.shared.trigger(.contextSwitch)
    }
    
    private func hasUpcomingDeadlines() -> Bool {
        // Check for tasks due in next 2 hours
        let request: NSFetchRequest<LogEntry> = LogEntry.fetchRequest()
        let twoHoursFromNow = Date().addingTimeInterval(7200)
        request.predicate = NSPredicate(
            format: "type == %d AND isComplete == NO AND date != nil AND date < %@",
            LogEntryType.task.rawValue,
            twoHoursFromNow as NSDate
        )
        request.fetchLimit = 1
        
        do {
            let count = try viewContext.count(for: request)
            return count > 0
        } catch {
            return false
        }
    }
    
    private func isDriving() -> Bool {
        // This would integrate with CoreMotion or location services
        // For now, return false
        return false
    }
    
    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
    }
    
    private func showQuickAddPanel() {
        HapticManager.shared.trigger(.medium)
        selectedQuickAction = currentContext.defaultAction
    }
}

// MARK: - Tab Bar Item
struct TabBarItem: View {
    let tab: (name: String, icon: String, tab: Int)
    @Binding var selectedTab: Int
    @Binding var showingQuickAdd: Bool
    @Binding var hapticFeedback: [Int: Bool]
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            if selectedTab != tab.tab {
                HapticManager.shared.trigger(.light)
                selectedTab = tab.tab
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 22))
                    .symbolRenderingMode(.hierarchical)
                
                Text(tab.name)
                    .font(.caption2)
            }
            .foregroundColor(selectedTab == tab.tab ? .themeAccent : .gray)
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.1), value: isPressed)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.3) {
            // Long press for quick action
            triggerQuickAction(for: tab.tab)
        } onPressingChanged: { pressing in
            isPressed = pressing
            if pressing && hapticFeedback[tab.tab] != true {
                HapticManager.shared.trigger(.light)
                hapticFeedback[tab.tab] = true
            } else if !pressing {
                hapticFeedback[tab.tab] = false
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onChanged { value in
                    if value.translation.height < -30 && !showingQuickAdd {
                        // Swipe up for quick add - contextual to current page
                        triggerContextualQuickAction()
                        showingQuickAdd = true
                    }
                }
                .onEnded { _ in
                    showingQuickAdd = false
                }
        )
    }
    
    private func triggerQuickAction(for tab: Int) {
        HapticManager.shared.trigger(.medium)
        
        switch tab {
        case 1: // Tasks
            NotificationCenter.default.post(name: Notification.Name("ShowAddTask"), object: nil)
        case 2: // Notes
            NotificationCenter.default.post(name: Notification.Name("ShowAddNote"), object: nil)
        case 3: // Payments
            NotificationCenter.default.post(name: Notification.Name("ShowAddPayment"), object: nil)
        default:
            break
        }
    }
    
    private func triggerContextualQuickAction() {
        HapticManager.shared.trigger(.medium)
        
        // Use current selected tab instead of the tab button that was swiped
        switch selectedTab {
        case 0: // Dashboard - default to task
            NotificationCenter.default.post(name: Notification.Name("ShowAddTask"), object: nil)
        case 1: // Tasks
            NotificationCenter.default.post(name: Notification.Name("ShowAddTask"), object: nil)
        case 2: // Notes
            NotificationCenter.default.post(name: Notification.Name("ShowAddNote"), object: nil)
        case 3: // Payments
            NotificationCenter.default.post(name: Notification.Name("ShowAddPayment"), object: nil)
        default:
            NotificationCenter.default.post(name: Notification.Name("ShowAddTask"), object: nil)
        }
    }
}

// MARK: - Pulse Button
struct PulseButton: View {
    @Binding var currentContext: ContextType
    @Binding var showRadialMenu: Bool
    @Binding var selectedQuickAction: LogEntryType?
    @Binding var pulseAnimation: Bool
    @Binding var selectedTab: Int
    
    @State private var isPressed = false
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        ZStack {
            // Pulse effect
            Circle()
                .fill(currentContext.pulseColor.opacity(0.2))
                .frame(width: 56, height: 56)
                .scaleEffect(pulseAnimation ? 1.3 : 1.0)
                .opacity(pulseAnimation ? 0.0 : 0.3)
            
            // Main button
            Button(action: {
                HapticManager.shared.trigger(.medium)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showRadialMenu.toggle()
                    rotationAngle = showRadialMenu ? 135 : 0
                }
            }) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [currentContext.pulseColor, currentContext.pulseColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 56, height: 56)
                        .shadow(color: currentContext.pulseColor.opacity(0.4), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: showRadialMenu ? "xmark" : currentContext.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .rotationEffect(Angle(degrees: rotationAngle))
                }
                .scaleEffect(isPressed ? 0.9 : 1.0)
            }
            .onLongPressGesture {
                // Quick add contextual action based on current tab
                print("Long press detected! selectedTab: \(selectedTab)")
                HapticManager.shared.trigger(.strong)
                selectedQuickAction = getContextualAction()
                print("Set selectedQuickAction to: \(getContextualAction())")
            } onPressingChanged: { pressing in
                isPressed = pressing
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func getContextualAction() -> LogEntryType {
        switch selectedTab {
        case 0: return .task  // Dashboard - default to task
        case 1: return .task  // Tasks tab
        case 2: return .note  // Notes tab
        case 3: return .payment  // Payments tab
        default: return .task
        }
    }
}


#Preview {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            PulseTabBar(
                selectedTab: .constant(0),
                showRadialMenu: .constant(false),
                selectedQuickAction: .constant(nil)
            )
        }
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}