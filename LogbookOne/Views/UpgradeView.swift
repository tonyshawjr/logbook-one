import SwiftUI
import SafariServices

struct UpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var couponCode = ""
    @State private var showingCouponEntry = false
    @State private var showingCouponSuccess = false
    @State private var showingCouponError = false
    @State private var safariVC: SFSafariViewController?
    @State private var showingSafari = false
    @State private var selectedSubscription: PurchaseManager.SubscriptionType = .monthly
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        proHeader
                        
                        // Subscription options
                        subscriptionOptions
                        
                        // Features list
                        featuresSection
                        
                        // Coupon section
                        couponSection
                        
                        // Purchase button
                        purchaseButton
                        
                        // Restore purchases
                        Button("Already purchased? Restore") {
                            // Implement restore logic here
                        }
                        .font(.footnote)
                        .foregroundColor(.themeSecondary)
                        .padding(.top, 8)
                    }
                    .padding()
                }
            }
            .navigationTitle("Upgrade to Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.themeBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Success!", isPresented: $showingCouponSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Test mode activated. You now have access to all Pro features.")
            }
            .alert("Invalid Code", isPresented: $showingCouponError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("The coupon code you entered is not valid.")
            }
        }
    }
    
    // MARK: - UI Components
    
    private var proHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.themeAccent)
            
            Text("Logbook One Pro")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.themePrimary)
            
            Text("Unlock all features and supercharge your productivity")
                .font(.subheadline)
                .foregroundColor(.themeSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 12)
    }
    
    private var subscriptionOptions: some View {
        VStack(spacing: 12) {
            Text("Choose Your Plan")
                .font(.headline)
                .foregroundColor(.themePrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Monthly option
            subscriptionCard(
                title: "Monthly",
                price: purchaseManager.getPrice(for: .monthly),
                description: "Flexible, cancel anytime",
                isSelected: selectedSubscription == .monthly
            ) {
                selectedSubscription = .monthly
            }
            
            // Yearly option
            subscriptionCard(
                title: "Annual",
                price: purchaseManager.getPrice(for: .yearly),
                description: "Save 16% compared to monthly",
                isSelected: selectedSubscription == .yearly
            ) {
                selectedSubscription = .yearly
            }
            
            // Lifetime option
            subscriptionCard(
                title: "Lifetime",
                price: purchaseManager.getPrice(for: .lifetime),
                description: "One-time purchase, unlimited access",
                isSelected: selectedSubscription == .lifetime
            ) {
                selectedSubscription = .lifetime
            }
        }
        .padding(.top, 8)
    }
    
    private func subscriptionCard(title: String, price: String, description: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.themePrimary)
                    
                    Text(price)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.themeAccent)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.themeSecondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .themeAccent : .themeSecondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.themeCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.themeAccent : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What's Included")
                .font(.headline)
                .foregroundColor(.themePrimary)
            
            featureRow(icon: "checkmark.square.fill", title: "Tasks Management", description: "Track and organize all your tasks")
            featureRow(icon: "dollarsign.circle.fill", title: "Payments Tracking", description: "Record and analyze your income")
            featureRow(icon: "person.crop.circle.fill", title: "Client Management", description: "Keep track of client details and tasks")
            featureRow(icon: "bell.fill", title: "Nag Mode", description: "Accountability reminders to keep you on track")
            featureRow(icon: "arrow.up.arrow.down", title: "Data Import/Export", description: "Backup and sync your data as CSV or JSON")
        }
        .padding(.top, 16)
    }
    
    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.themeAccent)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.themePrimary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.themeSecondary)
            }
        }
    }
    
    private var couponSection: some View {
        VStack {
            if showingCouponEntry {
                HStack {
                    TextField("Enter coupon code", text: $couponCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Button("Apply") {
                        applyCoupon()
                    }
                    .foregroundColor(.themeAccent)
                }
                .padding(.top, 8)
            } else {
                Button("Have a coupon code?") {
                    showingCouponEntry = true
                }
                .font(.footnote)
                .foregroundColor(.themeAccent)
                .padding(.top, 16)
            }
        }
    }
    
    private var purchaseButton: some View {
        Button(action: {
            startPurchase()
        }) {
            Text("Upgrade Now")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.themeAccent)
                .cornerRadius(12)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Actions
    
    private func applyCoupon() {
        let success = purchaseManager.applyCoupon(couponCode)
        if success {
            showingCouponSuccess = true
            // Auto-dismiss after successful code entry
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                dismiss()
            }
        } else {
            showingCouponError = true
        }
    }
    
    private func startPurchase() {
        if let url = purchaseManager.getPurchaseURL(for: selectedSubscription) {
            let config = SFSafariViewController.Configuration()
            safariVC = SFSafariViewController(url: url, configuration: config)
            showingSafari = true
            
            // Presentation logic would typically use UIKit integration
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                if let safariVC = safariVC {
                    rootViewController.present(safariVC, animated: true)
                }
            }
        }
    }
}

#Preview {
    UpgradeView()
} 