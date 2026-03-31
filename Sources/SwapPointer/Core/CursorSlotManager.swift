import CoreGraphics
import Foundation

/// Manages cursor position slots, one per mouse device.
@MainActor
final class CursorSlotManager {
    /// Stored cursor positions keyed by device ID.
    private var slots: [String: CGPoint] = [:]

    /// The device ID of the currently active slot.
    private(set) var activeDeviceID: String?

    /// Save a cursor position for a device.
    func savePosition(_ position: CGPoint, for deviceID: String) {
        slots[deviceID] = position
    }

    /// Get the saved position for a device, defaulting to screen center.
    func position(for deviceID: String) -> CGPoint {
        if let saved = slots[deviceID] {
            return saved
        }
        // Default to primary screen center
        let screenCenter = Self.primaryScreenCenter()
        slots[deviceID] = screenCenter
        return screenCenter
    }

    /// Set the active device ID.
    func setActive(_ deviceID: String) {
        activeDeviceID = deviceID
    }

    /// Get all inactive slot positions (for overlay display).
    func inactiveSlots() -> [(deviceID: String, position: CGPoint)] {
        slots.compactMap { key, value in
            key == activeDeviceID ? nil : (deviceID: key, position: value)
        }
    }

    /// Remove a slot when a device is disconnected.
    func removeSlot(for deviceID: String) {
        slots.removeValue(forKey: deviceID)
        if activeDeviceID == deviceID {
            activeDeviceID = slots.keys.first
        }
    }

    /// Get all device IDs with slots, in order.
    var allDeviceIDs: [String] {
        Array(slots.keys.sorted())
    }

    /// Get the next device ID after the current active one (for cycling).
    func nextDeviceID(after currentID: String, allDeviceIDs deviceIDs: [String]) -> String? {
        guard let currentIndex = deviceIDs.firstIndex(of: currentID) else {
            return deviceIDs.first
        }
        let nextIndex = (currentIndex + 1) % deviceIDs.count
        return deviceIDs[nextIndex]
    }

    private static func primaryScreenCenter() -> CGPoint {
        if let screen = NSScreen.main {
            let frame = screen.frame
            return CGPoint(x: frame.midX, y: frame.midY)
        }
        return CGPoint(x: 500, y: 400)
    }
}

// NSScreen is in AppKit, import it for screen info
import AppKit
