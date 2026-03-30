import SwiftUI

struct SettingsView: View {
    let hidDeviceManager: HIDDeviceManager
    let cursorSlotManager: CursorSlotManager
    let switchTriggerManager: SwitchTriggerManager

    var body: some View {
        TabView {
            DeviceListView(hidDeviceManager: hidDeviceManager)
                .tabItem {
                    Label("Devices", systemImage: "computermouse")
                }

            HotkeySettingsView()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }

            AppearanceSettingsView()
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }

            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
        }
        .frame(width: 480, height: 380)
        .padding()
    }
}

struct GeneralSettingsView: View {
    @State private var launchAtLogin = LoginItemManager.isEnabled
    @State private var autoDetectEnabled = UserDefaults.swapPointer.autoDetectEnabled
    @State private var autoSwitchThreshold = UserDefaults.swapPointer.autoSwitchThreshold

    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        LoginItemManager.setEnabled(newValue)
                    }
            }

            Section("Auto-Detection") {
                Toggle("Automatically switch when another mouse moves", isOn: $autoDetectEnabled)
                    .onChange(of: autoDetectEnabled) { _, newValue in
                        UserDefaults.swapPointer.autoDetectEnabled = newValue
                    }

                if autoDetectEnabled {
                    VStack(alignment: .leading) {
                        Text("Sensitivity threshold: \(Int(autoSwitchThreshold)) px")
                        Slider(value: $autoSwitchThreshold, in: 5...50, step: 1) {
                            Text("Threshold")
                        }
                        .onChange(of: autoSwitchThreshold) { _, newValue in
                            UserDefaults.swapPointer.autoSwitchThreshold = newValue
                        }
                        Text("Lower values = more sensitive. Higher values = less accidental switching.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}
