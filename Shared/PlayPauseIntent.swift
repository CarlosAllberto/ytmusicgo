import AppIntents
import WidgetKit

/// Botão de tocar/pausar do widget. Por ser AudioPlaybackIntent e estar nos dois alvos,
/// o iOS executa perform() no processo do app, que controla o player da página.
struct PlayPauseIntent: AudioPlaybackIntent {
    static var title: LocalizedStringResource = "Tocar ou pausar"
    static var description = IntentDescription("Toca ou pausa a música atual do YTMusicGo.")

    /// Definido pelo app ao iniciar; no processo do widget fica nil.
    @MainActor static var toggle: (() -> Void)?

    init() {}

    func perform() async throws -> some IntentResult {
        // Inverte já o estado salvo para o widget responder ao toque sem esperar a página.
        var np = NowPlayingStore.load()
        np.isPlaying.toggle()
        NowPlayingStore.save(np)
        await MainActor.run { Self.toggle?() }
        WidgetCenter.shared.reloadTimelines(ofKind: NowPlayingStore.widgetKind)
        return .result()
    }
}
