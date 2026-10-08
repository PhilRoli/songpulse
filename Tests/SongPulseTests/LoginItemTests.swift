import XCTest
@testable import SongPulse

@MainActor
final class LoginItemTests: XCTestCase {
    final class FakeManager: LoginItemManaging {
        var isEnabled = false
        var shouldThrow = false
        func register() throws {
            if shouldThrow { throw URLError(.unknown) }
            isEnabled = true
        }
        func unregister() throws {
            if shouldThrow { throw URLError(.unknown) }
            isEnabled = false
        }
    }

    func testEnableDisable() {
        let manager = FakeManager()
        let controller = LoginItemController(manager: manager)
        XCTAssertTrue(controller.setEnabled(true))
        XCTAssertTrue(controller.isEnabled)
        XCTAssertTrue(controller.setEnabled(false))
        XCTAssertFalse(controller.isEnabled)
    }

    func testFailureReturnsFalse() {
        let manager = FakeManager()
        manager.shouldThrow = true
        XCTAssertFalse(LoginItemController(manager: manager).setEnabled(true))
    }
}
