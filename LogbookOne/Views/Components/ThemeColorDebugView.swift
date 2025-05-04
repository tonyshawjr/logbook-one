import SwiftUI

/// A utility view to display the theme colors for debugging purposes
struct ThemeColorDebugView: View {
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Theme Background")
                    .font(.caption)
                
                Spacer()
                
                Rectangle()
                    .fill(Color.themeBackground)
                    .frame(width: 50, height: 30)
                    .border(Color.black, width: 1)
            }
            
            HStack {
                Text("Theme Card")
                    .font(.caption)
                
                Spacer()
                
                Rectangle()
                    .fill(Color.themeCard)
                    .frame(width: 50, height: 30)
                    .border(Color.black, width: 1)
            }
            
            HStack {
                Text("Theme Accent")
                    .font(.caption)
                
                Spacer()
                
                Rectangle()
                    .fill(Color.themeAccent)
                    .frame(width: 50, height: 30)
                    .border(Color.black, width: 1)
            }
            
            HStack {
                Text("Theme Primary")
                    .font(.caption)
                
                Spacer()
                
                Rectangle()
                    .fill(Color.themePrimary)
                    .frame(width: 50, height: 30)
                    .border(Color.black, width: 1)
            }
            
            HStack {
                Text("Theme Secondary")
                    .font(.caption)
                
                Spacer()
                
                Rectangle()
                    .fill(Color.themeSecondary)
                    .frame(width: 50, height: 30)
                    .border(Color.black, width: 1)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .padding()
    }
} 