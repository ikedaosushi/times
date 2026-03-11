import SwiftUI

private nonisolated(unsafe) let imageCache: NSCache<NSString, UIImage> = {
    let cache = NSCache<NSString, UIImage>()
    cache.countLimit = 100
    cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    return cache
}()

@MainActor
func cachedSwiftUIImage(from data: Data, cacheKey: String) -> Image? {
    let key = NSString(string: cacheKey)
    if let cached = imageCache.object(forKey: key) {
        return Image(uiImage: cached)
    }
    guard let uiImage = UIImage(data: data) else { return nil }
    imageCache.setObject(uiImage, forKey: key, cost: data.count)
    return Image(uiImage: uiImage)
}
