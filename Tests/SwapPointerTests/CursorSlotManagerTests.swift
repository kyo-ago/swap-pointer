import Testing
@testable import SwapPointer

@Suite("CursorSlotManager Tests")
@MainActor
struct CursorSlotManagerTests {
    @Test("Save and retrieve position")
    func saveAndRetrievePosition() {
        let manager = CursorSlotManager()
        let point = CGPoint(x: 100, y: 200)
        manager.savePosition(point, for: "device-1")
        let retrieved = manager.position(for: "device-1")
        #expect(retrieved.x == 100)
        #expect(retrieved.y == 200)
    }

    @Test("Default position for unknown device")
    func defaultPosition() {
        let manager = CursorSlotManager()
        let pos = manager.position(for: "unknown-device")
        // Should return some default (screen center or fallback)
        #expect(pos.x >= 0)
        #expect(pos.y >= 0)
    }

    @Test("Active device tracking")
    func activeDeviceTracking() {
        let manager = CursorSlotManager()
        manager.savePosition(.zero, for: "dev-a")
        manager.savePosition(.zero, for: "dev-b")
        manager.setActive("dev-a")
        #expect(manager.activeDeviceID == "dev-a")
        manager.setActive("dev-b")
        #expect(manager.activeDeviceID == "dev-b")
    }

    @Test("Inactive slots excludes active device")
    func inactiveSlotsExcludeActive() {
        let manager = CursorSlotManager()
        manager.savePosition(CGPoint(x: 10, y: 20), for: "dev-a")
        manager.savePosition(CGPoint(x: 30, y: 40), for: "dev-b")
        manager.setActive("dev-a")
        let inactive = manager.inactiveSlots()
        #expect(inactive.count == 1)
        #expect(inactive[0].deviceID == "dev-b")
    }

    @Test("Next device cycles correctly")
    func nextDeviceCycling() {
        let manager = CursorSlotManager()
        let ids = ["a", "b", "c"]
        #expect(manager.nextDeviceID(after: "a", allDeviceIDs: ids) == "b")
        #expect(manager.nextDeviceID(after: "b", allDeviceIDs: ids) == "c")
        #expect(manager.nextDeviceID(after: "c", allDeviceIDs: ids) == "a")
    }

    @Test("Remove slot")
    func removeSlot() {
        let manager = CursorSlotManager()
        manager.savePosition(.zero, for: "dev-a")
        manager.savePosition(.zero, for: "dev-b")
        manager.setActive("dev-a")
        manager.removeSlot(for: "dev-a")
        #expect(manager.activeDeviceID == "dev-b")
    }
}
