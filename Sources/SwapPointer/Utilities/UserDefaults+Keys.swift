import Foundation

extension UserDefaults {
    /// Shared UserDefaults instance for SwapPointer settings.
    static let swapPointer = UserDefaults.standard

    // MARK: - Auto-Detection

    private static let autoSwitchThresholdKey = "SwapPointer.autoSwitchThreshold"
    private static let autoDetectEnabledKey = "SwapPointer.autoDetectEnabled"

    var autoSwitchThreshold: Double {
        get {
            let value = double(forKey: Self.autoSwitchThresholdKey)
            return value > 0 ? value : 15.0  // Default: 15 pixels
        }
        set { set(newValue, forKey: Self.autoSwitchThresholdKey) }
    }

    var autoDetectEnabled: Bool {
        get {
            if object(forKey: Self.autoDetectEnabledKey) == nil {
                return true  // Default: enabled
            }
            return bool(forKey: Self.autoDetectEnabledKey)
        }
        set { set(newValue, forKey: Self.autoDetectEnabledKey) }
    }

    // MARK: - Visual Settings

    private static let showDormantCursorsKey = "SwapPointer.showDormantCursors"
    private static let dormantCursorOpacityKey = "SwapPointer.dormantCursorOpacity"
    private static let showWarpAnimationKey = "SwapPointer.showWarpAnimation"

    var showDormantCursors: Bool {
        get {
            if object(forKey: Self.showDormantCursorsKey) == nil {
                return true  // Default: enabled
            }
            return bool(forKey: Self.showDormantCursorsKey)
        }
        set { set(newValue, forKey: Self.showDormantCursorsKey) }
    }

    var dormantCursorOpacity: Double {
        get {
            let value = double(forKey: Self.dormantCursorOpacityKey)
            return value > 0 ? value : 0.5  // Default: 50%
        }
        set { set(newValue, forKey: Self.dormantCursorOpacityKey) }
    }

    var showWarpAnimation: Bool {
        get {
            if object(forKey: Self.showWarpAnimationKey) == nil {
                return true  // Default: enabled
            }
            return bool(forKey: Self.showWarpAnimationKey)
        }
        set { set(newValue, forKey: Self.showWarpAnimationKey) }
    }

    // MARK: - Login Item

    private static let launchAtLoginKey = "SwapPointer.launchAtLogin"

    var launchAtLogin: Bool {
        get { bool(forKey: Self.launchAtLoginKey) }
        set { set(newValue, forKey: Self.launchAtLoginKey) }
    }
}
