import Foundation
import ServiceManagement

/// Manages "launch at login" registration using SMAppService.
enum LoginItemManager {
    /// Register or unregister the app as a login item.
    static func setEnabled(_ enabled: Bool) {
        let service = SMAppService.mainApp
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
            UserDefaults.swapPointer.launchAtLogin = enabled
        } catch {
            print("SwapPointer: Failed to \(enabled ? "register" : "unregister") login item: \(error)")
        }
    }

    /// Check if currently registered.
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }
}
