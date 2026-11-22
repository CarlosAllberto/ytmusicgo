import SwiftUI
import WidgetKit
import AppIntents

struct NowPlayingEntry: TimelineEntry {
    let date: Date
    let np: NowPlaying
    let artwork: UIImage?
}

struct NowPlayingProvider: TimelineProvider {
    func placeholder(in context: Context) -> NowPlayingEntry {
        NowPlayingEntry(date: .now, np: NowPlaying(title: "Música", artist: "Artista", isPlaying: false, artworkURL: nil), artwork: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (NowPlayingEntry) -> Void) {
        completion(current())
    }

    // O app pede a atualização sempre que a faixa ou o estado mudam; o widget não se atualiza sozinho.
    func getTimeline(in context: Context, completion: @escaping (Timeline<NowPlayingEntry>) -> Void) {
        completion(Timeline(entries: [current()], policy: .never))
    }

    private func current() -> NowPlayingEntry {
        let np = NowPlayingStore.load()
        let art = np.artworkURL == nil ? nil : NowPlayingStore.artworkFile.flatMap { UIImage(contentsOfFile: $0.path) }
        return NowPlayingEntry(date: .now, np: np, artwork: art)
    }
}

struct NowPlayingWidgetView: View {
    let entry: NowPlayingEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                artwork
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                Spacer(minLength: 0)
                Image("AppLogo")
                    .resizable()
                    .frame(width: 22, height: 22)
                    .clipShape(Circle())
                    .widgetAccentable()
            }

            Spacer(minLength: 6)

            HStack(alignment: .bottom, spacing: 6) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(entry.np.title)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                    Text(entry.np.artist)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Button(intent: PlayPauseIntent()) {
                    Image(systemName: entry.np.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(.white))
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.plain)
                .widgetAccentable()
                .accessibilityLabel(entry.np.isPlaying ? "Pausar" : "Tocar")
            }
        }
        .foregroundStyle(.white)
        .containerBackground(for: .widget) { background }
    }

    @ViewBuilder private var artwork: some View {
        if let img = entry.artwork {
            Image(uiImage: img).resizable().scaledToFill()
        } else {
            ZStack {
                Color.white.opacity(0.12)
                Image(systemName: "music.note").font(.system(size: 28, weight: .semibold)).foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    /// Fundo cinza translúcido tingido pela capa, como o widget do Spotify.
    @ViewBuilder private var background: some View {
        ZStack {
            Color(white: 0.22)
            if let img = entry.artwork {
                Image(uiImage: img).resizable().scaledToFill().blur(radius: 30).opacity(0.55)
            }
            Color.black.opacity(0.25)
        }
    }
}

struct NowPlayingWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: NowPlayingStore.widgetKind, provider: NowPlayingProvider()) { entry in
            NowPlayingWidgetView(entry: entry)
        }
        .configurationDisplayName("Tocando agora")
        .description("Mostra a música atual e toca ou pausa sem abrir o app.")
        .supportedFamilies([.systemSmall])
    }
}

@main
struct YTMusicGoWidgetBundle: WidgetBundle {
    var body: some Widget {
        NowPlayingWidget()
    }
}

#Preview(as: .systemSmall) {
    NowPlayingWidget()
} timeline: {
    NowPlayingEntry(date: .now, np: NowPlaying(title: "Time", artist: "Pink Floyd", isPlaying: false, artworkURL: nil), artwork: nil)
    NowPlayingEntry(date: .now, np: NowPlaying(title: "Time", artist: "Pink Floyd", isPlaying: true, artworkURL: nil), artwork: nil)
}
