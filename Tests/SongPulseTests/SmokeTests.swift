import XCTest
@testable import SongPulse

final class SmokeTests: XCTestCase {
    @MainActor
    func testAppDelegateInstantiates() {
        XCTAssertNotNil(AppDelegate())
    }
}
