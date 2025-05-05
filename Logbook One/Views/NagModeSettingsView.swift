import SwiftUI

struct NagModeSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("nagModeEnabled") private var nagModeEnabled = false
    @AppStorage("nagModeCutoffTime") private var nagModeCutoffTime = 15 // 3 PM, stored as hour (24-hour format)
    @AppStorage("nagModeIntensity") private var nagModeIntensity = "Gentle"
    @AppStorage("nagModeTone") private var nagModeTone = "Encouraging"
    @AppStorage("nagModeInAppNags") private var nagModeInAppNags = true
    @AppStorage("nagModeBuddyName") private var nagModeBuddyName = ""
    @AppStorage("nagModeShowJournal") private var nagModeShowJournal = false
    
    @State private var showingTonePreview = false
    @State private var tempBuddyName = ""
    @State private var isEditingBuddyName = false
    
    // Sample messages for each tone to preview
    private let previewMessages = [
        "Encouraging": [
            "Still time to log something today. You've got this.",
            "A little progress goes a long way. Drop in a note or task.",
            "One log = one less thing to forget later."
        ],
        "Bossy": [
            "No excuses. Add a log.",
            "Didn't log today yet. Fix that.",
            "You said you wanted to stay on track. Prove it."
        ],
        "Friendly": [
            "Hey, got anything to jot down?",
            "Quick brain dump while it's still fresh?",
            "You've been quiet today. Want to log something?"
        ],
        "Sarcastic": [
            "No logs yet? What are you even doing?",
            "Today's looking empty… just like your entries.",
            "Still waiting on that log. Just like your clients."
        ]
    ]
    
    // Intensity options
    private let intensityOptions = ["Gentle", "Persistent", "Beast Mode"]
    
    // Tone options
    private let toneOptions = ["Encouraging", "Bossy", "Friendly", "Sarcastic"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Logo section
                        nagModeLogo
                            .padding(.top, 20)
                        
                        // Master toggle
                        nagModeToggle
                        
                        if nagModeEnabled {
                            // Settings sections
                            Group {
                                cutoffTimeSection
                                intensitySection
                                toneSection
                                inAppNagsSection
                                buddyModeSection
                                nagJournalSection
                            }
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                    .animation(.easeInOut, value: nagModeEnabled)
                }
            }
            .navigationTitle("Nag Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.themeBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Save buddy name if being edited
                        if isEditingBuddyName {
                            nagModeBuddyName = tempBuddyName
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            tempBuddyName = nagModeBuddyName
        }
        .sheet(isPresented: $showingTonePreview) {
            nagModePreviewSheet
        }
    }
    
    // MARK: - UI Components
    
    private var nagModeLogo: some View {
        VStack(spacing: 6) {
            // Simple Impact-style font
            Text("NAG MODE")
                .font(.system(size: 42, weight: .black, design: .default))
                .foregroundColor(.red)
                .kerning(2)
                .tracking(1)
            
            Text("YOUR ACCOUNTABILITY ENFORCER")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.themeSecondary)
        }
        .padding(.vertical, 16)
    }
    
    private var nagModeToggle: some View {
        VStack(spacing: 8) {
            Toggle("Enable Nag Mode", isOn: $nagModeEnabled)
                .font(.appHeadline)
                .tint(.themeAccent)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.themeCard)
                        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
                )
            
            if !nagModeEnabled {
                Text("Turn on Nag Mode to keep yourself accountable and never miss a day.")
                    .font(.appCaption)
                    .foregroundColor(.themeSecondary)
                    .padding(.horizontal)
                    .transition(.opacity)
            }
        }
    }
    
    private var cutoffTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cutoff Time")
                .font(.appTitle3)
                .foregroundColor(.themePrimary)
            
            Text("Nag Mode will activate if you haven't logged anything by this time.")
                .font(.appCaption)
                .foregroundColor(.themeSecondary)
            
            Picker("Cutoff Time", selection: $nagModeCutoffTime) {
                ForEach(8..<22) { hour in
                    Text(formatHour(hour)).tag(hour)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 100)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.themeCard)
                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        )
    }
    
    private var intensitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Intensity Level")
                .font(.appTitle3)
                .foregroundColor(.themePrimary)
            
            Text("How persistent should Nag Mode be?")
                .font(.appCaption)
                .foregroundColor(.themeSecondary)
            
            VStack(spacing: 12) {
                ForEach(intensityOptions, id: \.self) { option in
                    Button(action: {
                        nagModeIntensity = option
                    }) {
                        HStack {
                            Text(option)
                                .foregroundColor(.themePrimary)
                            
                            Spacer()
                            
                            if nagModeIntensity == option {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.themeAccent)
                            } else {
                                Circle()
                                    .stroke(Color.themeSecondary.opacity(0.4), lineWidth: 1)
                                    .frame(width: 22, height: 22)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    if option != intensityOptions.last {
                        Divider()
                    }
                }
            }
            
            Text(getIntensityDescription())
                .font(.appCaption)
                .foregroundColor(.themeSecondary)
                .padding(.top, 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.themeCard)
                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        )
    }
    
    private var toneSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tone & Personality")
                .font(.appTitle3)
                .foregroundColor(.themePrimary)
            
            Text("How should Nag Mode speak to you?")
                .font(.appCaption)
                .foregroundColor(.themeSecondary)
            
            VStack(spacing: 12) {
                ForEach(toneOptions, id: \.self) { option in
                    Button(action: {
                        nagModeTone = option
                    }) {
                        HStack {
                            Text(option)
                                .foregroundColor(.themePrimary)
                            
                            Spacer()
                            
                            if nagModeTone == option {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.themeAccent)
                            } else {
                                Circle()
                                    .stroke(Color.themeSecondary.opacity(0.4), lineWidth: 1)
                                    .frame(width: 22, height: 22)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    if option != toneOptions.last {
                        Divider()
                    }
                }
            }
            
            Button(action: {
                showingTonePreview = true
            }) {
                Text("Preview Tone")
                    .font(.appSubheadline)
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color.themeAccent)
                    .cornerRadius(10)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.themeCard)
                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        )
    }
    
    private var inAppNagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("In-App Reminders")
                .font(.appTitle3)
                .foregroundColor(.themePrimary)
            
            Toggle("Show visual reminders inside the app", isOn: $nagModeInAppNags)
                .tint(.themeAccent)
            
            Text("You'll see banners and other visual cues when you haven't logged anything.")
                .font(.appCaption)
                .foregroundColor(.themeSecondary)
                .padding(.top, 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.themeCard)
                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        )
    }
    
    private var buddyModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Buddy Mode")
                .font(.appTitle3)
                .foregroundColor(.themePrimary)
            
            Text("Give your nag buddy a name for personalized messages")
                .font(.appCaption)
                .foregroundColor(.themeSecondary)
            
            HStack {
                if isEditingBuddyName {
                    TextField("Enter name", text: $tempBuddyName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .submitLabel(.done)
                        .onSubmit {
                            isEditingBuddyName = false
                            nagModeBuddyName = tempBuddyName
                        }
                } else {
                    Text(nagModeBuddyName.isEmpty ? "Not set" : nagModeBuddyName)
                        .foregroundColor(nagModeBuddyName.isEmpty ? .themeSecondary : .themePrimary)
                    
                    Spacer()
                }
                
                Button(action: {
                    if isEditingBuddyName {
                        isEditingBuddyName = false
                        nagModeBuddyName = tempBuddyName
                    } else {
                        isEditingBuddyName = true
                    }
                }) {
                    Text(isEditingBuddyName ? "Done" : "Edit")
                        .foregroundColor(.themeAccent)
                }
            }
            
            if !nagModeBuddyName.isEmpty {
                Text("Example: \"\(nagModeBuddyName) says: Time to log that task!\"")
                    .font(.appCaption)
                    .foregroundColor(.themeSecondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.themeCard)
                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        )
    }
    
    private var nagJournalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nag Journal")
                .font(.appTitle3)
                .foregroundColor(.themePrimary)
            
            Toggle("Show activity in Today view", isOn: $nagModeShowJournal)
                .tint(.themeAccent)
            
            Text("Display how often Nag Mode had to remind you and your response history.")
                .font(.appCaption)
                .foregroundColor(.themeSecondary)
                .padding(.top, 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.themeCard)
                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        )
    }
    
    private var nagModePreviewSheet: some View {
        VStack(spacing: 20) {
            Text("Nag Mode: \(nagModeTone) Tone")
                .font(.appTitle)
                .foregroundColor(.themePrimary)
                .padding(.top, 40)
            
            Text("Here's how your reminders will sound:")
                .font(.appSubheadline)
                .foregroundColor(.themeSecondary)
            
            VStack(spacing: 16) {
                ForEach(previewMessages[nagModeTone] ?? [""], id: \.self) { message in
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.themeAccent)
                            .font(.system(size: 18))
                        
                        Text(formatPreviewMessage(message))
                            .foregroundColor(.themePrimary)
                            .padding(.leading, 4)
                        
                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.themeCard)
                    )
                    .padding(.horizontal)
                }
            }
            
            Spacer()
            
            Button {
                showingTonePreview = false
            } label: {
                Text("Done")
                    .font(.appHeadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.themeAccent)
                    .cornerRadius(16)
                    .padding(.horizontal, 40)
            }
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatHour(_ hour: Int) -> String {
        let hourValue = hour > 12 ? hour - 12 : hour
        let amPm = hour >= 12 ? "PM" : "AM"
        return "\(hourValue):00 \(amPm)"
    }
    
    private func getIntensityDescription() -> String {
        switch nagModeIntensity {
        case "Gentle":
            return "One reminder per day if you haven't logged anything."
        case "Persistent":
            return "Hourly reminders until you log something."
        case "Beast Mode":
            return "Reminders every 30 minutes plus visual banners in the app."
        default:
            return ""
        }
    }
    
    private func formatPreviewMessage(_ message: String) -> String {
        if !nagModeBuddyName.isEmpty {
            return "\(nagModeBuddyName) says: \(message)"
        }
        return message
    }
}

// MARK: - Preview
#Preview {
    NagModeSettingsView()
} 