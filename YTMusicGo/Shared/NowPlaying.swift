import AppIntents
import Foundation

// Faixa atual, gravada pelo app e lida pelo widget pelo App Group.
enum NowPlaying {
    static let group = "group.com.treendz.ytmusicgo"
    static let kind = "NowPlaying"  // tipo do widget, para recarregar só ele
    private static var defaults: UserDefaults? { UserDefaults(suiteName: group) }
    static var artworkURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)?.appendingPathComponent("artwork.jpg")
    }

    struct Track {
        var title: String
        var artist: String
        var playing: Bool
    }

    static func load() -> Track? {
        guard let d = defaults, let title = d.string(forKey: "title") else { return nil }
        return Track(title: title, artist: d.string(forKey: "artist") ?? "", playing: d.bool(forKey: "playing"))
    }

    static func save(title: String, artist: String) {
        defaults?.set(title, forKey: "title")
        defaults?.set(artist, forKey: "artist")
    }

    static func save(playing: Bool) { defaults?.set(playing, forKey: "playing") }

    // O intent roda no processo do app; quem toca é o Player, que se registra aqui.
    static var toggle: (() -> Void)?
}

// AudioPlaybackIntent: o iOS executa no app (em segundo plano), não no widget.
struct TogglePlayIntent: AudioPlaybackIntent {
    static let title: LocalizedStringResource = "Tocar ou pausar"

    func perform() async throws -> some IntentResult {
        await MainActor.run { NowPlaying.toggle?() }
        return .result()
    }
}
