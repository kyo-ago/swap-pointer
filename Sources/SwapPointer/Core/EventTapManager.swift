import CoreGraphics
import Foundation

/// Manages a CGEventTap for intercepting and suppressing mouse events.
@MainActor
final class EventTapManager {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    /// When true, mouse move events from non-active devices are suppressed.
    var isSuppressing: Bool = false

    /// Duration to suppress events after a switch (to prevent cursor jump from residual events).
    var suppressionDuration: TimeInterval = 0.05
    private var suppressionEndTime: Date?

    /// Callback invoked for each mouse event. Return nil to suppress.
    var eventFilter: ((CGEvent) -> CGEvent?)?

    init() {}

    deinit {
        stop()
    }

    /// Start the event tap.
    func start() {
        guard eventTap == nil else { return }

        let eventMask: CGEventMask =
            (1 << CGEventType.mouseMoved.rawValue) |
            (1 << CGEventType.leftMouseDragged.rawValue) |
            (1 << CGEventType.rightMouseDragged.rawValue) |
            (1 << CGEventType.otherMouseDragged.rawValue)

        let context = Unmanaged.passUnretained(self).toOpaque()

        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { _, type, event, userInfo -> Unmanaged<CGEvent>? in
                guard let userInfo = userInfo else {
                    return Unmanaged.passUnretained(event)
                }
                return MainActor.assumeIsolated {
                    let this = Unmanaged<EventTapManager>.fromOpaque(userInfo).takeUnretainedValue()
                    return this.handleEvent(type: type, event: event)
                }
            },
            userInfo: context
        )

        guard let tap = eventTap else {
            print("SwapPointer: Failed to create event tap. Accessibility permission may be required.")
            return
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        }

        CGEvent.tapEnable(tap: tap, enable: true)
        print("SwapPointer: Event tap started")
    }

    /// Stop the event tap.
    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    /// Begin temporary event suppression after a cursor switch.
    func beginSuppression() {
        isSuppressing = true
        suppressionEndTime = Date().addingTimeInterval(suppressionDuration)

        DispatchQueue.main.asyncAfter(deadline: .now() + suppressionDuration) { [weak self] in
            self?.isSuppressing = false
            self?.suppressionEndTime = nil
        }
    }

    private func handleEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Re-enable tap if it was disabled by the system
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        // During suppression, block mouse movement events
        if isSuppressing {
            return nil  // Suppress the event
        }

        // Allow custom filtering
        if let filter = eventFilter {
            if let filtered = filter(event) {
                return Unmanaged.passUnretained(filtered)
            }
            return nil  // Suppress
        }

        return Unmanaged.passUnretained(event)
    }
}
