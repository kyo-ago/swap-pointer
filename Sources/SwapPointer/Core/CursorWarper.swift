import CoreGraphics
import Foundation

/// Handles warping the mouse cursor to a target position.
@MainActor
enum CursorWarper {
    /// Warp the cursor to the given position instantly.
    static func warp(to point: CGPoint) {
        CGWarpMouseCursorPosition(point)
        // Re-associate the mouse with the new position to prevent delta accumulation
        CGAssociateMouseAndMouseCursorPosition(1)
    }

    /// Get the current cursor position.
    static var currentPosition: CGPoint {
        NSEvent.mouseLocation.flippedForCG
    }
}

import AppKit

extension NSPoint {
    /// Convert from AppKit's bottom-left origin to CoreGraphics' top-left origin.
    @MainActor
    var flippedForCG: CGPoint {
        guard let screen = NSScreen.main else { return self }
        return CGPoint(x: x, y: screen.frame.height - y)
    }
}
