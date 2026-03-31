import AppKit
import Foundation

/// Manages overlay windows that show dormant cursor positions.
@MainActor
final class CursorOverlayManager {
    private var overlayWindows: [String: NSWindow] = [:]
    private var animationWindow: NSWindow?

    /// Slot colors for distinguishing different cursors.
    private let slotColors: [NSColor] = [
        .systemBlue,
        .systemOrange,
        .systemGreen,
        .systemPurple,
        .systemPink,
    ]

    /// Update overlays to reflect current dormant slot positions.
    func updateOverlays(slots: [(deviceID: String, position: CGPoint)]) {
        guard UserDefaults.swapPointer.showDormantCursors else {
            removeAllOverlays()
            return
        }

        // Remove overlays for devices no longer in the list
        let activeIDs = Set(slots.map(\.deviceID))
        for (id, window) in overlayWindows where !activeIDs.contains(id) {
            window.orderOut(nil)
            overlayWindows.removeValue(forKey: id)
        }

        let opacity = UserDefaults.swapPointer.dormantCursorOpacity

        for (index, slot) in slots.enumerated() {
            let window: NSWindow
            if let existing = overlayWindows[slot.deviceID] {
                window = existing
            } else {
                window = createOverlayWindow()
                overlayWindows[slot.deviceID] = window
            }

            let color = slotColors[index % slotColors.count]
            updateOverlayContent(window: window, color: color, opacity: opacity)

            // Position window centered on the slot position (convert CG coords to screen coords)
            let screenPoint = slot.position.convertedToScreen
            let markerSize: CGFloat = 24
            let origin = NSPoint(
                x: screenPoint.x - markerSize / 2,
                y: screenPoint.y - markerSize / 2
            )
            window.setFrameOrigin(origin)
            window.orderFrontRegardless()
        }
    }

    /// Remove all overlay windows.
    func removeAllOverlays() {
        for (_, window) in overlayWindows {
            window.orderOut(nil)
        }
        overlayWindows.removeAll()
    }

    /// Show a brief warp animation at the given CG point.
    func showWarpAnimation(at cgPoint: CGPoint) {
        let screenPoint = cgPoint.convertedToScreen
        let size: CGFloat = 60

        let window = NSWindow(
            contentRect: NSRect(x: screenPoint.x - size / 2, y: screenPoint.y - size / 2, width: size, height: size),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .screenSaver
        window.ignoresMouseEvents = true
        window.hasShadow = false

        let animView = WarpAnimationView(frame: NSRect(x: 0, y: 0, width: size, height: size))
        window.contentView = animView
        window.orderFrontRegardless()

        animationWindow = window
        animView.startAnimation { [weak self] in
            window.orderOut(nil)
            self?.animationWindow = nil
        }
    }

    // MARK: - Private

    private func createOverlayWindow() -> NSWindow {
        let markerSize: CGFloat = 24
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: markerSize, height: markerSize),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .screenSaver
        window.ignoresMouseEvents = true
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        return window
    }

    private func updateOverlayContent(window: NSWindow, color: NSColor, opacity: Double) {
        let size = window.frame.size
        let view = NSView(frame: NSRect(origin: .zero, size: size))

        let circle = CAShapeLayer()
        circle.path = CGPath(ellipseIn: NSRect(origin: .zero, size: size), transform: nil)
        circle.fillColor = color.withAlphaComponent(opacity).cgColor
        circle.strokeColor = color.withAlphaComponent(min(opacity + 0.3, 1.0)).cgColor
        circle.lineWidth = 2

        view.wantsLayer = true
        view.layer?.addSublayer(circle)

        // Add a small cursor icon in the center
        let cursorLayer = CATextLayer()
        cursorLayer.string = "↖"
        cursorLayer.fontSize = 14
        cursorLayer.alignmentMode = .center
        cursorLayer.frame = NSRect(origin: .zero, size: size)
        cursorLayer.foregroundColor = NSColor.white.withAlphaComponent(opacity).cgColor
        view.layer?.addSublayer(cursorLayer)

        window.contentView = view
    }
}

extension CGPoint {
    /// Convert from CG coordinate system (top-left origin) to screen coordinate system (bottom-left origin).
    @MainActor
    var convertedToScreen: NSPoint {
        guard let screen = NSScreen.main else { return NSPoint(x: x, y: y) }
        return NSPoint(x: x, y: screen.frame.height - y)
    }
}
