//
//  DSRemoteImage.swift
//
//  Remote image with a cache, built only on the system so the package has no
//  dependencies: a memory cache, URLSession's disk cache, and images decoded
//  at the size they are shown (not full size), off the main thread. Shows the
//  placeholder while loading and if loading fails. A project already using
//  an image library can keep it; this is the default.
//
//  Requests that need extra headers (for example an `Origin` header for the
//  app's own API) set them once with
//  `.environment(\.dsImageRequestHeaders, ["Origin": …])`.
//

import ImageIO
import SwiftUI
import UIKit

/// A remote image, cached and decoded at display size.
public struct DSRemoteImage<Placeholder: View>: View {
    private let url: URL?
    private let contentMode: ContentMode
    private let accessibilityLabel: String?
    private let placeholder: Placeholder

    @State private var image: UIImage?
    @Environment(\.displayScale) private var displayScale
    @Environment(\.dsImageRequestHeaders) private var headers

    /// `accessibilityLabel` describes the image for VoiceOver; leave it `nil`
    /// for decorative images.
    public init(
        url: URL?,
        contentMode: ContentMode = .fill,
        accessibilityLabel: String? = nil,
        @ViewBuilder placeholder: () -> Placeholder
    ) {
        self.url = url
        self.contentMode = contentMode
        self.accessibilityLabel = accessibilityLabel
        self.placeholder = placeholder()
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .transition(.opacity)
                } else {
                    placeholder
                        .frame(width: proxy.size.width, height: proxy.size.height)
                }
            }
            .task(id: LoadKey(url: url, pixels: maxPixels(for: proxy.size))) {
                await load(pixels: maxPixels(for: proxy.size))
            }
        }
        .clipped()
        // The photo is measured before it's cropped, so VoiceOver gets its own
        // element sized to the visible frame.
        .accessibilityHidden(true)
        .overlay {
            if let accessibilityLabel {
                Color.clear
                    .accessibilityElement()
                    .accessibilityLabel(accessibilityLabel)
                    .accessibilityAddTraits(.isImage)
            }
        }
    }

    private struct LoadKey: Equatable {
        let url: URL?
        let pixels: Int
    }

    /// The longest side in pixels, rounded up to a 100 px step so small
    /// layout changes reuse the cached image.
    private func maxPixels(for size: CGSize) -> Int {
        let pixels = max(size.width, size.height) * displayScale
        return Int((pixels / 100).rounded(.up) * 100)
    }

    private func load(pixels: Int) async {
        guard let url, pixels > 0 else { return }
        let loaded = await DSImagePipeline.shared.image(for: url, maxPixels: pixels, headers: headers)
        guard !Task.isCancelled else { return }
        withAnimation(DesignSystem.Motion.enter) { image = loaded }
    }
}

public extension DSRemoteImage where Placeholder == DSImagePlaceholder {
    /// A remote image with the standard placeholder.
    init(url: URL?, contentMode: ContentMode = .fill, accessibilityLabel: String? = nil) {
        self.init(url: url, contentMode: contentMode, accessibilityLabel: accessibilityLabel) {
            DSImagePlaceholder()
        }
    }
}

/// The standard image placeholder: a soft fill with a photo symbol.
public struct DSImagePlaceholder: View {
    @Environment(\.theme) private var theme

    public init() {}

    public var body: some View {
        theme.surfacePressed
            .overlay {
                Image(systemName: "photo")
                    .textRole(.title3)
                    .foregroundStyle(theme.labelTertiary)
            }
    }
}

private struct ImageRequestHeadersKey: EnvironmentKey {
    static let defaultValue: [String: String] = [:]
}

public extension EnvironmentValues {
    /// Extra HTTP headers for `DSRemoteImage` requests.
    var dsImageRequestHeaders: [String: String] {
        get { self[ImageRequestHeadersKey.self] }
        set { self[ImageRequestHeadersKey.self] = newValue }
    }
}

/// Downloads, caches and decodes images off the main thread.
actor DSImagePipeline {
    static let shared = DSImagePipeline()

    private let memory = NSCache<NSString, UIImage>()
    private let session: URLSession

    private init() {
        memory.totalCostLimit = 50 * 1024 * 1024
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(
            memoryCapacity: 10 * 1024 * 1024,
            diskCapacity: 200 * 1024 * 1024,
            diskPath: "DSRemoteImage"
        )
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        session = URLSession(configuration: configuration)
    }

    func image(for url: URL, maxPixels: Int, headers: [String: String]) async -> UIImage? {
        let key = "\(url.absoluteString)#\(maxPixels)" as NSString
        if let cached = memory.object(forKey: key) { return cached }

        var request = URLRequest(url: url)
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        guard let (data, response) = try? await session.data(for: request),
              (response as? HTTPURLResponse).map({ (200..<300).contains($0.statusCode) }) ?? true,
              let image = Self.downsample(data, maxPixels: maxPixels)
        else { return nil }

        let cost = Int(image.size.width * image.size.height * image.scale * image.scale * 4)
        memory.setObject(image, forKey: key, cost: cost)
        return image
    }

    /// Decodes straight to the display size, so a large photo never sits in
    /// memory at full resolution.
    private static func downsample(_ data: Data, maxPixels: Int) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else { return nil }
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixels,
        ] as CFDictionary
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

#Preview {
    VStack(spacing: DesignSystem.Spacing.standard.groupGap) {
        DSRemoteImage(url: URL(string: "https://picsum.photos/id/1018/1200/800"), accessibilityLabel: "Mountains")
            .frame(height: 200)
            .clipShape(DesignSystem.Radius.shape(16))
        DSRemoteImage(url: URL(string: "https://example.invalid/missing.jpg"))
            .frame(height: 120)
            .clipShape(DesignSystem.Radius.shape(16))
    }
    .screenMargins()
}
