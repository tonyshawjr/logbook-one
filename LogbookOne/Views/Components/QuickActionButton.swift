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
                    showingSheet = true
                }) {
                    Image(systemName: "plus")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.appAccent)
                        .clipShape(Circle())
                        .shadow(color: Color.appAccent.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 80) // Position above tab bar
            }
        }
    }
}

#Preview {
    QuickActionButton(showingSheet: .constant(false), currentTab: 0)
} 