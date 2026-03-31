import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var hidDeviceManager: HIDDeviceManager!
    private var cursorSlotManager: CursorSlotManager!
    private var eventTapManager: EventTapManager!
    private var switchTriggerManager: SwitchTriggerManager!
    private var overlayManager: CursorOverlayManager!
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)

        setupStatusItem()
        setupManagers()

        // Check permissions on launch
        PermissionManager.shared.requestPermissionsIfNeeded()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "cursorarrow.click.2", accessibilityDescription: "SwapPointer")
            button.image?.size = NSSize(width: 18, height: 18)
        }
        statusItem.menu = buildMenu()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "SwapPointer", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        let devicesItem = NSMenuItem(title: "Devices", action: nil, keyEquivalent: "")
        devicesItem.submenu = buildDevicesSubmenu()
        menu.addItem(devicesItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit SwapPointer", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        return menu
    }

    private func buildDevicesSubmenu() -> NSMenu {
        let submenu = NSMenu()
        let devices = hidDeviceManager?.connectedDevices ?? []
        if devices.isEmpty {
            submenu.addItem(NSMenuItem(title: "No mice detected", action: nil, keyEquivalent: ""))
        } else {
            for device in devices {
                let title = "\(device.name) (Slot \(device.slotIndex + 1))"
                let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
                if device.isActive {
                    item.state = .on
                }
                submenu.addItem(item)
            }
        }
        return submenu
    }

    private func setupManagers() {
        cursorSlotManager = CursorSlotManager()
        hidDeviceManager = HIDDeviceManager()
        eventTapManager = EventTapManager()
        overlayManager = CursorOverlayManager()

        switchTriggerManager = SwitchTriggerManager(
            hidDeviceManager: hidDeviceManager,
            cursorSlotManager: cursorSlotManager,
            eventTapManager: eventTapManager,
            overlayManager: overlayManager
        )

        hidDeviceManager.onDevicesChanged = { [weak self] in
            self?.statusItem.menu = self?.buildMenu()
        }

        switchTriggerManager.start()
    }

    @objc private func openSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView(
            hidDeviceManager: hidDeviceManager,
            cursorSlotManager: cursorSlotManager,
            switchTriggerManager: switchTriggerManager
        )

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 460),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "SwapPointer Settings"
        window.contentView = NSHostingView(rootView: settingsView)
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        settingsWindow = window
    }
}
