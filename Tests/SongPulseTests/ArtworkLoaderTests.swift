import AppKit
import XCTest
@testable import SongPulse

@MainActor
final class ArtworkLoaderTests: XCTestCase {
    final class FakeFetcher: DataFetching {
        var result: Result<Data, Error> = .success(Data())
        private(set) var calls = 0
        func data(from url: URL) async throws -> Data {
            calls += 1
            return try result.get()
        }
    }

    private func pngData() -> Data {
        let image = NSImage(size: NSSize(width: 4, height: 4), flipped: false) { rect in
            NSColor.red.setFill()
            rect.fill()
            return true
        }
        let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
        return rep.representation(using: .png, properties: [:])!
    }

    private let url = URL(string: "https://i.scdn.co/image/a")!

    func testSuccessIsCachedByURL() async {
        let fetcher = FakeFetcher()
        fetcher.result = .success(pngData())
        let loader = ArtworkLoader(fetcher: fetcher)
        let first = await loader.image(for: url)
        let second = await loader.image(for: url)
        XCTAssertNotNil(first)
        XCTAssertNotNil(second)
        XCTAssertEqual(fetcher.calls, 1)
    }

    func testFetchFailureReturnsNilAndIsNotCached() async {
        let fetcher = FakeFetcher()
        fetcher.result = .failure(URLError(.notConnectedToInternet))
        let loader = ArtworkLoader(fetcher: fetcher)
        let failed = await loader.image(for: url)
        XCTAssertNil(failed)
        fetcher.result = .success(pngData())
        let retried = await loader.image(for: url)
        XCTAssertNotNil(retried)
        XCTAssertEqual(fetcher.calls, 2)
    }

    func testNonImageDataReturnsNil() async {
        let fetcher = FakeFetcher()
        fetcher.result = .success(Data("not an image".utf8))
        let image = await ArtworkLoader(fetcher: fetcher).image(for: url)
        XCTAssertNil(image)
    }

    func testEvictsOldestBeyondCapacity() async {
        let fetcher = FakeFetcher()
        fetcher.result = .success(pngData())
        let loader = ArtworkLoader(fetcher: fetcher, capacity: 1)
        let other = URL(string: "https://i.scdn.co/image/b")!
        _ = await loader.image(for: url)
        _ = await loader.image(for: other)
        _ = await loader.image(for: url)
        XCTAssertEqual(fetcher.calls, 3)
    }

    func testRoundedProducesRequestedSize() {
        let image = NSImage(size: NSSize(width: 100, height: 100))
        let rounded = image.rounded(size: NSSize(width: 18, height: 18), radius: 4)
        XCTAssertEqual(rounded.size, NSSize(width: 18, height: 18))
    }
}
