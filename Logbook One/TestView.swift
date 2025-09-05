import SwiftUI

struct TestView: View {
    @State private var selectedTab = 0
    @State private var showMenu = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background content
            Color.gray.opacity(0.1)
                .ignoresSafeArea()
            
            Text("Tab \(selectedTab)")
                .font(.largeTitle)
            
            // Simple tab bar
            HStack {
                ForEach(0..<4) { index in
                    Button(action: { selectedTab = index }) {
                        VStack {
                            Image(systemName: "square.fill")
                            Text("Tab \(index)")
                                .font(.caption)
                        }
                        .foregroundColor(selectedTab == index ? .blue : .gray)
                    }
                    .frame(maxWidth: .infinity)
                    
                    if index == 1 {
                        // Center button
                        Button(action: { showMenu = true }) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: "plus")
                                        .foregroundColor(.white)
                                        .font(.title2)
                                )
                        }
                        .offset(y: -20)
                    }
                }
            }
            .frame(height: 49)
            .padding(.horizontal)
            .background(
                Color.white
                    .shadow(radius: 2)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .sheet(isPresented: $showMenu) {
            VStack {
                Text("Quick Add Menu")
                    .font(.headline)
                    .padding()
                
                Button("Add Task") { showMenu = false }
                    .padding()
                Button("Add Note") { showMenu = false }
                    .padding()
                Button("Add Payment") { showMenu = false }
                    .padding()
                
                Spacer()
            }
            .presentationDetents([.height(280)])
            .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    TestView()
}