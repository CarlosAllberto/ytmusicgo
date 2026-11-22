import Foundation

/// Faixa atual, gravada pelo app no App Group e lida pelo widget.
struct NowPlaying: Codable, Equatable {
    var title: String
    var artist: String
    var isPlaying: Bool
    var artworkURL: String?

    static let empty = NowPlaying(title: "Nada tocando", artist: "Abra o YTMusicGo", isPlaying: false, artworkURL: nil)
}

enum NowPlayingStore {
    static let appGroup = "group.com.treendz.ytmusicgo"
    static let widgetKind = "NowPlayingWidget"
    private static let key = "nowPlaying"

    private static var defaults: UserDefaults? { UserDefaults(suiteName: appGroup) }

    /// Capa já reduzida, em arquivo: o widget tem limite de memória e não baixa nada sozinho.
    static var artworkFile: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)?.appendingPathComponent("artwork.jpg")
    }

    static func load() -> NowPlaying {
        guard let data = defaults?.data(forKey: key), let np = try? JSONDecoder().decode(NowPlaying.self, from: data) else { return .empty }
        return np
    }

    static func save(_ np: NowPlaying) {
        if let data = try? JSONEncoder().encode(np) { defaults?.set(data, forKey: key) }
    }
}
