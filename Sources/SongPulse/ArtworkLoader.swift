import AppKit

protocol DataFetching {
    func data(from url: URL) async throws -> Data
}

struct URLSessionFetcher: DataFetching {
    func data(from url: URL) async throws -> Data {
        try await URLSession.shared.data(from: url).0
    }
}

@MainActor
final class ArtworkLoader {
    private let fetcher: DataFetching
    private let capacity: Int
    private var cache: [URL: NSImage] = [:]
    private var order: [URL] = []

    init(fetcher: DataFetching = URLSessionFetcher(), capacity: Int = 20) {
        self.fetcher = fetcher
        self.capacity = capacity
    }

    func image(for url: URL) async -> NSImage? {
        if let cached = cache[url] { return cached }
        guard let data = try? await fetcher.data(from: url),
              let image = NSImage(data: data) else { return nil }
        cache[url] = image
        order.append(url)
        while order.count > capacity {
            cache.removeValue(forKey: order.removeFirst())
        }
        return image
    }
}

extension NSImage {
    func rounded(size: NSSize, radius: CGFloat) -> NSImage {
        NSImage(size: size, flipped: false) { rect in
            NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).addClip()
            self.draw(in: rect)
            return true
        }
    }
}
