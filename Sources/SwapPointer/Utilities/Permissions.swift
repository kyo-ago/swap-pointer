import AppKit
import Foundation

/// Manages checking and requesting macOS permissions required by SwapPointer.
final class PermissionManager {
    static let shared = PermissionManager()

    private init() {}

    /// Check if Accessibility permission is granted.
    var isAccessibilityGranted: Bool {
        AXIsProcessTrustedWithOptions(
            [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): false] as CFDictionary
        )
    }

    /// Request Accessibility permission (shows system prompt if not granted).
    func requestAccessibility() {
        AXIsProcessTrustedWithOptions(
            [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        )
    }

    /// Request all necessary permissions, showing guidance if not granted.
    func requestPermissionsIfNeeded() {
        if !isAccessibilityGranted {
            requestAccessibility()
            showPermissionGuidance()
        }
    }

    private func showPermissionGuidance() {
        let alert = NSAlert()
        alert.messageText = "SwapPointer Needs Permissions"
        alert.informativeText = """
            SwapPointer requires Accessibility and Input Monitoring permissions to function.

            1. Open System Settings → Privacy & Security → Accessibility
            2. Enable SwapPointer
            3. Open System Settings → Privacy & Security → Input Monitoring
            4. Enable SwapPointer

            After granting permissions, please restart SwapPointer.
            """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Later")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            openAccessibilitySettings()
        }
    }

    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
