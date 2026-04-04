import Carbon
import CoreGraphics
import Foundation

/// Integrates both hotkey-based and auto-detection-based cursor slot switching.
@MainActor
final class SwitchTriggerManager {
    private let hidDeviceManager: HIDDeviceManager
    private let cursorSlotManager: CursorSlotManager
    private let eventTapManager: EventTapManager
    private let overlayManager: CursorOverlayManager

    /// Accumulated movement per device for auto-detection threshold.
    private var movementAccumulator: [String: Double] = [:]
    private var lastMovementTime: [String: Date] = [:]

    /// Movement threshold (in pixels of cumulative delta) to trigger auto-switch.
    var autoSwitchThreshold: Double {
        get { UserDefaults.swapPointer.autoSwitchThreshold }
        set { UserDefaults.swapPointer.autoSwitchThreshold = newValue }
    }

    /// Time window for accumulating movement (seconds).
    var movementTimeWindow: TimeInterval = 0.3

    /// Whether auto-detection is enabled.
    var autoDetectEnabled: Bool {
        get { UserDefaults.swapPointer.autoDetectEnabled }
        set { UserDefaults.swapPointer.autoDetectEnabled = newValue }
    }

    /// Registered hotkey event handler refs.
    private var hotkeyRefs: [EventHotKeyRef] = []

    /// Callback for UI updates after a switch.
    var onSwitch: (() -> Void)?

    init(
        hidDeviceManager: HIDDeviceManager,
        cursorSlotManager: CursorSlotManager,
        eventTapManager: EventTapManager,
        overlayManager: CursorOverlayManager
    ) {
        self.hidDeviceManager = hidDeviceManager
        self.cursorSlotManager = cursorSlotManager
        self.eventTapManager = eventTapManager
        self.overlayManager = overlayManager
    }

    func start() {
        setupHIDCallbacks()
        setupHotkeys()
        eventTapManager.start()
    }

    func stop() {
        eventTapManager.stop()
        unregisterHotkeys()
    }

    // MARK: - Auto-Detection via HID

    private func setupHIDCallbacks() {
        hidDeviceManager.onMouseMoved = { [weak self] deviceID, deltaX, deltaY in
            self?.handleMouseMovement(deviceID: deviceID, deltaX: deltaX, deltaY: deltaY)
        }
    }

    private func handleMouseMovement(deviceID: String, deltaX: Int, deltaY: Int) {
        guard autoDetectEnabled else { return }

        let activeID = cursorSlotManager.activeDeviceID

        // If this is the active device, no switch needed
        if deviceID == activeID { return }

        // Accumulate movement for the non-active device
        let now = Date()
        if let lastTime = lastMovementTime[deviceID],
           now.timeIntervalSince(lastTime) > movementTimeWindow {
            // Reset accumulator if too much time has passed
            movementAccumulator[deviceID] = 0
        }

        let delta = sqrt(Double(deltaX * deltaX + deltaY * deltaY))
        movementAccumulator[deviceID, default: 0] += delta
        lastMovementTime[deviceID] = now

        // Check threshold
        if (movementAccumulator[deviceID] ?? 0) >= autoSwitchThreshold {
            movementAccumulator[deviceID] = 0
            performSwitch(to: deviceID)
        }
    }

    // MARK: - Hotkey-Based Switching

    private func setupHotkeys() {
        // Install Carbon event handler for hotkeys
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let handler: EventHandlerUPP = { _, event, userData -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }

            var hotkeyID = EventHotKeyID()
            GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotkeyID
            )

            MainActor.assumeIsolated {
                let this = Unmanaged<SwitchTriggerManager>.fromOpaque(userData).takeUnretainedValue()
                this.handleHotkeyPressed(id: Int(hotkeyID.id))
            }
            return noErr
        }

        let context = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventType, context, nil)

        registerDefaultHotkeys()
    }

    private func registerDefaultHotkeys() {
        unregisterHotkeys()

        // Ctrl+Option+Tab = cycle to next slot (ID 0)
        registerHotkey(
            id: 0,
            keyCode: UInt32(kVK_Tab),
            modifiers: UInt32(controlKey | optionKey)
        )

        // Ctrl+Option+1 = slot 1 (ID 1)
        registerHotkey(
            id: 1,
            keyCode: UInt32(kVK_ANSI_1),
            modifiers: UInt32(controlKey | optionKey)
        )

        // Ctrl+Option+2 = slot 2 (ID 2)
        registerHotkey(
            id: 2,
            keyCode: UInt32(kVK_ANSI_2),
            modifiers: UInt32(controlKey | optionKey)
        )

        // Ctrl+Option+3 = slot 3 (ID 3)
        registerHotkey(
            id: 3,
            keyCode: UInt32(kVK_ANSI_3),
            modifiers: UInt32(controlKey | optionKey)
        )
    }

    private func registerHotkey(id: Int, keyCode: UInt32, modifiers: UInt32) {
        let hotkeyID = EventHotKeyID(signature: OSType(0x5350_5452), id: UInt32(id))  // 'SPTR'
        var hotkeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(keyCode, modifiers, hotkeyID, GetApplicationEventTarget(), 0, &hotkeyRef)
        if status == noErr, let ref = hotkeyRef {
            hotkeyRefs.append(ref)
        }
    }

    private func unregisterHotkeys() {
        for ref in hotkeyRefs {
            UnregisterEventHotKey(ref)
        }
        hotkeyRefs.removeAll()
    }

    private func handleHotkeyPressed(id: Int) {
        let deviceIDs = hidDeviceManager.connectedDevices.map(\.id)
        guard !deviceIDs.isEmpty else { return }

        if id == 0 {
            // Cycle to next
            if let activeID = cursorSlotManager.activeDeviceID,
               let nextID = cursorSlotManager.nextDeviceID(after: activeID, allDeviceIDs: deviceIDs) {
                performSwitch(to: nextID)
            }
        } else {
            // Switch to specific slot (1-indexed)
            let slotIndex = id - 1
            if slotIndex < deviceIDs.count {
                performSwitch(to: deviceIDs[slotIndex])
            }
        }
    }

    // MARK: - Switch Execution

    func performSwitch(to targetDeviceID: String) {
        let currentActiveID = cursorSlotManager.activeDeviceID

        // Don't switch to already-active device
        if targetDeviceID == currentActiveID { return }

        // Save current cursor position for the currently active device
        if let activeID = currentActiveID {
            let currentPos = CursorWarper.currentPosition
            cursorSlotManager.savePosition(currentPos, for: activeID)
        }

        // Get target position
        let targetPosition = cursorSlotManager.position(for: targetDeviceID)

        // Begin event suppression to prevent residual movement
        eventTapManager.beginSuppression()

        // Warp cursor
        CursorWarper.warp(to: targetPosition)

        // Update active state
        cursorSlotManager.setActive(targetDeviceID)
        hidDeviceManager.setActiveDevice(targetDeviceID)

        // Update overlay (show dormant cursors, hide active one)
        overlayManager.updateOverlays(slots: cursorSlotManager.inactiveSlots())

        // Show warp animation if enabled
        if UserDefaults.swapPointer.showWarpAnimation {
            overlayManager.showWarpAnimation(at: targetPosition)
        }

        // Reset movement accumulators
        movementAccumulator.removeAll()

        onSwitch?()

        print("SwapPointer: Switched to device \(targetDeviceID) at \(targetPosition)")
    }
}
