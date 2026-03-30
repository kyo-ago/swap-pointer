import SwiftUI

struct HotkeySettingsView: View {
    var body: some View {
        Form {
            Section("Keyboard Shortcuts") {
                HotkeyRow(label: "Cycle to next slot", shortcut: "⌃⌥ Tab")
                HotkeyRow(label: "Switch to Slot 1", shortcut: "⌃⌥ 1")
                HotkeyRow(label: "Switch to Slot 2", shortcut: "⌃⌥ 2")
                HotkeyRow(label: "Switch to Slot 3", shortcut: "⌃⌥ 3")
            }

            Section("Info") {
                Text("Hotkeys work globally and can be used to switch between cursor slots at any time.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

struct HotkeyRow: View {
    let label: String
    let shortcut: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(shortcut)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.15))
                )
        }
    }
}
