import Foundation
import SwiftUI

// HTML parsing logic - not bound to any actor, safe to call from background threads
private enum OGPParser {
    static let titleRegex = try! NSRegularExpression(pattern: #"<title[^>]*>([^<]+)</title>"#)

    static func metaRegexes(for attr: String, value: String) -> (NSRegularExpression, NSRegularExpression) {
        let pattern1 = #"<meta[^>]+\#(attr)=["']\#(value)["'][^>]+content=["']([^"']+)["']"#
        let pattern2 = #"<meta[^>]+content=["']([^"']+)["'][^>]+\#(attr)=["']\#(value)["']"#
        return (try! NSRegularExpression(pattern: pattern1), try! NSRegularExpression(pattern: pattern2))
    }

    static let ogTitleRegexes = metaRegexes(for: "property", value: "og:title")
    static let ogDescRegexes = metaRegexes(for: "property", value: "og:description")
    static let ogImageRegexes = metaRegexes(for: "property", value: "og:image")
    static let metaDescRegexes = metaRegexes(for: "name", value: "description")

    static func parse(html: String) -> (title: String?, description: String?, imageURL: String?) {
        let title = extractMeta(from: html, using: ogTitleRegexes)
            ?? extractHTMLTitle(from: html)
        let description = extractMeta(from: html, using: ogDescRegexes)
            ?? extractMeta(from: html, using: metaDescRegexes)
        let imageURL = extractMeta(from: html, using: ogImageRegexes)
        return (title, description, imageURL)
    }

    static func extractMeta(from html: String, using regexes: (NSRegularExpression, NSRegularExpression)) -> String? {
        let range = NSRange(html.startIndex..., in: html)
        for regex in [regexes.0, regexes.1] {
            if let match = regex.firstMatch(in: html, range: range) {
                let matchedRange = match.range(at: 1)
                if let swiftRange = Range(matchedRange, in: html) {
                    let value = String(html[swiftRange])
                    return value.isEmpty ? nil : value
                }
            }
        }
        return nil
    }

    static func extractHTMLTitle(from html: String) -> String? {
        let range = NSRange(html.startIndex..., in: html)
        guard let match = titleRegex.firstMatch(in: html, range: range),
              let groupRange = Range(match.range(at: 1), in: html) else { return nil }
        let value = String(html[groupRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}

@MainActor
enum OGPService {
    // OGP result cache to avoid redundant network requests
    private struct OGPResult {
        let title: String?
        let description: String?
        let imageURL: String?
    }
    private static var ogpCache: [URL: OGPResult] = [:]
    private static var inFlightRequests: Set<URL> = []

    static func fetchOGP(for post: Post, url: URL) async {
        // Return cached result if available
        if let cached = ogpCache[url] {
            post.ogpTitle = cached.title
            post.ogpDescription = cached.description
            post.ogpImageURL = cached.imageURL
            return
        }

        // Avoid duplicate in-flight requests for the same URL
        guard !inFlightRequests.contains(url) else { return }
        inFlightRequests.insert(url)
        defer { inFlightRequests.remove(url) }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let html = String(data: data, encoding: .utf8) else { return }

            // Parse HTML off the main thread
            let result = await Task.detached {
                OGPParser.parse(html: html)
            }.value

            let cachedResult = OGPResult(title: result.title, description: result.description, imageURL: result.imageURL)
            ogpCache[url] = cachedResult

            post.ogpTitle = result.title
            post.ogpDescription = result.description
            post.ogpImageURL = result.imageURL
        } catch {
            // Silently fail - URL just won't have OGP preview
        }
    }
}
