import SwiftUI

struct EntryTypeBadgeView: View {
    let type: LogEntryType
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: iconName)
                .font(.caption.weight(.semibold))
            
            Text(type.displayName)
                .font(.appCaption.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(backgroundColor)
        .foregroundColor(.white)
        .cornerRadius(12)
    }
    
    private var backgroundColor: Color {
        switch type {
        case .task:
            return Color.themeTask
        case .note:
            return Color.themeNote
        case .payment:
            return Color.themePayment
        }
    }
    
    private var iconName: String {
        switch type {
        case .task:
            return "checkmark.circle"
        case .note:
            return "doc.text"
        case .payment:
            return "dollarsign.circle"
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        EntryTypeBadgeView(type: .task)
        EntryTypeBadgeView(type: .note)
        EntryTypeBadgeView(type: .payment)
    }
    .padding()
} 