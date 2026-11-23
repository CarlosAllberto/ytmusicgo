import SwiftUI

// Tela cheia do player, no tema escuro do app web.
struct PlayerView: View {
    @EnvironmentObject var player: Player
    var close: () -> Void
    var openArtist: (String) -> Void
    @State private var drag: Double?  // posição (0...1) enquanto arrasta a barra
    @State private var pull: CGFloat = 0  // deslocamento do arrastar para fechar
    @State private var showLyrics = false
    @State private var lyrics: String?
    @State private var loadingLyrics = false
    @State private var translated: String?  // cache da tradução da faixa atual
    @State private var showTranslated = false
    @State private var translating = false
    @State private var translateFailed = false

    private let bg = Color(red: 3 / 255, green: 3 / 255, blue: 3 / 255)
    private var frac: Double { player.duration > 0 ? min(player.position / player.duration, 1) : 0 }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Arrastar para baixo só no topo (cabeçalho e capa): assim não disputa com a rolagem da fila nem com a barra de progresso.
                VStack(spacing: 20) {
                    HStack { Button(action: close) { Image(systemName: "chevron.down").font(.title3).frame(width: 36, height: 36).glass(Circle()) { $0 } }.buttonStyle(Pointer()); Spacer() }
                        .overlay { Capsule().fill(.white.opacity(0.3)).frame(width: 36, height: 5) }
                    Thumb(url: player.current?.thumb, size: 300).clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .contentShape(Rectangle())
                .gesture(DragGesture(coordinateSpace: .global)  // global: a vista anda junto com o dedo
                    .onChanged { pull = max($0.translation.height, 0) }
                    .onEnded { v in
                        if v.translation.height > 120 || v.predictedEndTranslation.height > 400 { close() }
                        else { withAnimation(.spring(duration: 0.3)) { pull = 0 } }
                    })
                VStack(alignment: .leading, spacing: 4) {
                    Text(player.current?.title ?? "").font(.system(size: 22, weight: .bold)).lineLimit(2)
                    subtitle
                }.frame(maxWidth: .infinity, alignment: .leading)
                progress
                controls
                HStack(spacing: 20) {
                    tab("A seguir", !showLyrics) { showLyrics = false }
                    tab("Letra", showLyrics) { showLyrics = true }
                    Spacer()
                }.padding(.top, 8)
                if showLyrics {
                    if loadingLyrics { ProgressView().frame(maxWidth: .infinity).padding(20) }
                    else {
                        if lyrics != nil { translateButton }
                        Text((showTranslated ? translated : lyrics) ?? "Letra indisponível para esta faixa.")
                            .foregroundStyle(lyrics == nil ? .white.opacity(0.7) : .white).font(.system(size: 15, weight: .medium)).lineSpacing(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    ForEach(Array(player.queue.enumerated()), id: \.element.id) { i, t in
                        Button { player.play(at: i) } label: { Row(item: t) }.buttonStyle(Pointer())
                            .padding(6).background(i == player.index ? Color.white.opacity(0.12) : .clear, in: RoundedRectangle(cornerRadius: 6))
                    }
                }
            }.padding(24).frame(maxWidth: 420)
        }
        .task(id: player.current?.videoId) {
            lyrics = nil; translated = nil; showTranslated = false; translateFailed = false
            guard let id = player.current?.videoId else { return }
            loadingLyrics = true
            lyrics = await InnerTube.lyrics(id)
            loadingLyrics = false
        }
        .frame(maxWidth: .infinity).background(bg).foregroundStyle(.white).preferredColorScheme(.dark)
        .offset(y: pull)
    }

    @ViewBuilder private var subtitle: some View {
        let sub = player.current?.subtitle ?? ""
        if let name = player.current?.artistName, let id = player.current?.artistId {
            HStack(spacing: 0) {
                Button { openArtist(id) } label: { Text(name).underline() }.buttonStyle(Pointer())
                Text(sub.hasPrefix(name) ? String(sub.dropFirst(name.count)) : "")
            }.font(.system(size: 15)).foregroundStyle(.white.opacity(0.7)).lineLimit(1)
        } else {
            Text(sub).font(.system(size: 15)).foregroundStyle(.white.opacity(0.7)).lineLimit(1)
        }
    }

    private var translateButton: some View {
        HStack(spacing: 8) {
            Button {
                if showTranslated { showTranslated = false; return }
                if translated != nil { showTranslated = true; return }
                guard let text = lyrics, !translating else { return }
                translating = true; translateFailed = false
                let id = player.current?.videoId
                Task {
                    let t = await Translate.text(text)
                    translating = false
                    guard id == player.current?.videoId else { return }  // trocou de faixa no meio
                    if let t { translated = t; showTranslated = true } else { translateFailed = true }
                }
            } label: {
                Text(showTranslated ? "Ver original" : "Traduzir").font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 12).padding(.vertical, 5).background(Capsule().fill(.white.opacity(0.15)))
            }.buttonStyle(Pointer())
            if translating { ProgressView().controlSize(.small) }
            if translateFailed { Text("Não deu para traduzir agora.").font(.system(size: 11)).foregroundStyle(.white.opacity(0.7)) }
            Spacer()
        }
    }

    private func tab(_ title: String, _ on: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.system(size: 15, weight: .semibold)).foregroundStyle(on ? .white : .white.opacity(0.6))
        }.buttonStyle(Pointer())
    }

    private var progress: some View {
        VStack(spacing: 6) {
            GeometryReader { g in
                let x = (drag ?? frac) * g.size.width
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.2)).frame(height: 3)
                    Capsule().fill(.white).frame(width: x, height: 3)
                    Circle().fill(.white).frame(width: 12, height: 12).offset(x: x - 6)
                }
                .frame(maxHeight: .infinity).contentShape(Rectangle()).pointer()
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { drag = min(max($0.location.x / g.size.width, 0), 1) }
                    .onEnded { _ in if let d = drag { player.seek(to: d * player.duration) }; drag = nil })
            }.frame(height: 16)
            HStack {
                Text(time((drag ?? frac) * player.duration)); Spacer(); Text(time(player.duration))
            }.font(.system(size: 11)).foregroundStyle(.white.opacity(0.7))
        }
    }

    // Glifos simples como no Now Playing da Apple; só o play tem círculo branco.
    private var controls: some View {
        HStack(spacing: 20) {
            Button { player.shuffle.toggle() } label: { Image(systemName: "shuffle").opacity(player.shuffle ? 1 : 0.5).frame(width: 38, height: 38) }
            Button { player.previous() } label: { Image(systemName: "backward.fill").font(.title3).frame(width: 46, height: 46) }
            Button { player.toggle() } label: {
                Image(systemName: player.playing ? "pause.fill" : "play.fill").font(.title2).foregroundColor(.black)
                    .frame(width: 56, height: 56).background(Circle().fill(.white))
            }
            Button { player.next() } label: { Image(systemName: "forward.fill").font(.title3).frame(width: 46, height: 46) }
            Button {
                player.repeatMode = player.repeatMode == .off ? .all : player.repeatMode == .all ? .one : .off
            } label: {
                Image(systemName: player.repeatMode == .one ? "repeat.1" : "repeat").opacity(player.repeatMode == .off ? 0.5 : 1).frame(width: 38, height: 38)
            }
        }.buttonStyle(Pointer()).font(.body)
    }

    private func time(_ s: Double) -> String { String(format: "%d:%02d", Int(s) / 60, Int(s) % 60) }
}
