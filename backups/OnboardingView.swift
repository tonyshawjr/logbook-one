import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    
    let pages = [
        OnboardingPage(
            title: "Say hello to Logbook One",
            subtitle: "Professional record-keeping for solo business owners",
            imageName: "doc.text.magnifyingglass",
            backgroundColor: Color(hex: "#F5F5F0")
        ),
        OnboardingPage(
            title: "Keep a journal",
            subtitle: "of your client interactions",
            imageName: "calendar",
            backgroundColor: Color(hex: "#F5F5F0")
        ),
        OnboardingPage(
            title: "Track payments",
            subtitle: "and monitor your business growth",
            imageName: "dollarsign.circle",
            backgroundColor: Color(hex: "#F5F5F0")
        ),
        OnboardingPage(
            title: "Private and secure",
            subtitle: "Your data stays on your device",
            imageName: "lock.shield",
            backgroundColor: Color(hex: "#F5F5F0")
        )
    ]
    
    var body: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                VStack(spacing: 20) {
                    // Page indicator
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color.themeAccent : Color.themeAccent.opacity(0.2))
                                .frame(width: 8, height: 8)
                                .scaleEffect(currentPage == index ? 1.2 : 1.0)
                                .animation(.spring(), value: currentPage)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Continue button
                    Button(action: {
                        if currentPage < pages.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            hasCompletedOnboarding = true
                        }
                    }) {
                        HStack {
                            Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
                                .font(.appHeadline)
                            
                            Image(systemName: "arrow.right")
                                .font(.appHeadline)
                        }
                        .frame(height: 24)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.themeAccent)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .shadow(color: Color.themeAccent.opacity(0.3), radius: 5, x: 0, y: 2)
                    }
                    
                    // Skip button
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            hasCompletedOnboarding = true
                        }
                        .font(.appSubheadline)
                        .foregroundColor(.themeSecondary)
                        .padding(.vertical, 12)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let imageName: String
    let backgroundColor: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Icon
            Image(systemName: page.imageName)
                .font(.system(size: 80))
                .foregroundColor(Color.themeAccent)
                .padding(.bottom, 20)
            
            // Title
            Text(page.title)
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.themePrimary)
                .multilineTextAlignment(.center)
            
            // Subtitle
            Text(page.subtitle)
                .font(.appTitle3)
                .foregroundColor(.themeSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Spacer()
            Spacer()
        }
        .padding()
        .background(page.backgroundColor)
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
} 