import SwiftUI
import LaunchAtLogin

struct PreferencesView: View {
    @AppStorage("startAtLogin") private var startAtLogin = false
    @AppStorage("isCompactLayout") private var isCompactLayout = false
    var switchToMainPopover: () -> Void // Closure to switch to main window

    var body: some View {
        Form {
            Toggle("Start at Login", isOn: $startAtLogin)
                .onChange(of: startAtLogin) {
                    LaunchAtLogin.isEnabled = startAtLogin // Use the variable directly
                }

            Toggle("Compact Layout (5 GIFs per row)", isOn: $isCompactLayout)
                .padding(.top)

            // Button to switch back to the main GIF window
            Button("Switch to Main Window") {
                switchToMainPopover()
            }
            .padding(.top)
        }
        .padding()
        .frame(width: 300, height: 200) // Adjust height to fit the new button
        .navigationTitle("Preferences")
    }
}

