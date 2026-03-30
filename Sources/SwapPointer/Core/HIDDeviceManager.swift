import Foundation
import IOKit
import IOKit.hid

/// Represents a recognized mouse device with its identification info.
struct MouseDevice: Identifiable, Equatable {
    let id: String  // Composite key: vendorID-productID-locationID
    let vendorID: Int
    let productID: Int
    let locationID: Int
    let name: String
    var slotIndex: Int
    var isActive: Bool

    static func == (lhs: MouseDevice, rhs: MouseDevice) -> Bool {
        lhs.id == rhs.id
    }
}

/// Manages IOHIDManager to detect, identify, and receive events from individual mouse devices.
final class HIDDeviceManager {
    private var hidManager: IOHIDManager?
    private(set) var connectedDevices: [MouseDevice] = []
    private var deviceRefs: [IOHIDDevice: String] = [:]  // IOHIDDevice -> device ID

    /// Called when device list changes (connect/disconnect).
    var onDevicesChanged: (() -> Void)?

    /// Called when a specific device generates a mouse movement event.
    /// Parameters: deviceID, deltaX, deltaY
    var onMouseMoved: ((String, Int, Int) -> Void)?

    init() {
        setupHIDManager()
    }

    deinit {
        if let manager = hidManager {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        }
    }

    private func setupHIDManager() {
        hidManager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        guard let manager = hidManager else { return }

        // Match mouse and pointing devices
        let matchingCriteria: [[String: Any]] = [
            [kIOHIDDeviceUsagePageKey as String: kHIDPage_GenericDesktop,
             kIOHIDDeviceUsageKey as String: kHIDUsage_GD_Mouse],
            [kIOHIDDeviceUsagePageKey as String: kHIDPage_GenericDesktop,
             kIOHIDDeviceUsageKey as String: kHIDUsage_GD_Pointer],
        ]

        IOHIDManagerSetDeviceMatchingMultiple(manager, matchingCriteria as CFArray)

        let context = Unmanaged.passUnretained(self).toOpaque()

        IOHIDManagerRegisterDeviceMatchingCallback(manager, { context, _, _, device in
            let this = Unmanaged<HIDDeviceManager>.fromOpaque(context!).takeUnretainedValue()
            this.handleDeviceConnected(device)
        }, context)

        IOHIDManagerRegisterDeviceRemovalCallback(manager, { context, _, _, device in
            let this = Unmanaged<HIDDeviceManager>.fromOpaque(context!).takeUnretainedValue()
            this.handleDeviceDisconnected(device)
        }, context)

        IOHIDManagerRegisterInputValueCallback(manager, { context, _, value in
            let this = Unmanaged<HIDDeviceManager>.fromOpaque(context!).takeUnretainedValue()
            this.handleInputValue(value)
        }, context)

        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)

        let result = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        if result != kIOReturnSuccess {
            print("SwapPointer: Failed to open IOHIDManager: \(result)")
        }
    }

    private func handleDeviceConnected(_ device: IOHIDDevice) {
        let vendorID = IOHIDDeviceGetProperty(device, kIOHIDVendorIDKey as CFString) as? Int ?? 0
        let productID = IOHIDDeviceGetProperty(device, kIOHIDProductIDKey as CFString) as? Int ?? 0
        let locationID = IOHIDDeviceGetProperty(device, kIOHIDLocationIDKey as CFString) as? Int ?? 0
        let name = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as? String ?? "Unknown Mouse"

        let deviceID = "\(vendorID)-\(productID)-\(locationID)"

        // Skip if already tracked
        guard !connectedDevices.contains(where: { $0.id == deviceID }) else { return }

        let slotIndex = connectedDevices.count
        let isActive = slotIndex == 0  // First device is active by default
        let mouseDevice = MouseDevice(
            id: deviceID,
            vendorID: vendorID,
            productID: productID,
            locationID: locationID,
            name: name,
            slotIndex: slotIndex,
            isActive: isActive
        )

        connectedDevices.append(mouseDevice)
        deviceRefs[device] = deviceID

        print("SwapPointer: Device connected: \(name) [\(deviceID)] -> Slot \(slotIndex)")
        onDevicesChanged?()
    }

    private func handleDeviceDisconnected(_ device: IOHIDDevice) {
        guard let deviceID = deviceRefs.removeValue(forKey: device) else { return }
        connectedDevices.removeAll { $0.id == deviceID }

        // Reassign slot indices
        for i in connectedDevices.indices {
            connectedDevices[i].slotIndex = i
        }

        print("SwapPointer: Device disconnected: \(deviceID)")
        onDevicesChanged?()
    }

    private func handleInputValue(_ value: IOHIDValue) {
        let element = IOHIDValueGetElement(value)
        let usagePage = IOHIDElementGetUsagePage(element)
        let usage = IOHIDElementGetUsage(element)

        // Only process GenericDesktop X/Y axis movements
        guard usagePage == kHIDPage_GenericDesktop else { return }
        guard usage == kHIDUsage_GD_X || usage == kHIDUsage_GD_Y else { return }

        let device = IOHIDElementGetDevice(element)
        guard let deviceID = deviceRefs[device] else { return }

        let intValue = IOHIDValueGetIntegerValue(value)

        if usage == kHIDUsage_GD_X {
            onMouseMoved?(deviceID, intValue, 0)
        } else {
            onMouseMoved?(deviceID, 0, intValue)
        }
    }

    /// Mark a device as the active one.
    func setActiveDevice(_ deviceID: String) {
        for i in connectedDevices.indices {
            connectedDevices[i].isActive = (connectedDevices[i].id == deviceID)
        }
    }

    /// Get the currently active device.
    var activeDevice: MouseDevice? {
        connectedDevices.first(where: { $0.isActive })
    }

    /// Find device by ID.
    func device(for id: String) -> MouseDevice? {
        connectedDevices.first(where: { $0.id == id })
    }
}
