import AppIntents
import SwiftUI
import WidgetKit

@main
struct YTMusicGoWidgets: WidgetBundle {
    var body: some Widget { NowPlayingWidget() }
}

struct NowPlayingWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: NowPlaying.kind, provider: Provider()) { NowPlayingView(entry: $0) }
            .configurationDisplayName("Tocando agora")
            .description("A faixa atual do YouTube Music, com tocar e pausar.")
            .supportedFamilies([.systemSmall])
    }
}

struct Entry: TimelineEntry {
    let date = Date()
    let track: NowPlaying.Track?
    let artwork: UIImage?
}

// Sem linha do tempo: o app recarrega o widget quando a faixa ou o estado mudam.
struct Provider: TimelineProvider {
    func placeholder(in _: Context) -> Entry { Entry(track: .init(title: "Música", artist: "Artista", playing: false), artwork: nil) }
    func getSnapshot(in _: Context, completion: @escaping (Entry) -> Void) { completion(current()) }
    func getTimeline(in _: Context, completion: @escaping (Timeline<Entry>) -> Void) { completion(Timeline(entries: [current()], policy: .never)) }

    private func current() -> Entry {
        Entry(track: NowPlaying.load(), artwork: NowPlaying.artworkURL.flatMap { UIImage(contentsOfFile: $0.path) })
    }
}

struct NowPlayingView: View {
    let entry: Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                artwork
                Spacer(minLength: 0)
                // Marca do Google: uso pessoal, primeira coisa a trocar se o app for publicado.
                Image("YTMusicIcon").resizable().desaturatedWhenAccented().frame(width: 22, height: 22)
            }
            Spacer(minLength: 0)
            HStack(alignment: .bottom, spacing: 6) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(entry.track?.title ?? "Nada tocando").font(.system(size: 14, weight: .semibold)).lineLimit(1)
                    Text(entry.track?.artist ?? "Abra o YTMusicGo").font(.system(size: 13)).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer(minLength: 0)
                if let t = entry.track {
                    Button(intent: TogglePlayIntent()) {
                        // Ícone recortado do círculo, não pintado de preto: nos modos tingido e transparente o iOS
                        // pinta tudo no mesmo tom, e o furo continua mostrando o fundo.
                        Circle().fill(.white).frame(width: 36, height: 36)
                            .overlay { Image(systemName: t.playing ? "pause.fill" : "play.fill").font(.system(size: 16, weight: .bold)).blendMode(.destinationOut) }
                            .compositingGroup()
                    }.buttonStyle(.plain)
                }
            }
        }
        .foregroundStyle(.white)
        .containerBackground(for: .widget) { Color(white: 0.11) }
    }

    @ViewBuilder private var artwork: some View {
        Group {
            if let a = entry.artwork { Image(uiImage: a).resizable().desaturatedWhenAccented().scaledToFill() }
            else { Color.white.opacity(0.1).overlay(Image(systemName: "music.note").font(.title2).foregroundStyle(.secondary)) }
        }
        .frame(width: 76, height: 76).clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

extension Image {
    // Nos ícones tingidos/transparentes do iOS 18+, imagem sem isto vira uma silhueta chapada.
    @ViewBuilder func desaturatedWhenAccented() -> some View {
        if #available(iOS 18.0, *) { widgetAccentedRenderingMode(.desaturated) } else { self }
    }
}
