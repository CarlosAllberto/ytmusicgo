import SwiftUI

@main
struct YTMusicGoApp: App {
    // Aqui e não no Player: o botão do widget pode abrir o app em segundo plano, antes de alguma tela criar o Player.
    init() { NowPlaying.toggle = { Player.shared.toggle() } }

    var body: some Scene {
        WindowGroup { ContentView().environmentObject(Player.shared) }
    }
}

// Cores do site: fundo quase preto, texto branco, secundário a 70%.
extension View {
    // Realce nativo do ponteiro (iPad, Mac com Apple Silicon); no toque não aparece.
    func pointer() -> some View { hoverEffect(.highlight) }

    // Liquid Glass no iOS 26+, só na camada de navegação (barra, voltar, mini player); antes, `fallback`.
    @ViewBuilder func glass<S: Shape, V: View>(_ shape: S, fallback: (Self) -> V) -> some View {
        if #available(iOS 26.0, *) { glassEffect(.regular.interactive(), in: shape) } else { fallback(self) }
    }

    // Barra de cima: no iOS 26 o conteúdo rola por baixo com o efeito de borda; antes, empilhada.
    @ViewBuilder func topBar<C: View>(@ViewBuilder _ bar: () -> C) -> some View {
        if #available(iOS 26.0, *) { safeAreaBar(edge: .top, spacing: 0, content: bar) }
        else { VStack(spacing: 0) { bar(); self } }
    }
}

struct Pointer: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.7 : 1).hoverEffect(.highlight)
    }
}

enum Theme {
    static let bg = Color(red: 3 / 255, green: 3 / 255, blue: 3 / 255)
    static let secondary = Color.white.opacity(0.7)
    static let line = Color.white.opacity(0.15)
    static let accent = Color(red: 1, green: 0.27, blue: 0.27)  // vermelho do YouTube Music, para a faixa atual
}

// Abre o player cheio a partir das listas (tocar de novo a faixa atual não a reinicia).
extension EnvironmentValues { @Entry var openPlayer: () -> Void = {} }

struct ContentView: View {
    enum Mode { case home, search, library }
    @EnvironmentObject var player: Player
    @ObservedObject private var auth = Auth.shared
    @State private var mode = Mode.home
    @State private var query = ""
    @State private var submitted = ""
    @State private var showPlayer = false
    @State private var path: [String] = []
    @FocusState private var searchFocus: Bool

    var body: some View {
        ZStack {
            NavigationStack(path: $path) {
                VStack(spacing: 0) {
                    switch mode {
                    case .search:
                        if !submitted.isEmpty { PageView(key: submitted) { try await InnerTube.search(submitted) } } else { Spacer() }
                    case .library:
                        if auth.loggedIn { PageView { try await InnerTube.library() } } else { Spacer() }
                    case .home:
                        if auth.loggedIn { PageView { try await InnerTube.home() } }
                        else if auth.checked {
                            // Deslogado: só o aviso, como no YTMusicBar. O login segue pelo botão do topo.
                            VStack(spacing: 12) {
                                Image(systemName: "person.crop.circle").font(.system(size: 44)).foregroundStyle(Theme.secondary)
                                Text("Entre na sua conta").font(.title3.bold())
                                Text("Faça login no YouTube Music para ver suas recomendações e sua biblioteca.")
                                    .font(.callout).foregroundStyle(Theme.secondary).multilineTextAlignment(.center).frame(maxWidth: 260)
                            }.padding(32).frame(maxWidth: .infinity, maxHeight: .infinity)
                            .ignoresSafeArea(edges: .top)  // centra na tela inteira, não só abaixo da barra de cima
                        } else { Spacer() }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .topBar { topBar }
                .background(Theme.bg)
                .navigationDestination(for: String.self) { id in PageView { try await InnerTube.browse(id) }.overlay(alignment: .topLeading) { BackButton() }.toolbar(.hidden, for: .navigationBar) }
                .toolbar(.hidden, for: .navigationBar)
            }
            if showPlayer {
                PlayerView(close: { withAnimation { showPlayer = false } }, openArtist: { id in showPlayer = false; path.append(id) }).transition(.move(edge: .bottom))
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .environment(\.openPlayer) { withAnimation { showPlayer = true } }
        .tint(.white)  // sem isso botões e links saem no azul padrão do iOS
        .preferredColorScheme(.dark)
        .sheet(isPresented: $auth.showLogin) { LoginView() }
        .task { player.attach(); await auth.refresh() }
        .task(id: query) {
            guard !query.isEmpty else { return }
            try? await Task.sleep(nanoseconds: 350_000_000)
            if !Task.isCancelled { submitted = query }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { if player.current != nil && !showPlayer { miniPlayer } }
        .ignoresSafeArea(.keyboard, edges: .bottom)  // teclado cobre o mini player em vez de empurrá-lo, como no app antigo
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            if mode == .search {
                Image(systemName: "magnifyingglass").foregroundStyle(Theme.secondary)
                TextField("Buscar músicas, álbuns, artistas", text: $query)
                    .textFieldStyle(.plain).focused($searchFocus).onAppear { searchFocus = true }
                    .submitLabel(.search).autocorrectionDisabled().onSubmit { submitted = query }
                Button { mode = .home; query = ""; submitted = "" } label: { Image(systemName: "xmark") }.buttonStyle(Pointer())
            } else {
                Button { mode = .home } label: { Logo() }.buttonStyle(Pointer())
                Spacer()
                HStack(spacing: 6) {  // busca e perfil juntos, como itens de toolbar
                Button { mode = .search } label: {
                    Image(systemName: "magnifyingglass").font(.system(size: 16)).frame(width: 34, height: 34).glass(Circle()) { $0 }
                }.buttonStyle(Pointer())
                if auth.loggedIn {
                    Menu {
                        Button("Biblioteca", systemImage: "books.vertical") { mode = .library }
                        Button("Sair da conta", systemImage: "rectangle.portrait.and.arrow.right") { mode = .home; Task { await auth.logout() } }
                    } label: {
                        Group {
                            if let p = auth.photo { Thumb(url: p, size: 28, round: true) } else { Image(systemName: "person.crop.circle").font(.system(size: 24)) }
                        }.frame(width: 34, height: 34).glass(Circle()) { $0 }
                    }.pointer()
                } else {
                    Button { auth.login() } label: { Image(systemName: "person.crop.circle").font(.system(size: 24)).frame(width: 34, height: 34).glass(Circle()) { $0 } }.buttonStyle(Pointer()).accessibilityLabel("Entrar")
                }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6).frame(height: 58)  // mais respiro acima do logo e dos botões
    }

    // iOS 26: cápsula de vidro flutuando sobre a lista; antes, faixa cinza colada no rodapé.
    @ViewBuilder private var miniPlayer: some View {
        if #available(iOS 26.0, *) {
            // Véu escuro sobre o vidro: sem ele o texto da lista vaza por trás e briga com o título.
            // Padding de baixo negativo: a cápsula desce para a faixa do indicador de início, como a barra de abas do iOS 26,
            // e o recuo do conteúdo só conta a parte acima dela.
            miniBar.background(Capsule().fill(.black.opacity(0.65))).glassEffect(.regular.interactive(), in: Capsule())
                .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, -20)
        } else {
            miniBar.background(Color(white: 0.1))
        }
    }

    private var miniBar: some View {
        let c = player.current!
        return HStack(spacing: 12) {
            Thumb(url: c.thumb, size: 36)
            VStack(alignment: .leading, spacing: 1) {
                Text(c.title).font(.system(size: 14, weight: .semibold)).lineLimit(1)
                Text(c.subtitle).font(.system(size: 12)).foregroundStyle(Theme.secondary).lineLimit(1)
            }
            Spacer()
            Button { player.previous() } label: { Image(systemName: "backward.fill") }.buttonStyle(Pointer())
            Button { player.toggle() } label: { Image(systemName: player.playing ? "pause.fill" : "play.fill").font(.system(size: 18)) }.buttonStyle(Pointer())
            Button { player.next() } label: { Image(systemName: "forward.fill") }.buttonStyle(Pointer())
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture { withAnimation { showPlayer = true } }
        .pointer()
    }
}

// Logo oficial do YouTube Music (on_platform_logo_dark.svg do site), em vetor no catálogo.
// Logo e ícone do app são marcas do YouTube Music (Google), só para uso pessoal: trocar primeiro se o app um dia for publicado.
struct Logo: View {
    var body: some View { Image("YTMusicLogo").resizable().scaledToFit().frame(height: 24) }
}

struct BackButton: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        Button { dismiss() } label: {
            Image(systemName: "chevron.left").font(.system(size: 16, weight: .bold)).frame(width: 40, height: 40)
                .glass(Circle()) { $0.background(Circle().fill(Color.white.opacity(0.15))) }
        }.buttonStyle(Pointer()).padding(12)
    }
}

struct PageView: View {
    var key = ""  // muda para recarregar sem descartar a página atual (evita piscar)
    let load: () async throws -> Page
    @State private var page: Page?
    @State private var error: Error?
    @State private var attempt = 0  // "Tentar de novo" soma 1 e refaz o load

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                if let page {
                    if !page.title.isEmpty { HeaderView(page: page) }
                    ForEach(page.sections) { SectionView(section: $0) }
                } else if let error {
                    failure(error)
                } else {
                    ProgressView().frame(maxWidth: .infinity).padding(40)
                }
            }.padding(.top, page?.isArtist == true ? 0 : 14).padding(.bottom, 16)  // respiro sob o topo; o banner do artista encosta no alto
        }
        .background(Theme.bg)
        .task(id: "\(key)#\(attempt)") {
            do { page = try await load(); error = nil } catch is CancellationError {} catch { self.error = error }
        }
    }

    // Aviso no lugar do erro bruto (ex.: NSURLErrorDomain -1009).
    private func failure(_ error: Error) -> some View {
        let offline = [.notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed]
            .contains((error as? URLError)?.code)
        return VStack(spacing: 12) {
            Image(systemName: offline ? "wifi.slash" : "exclamationmark.triangle").font(.system(size: 40)).foregroundStyle(Theme.secondary)
            Text(offline ? "Sem conexão" : "Não foi possível carregar").font(.title3.bold())
            Text(offline ? "Verifique sua internet e tente de novo." : "Algo deu errado ao falar com o YouTube Music.")
                .font(.callout).foregroundStyle(Theme.secondary).multilineTextAlignment(.center).frame(maxWidth: 260)
            Pill(title: "Tentar de novo", icon: "arrow.clockwise", filled: false) { self.error = nil; attempt += 1 }.padding(.top, 4)
        }.padding(32).frame(maxWidth: .infinity)
    }
}

struct HeaderView: View {
    @EnvironmentObject var player: Player
    let page: Page
    @ObservedObject private var auth = Auth.shared
    @State private var subscribed: Bool?  // nil = o que veio na página

    // Faixas tocáveis da página, na ordem em que aparecem.
    private var tracks: [Item] { page.sections.flatMap(\.items).filter { $0.videoId != nil } }

    var body: some View {
        if page.isArtist {
            VStack(alignment: .leading, spacing: 6) {
                Spacer(minLength: 120)
                Text(page.title).font(.system(size: 26, weight: .bold))
                if !page.subtitle.isEmpty { Text(page.subtitle).font(.system(size: 13)).foregroundStyle(Theme.secondary) }
                HStack(spacing: 10) {
                    Pill(title: "Iniciar", icon: nil, filled: true) { if let t = tracks.first { player.play(t, in: tracks) } }
                    Pill(title: "Aleatório", icon: "shuffle", filled: false) { let l = tracks.shuffled(); if let t = l.first { player.play(t, in: l) } }
                    if auth.loggedIn, let id = page.channelId {
                        let on = subscribed ?? page.subscribed
                        Pill(title: on ? "Inscrito" : "Inscrever-se", icon: nil, filled: false) {
                            subscribed = !on  // otimista; volta se a API falhar
                            Task { do { try await InnerTube.subscribe(id, !on) } catch { subscribed = on } }
                        }
                    }
                }.padding(.top, 8)
            }
            .padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(alignment: .top) {
                // Foto do artista esmaecendo para o fundo, como no site.
                AsyncImage(url: page.thumb?.sized(840)) { $0.resizable().scaledToFill() } placeholder: { Color.clear }
                    .frame(height: 300).clipped()
                    .mask(LinearGradient(colors: [.black, .black.opacity(0.6), .clear], startPoint: .top, endPoint: .bottom))
            }
        } else {
            HStack(spacing: 16) {
                Thumb(url: page.thumb, size: 110)
                VStack(alignment: .leading, spacing: 4) {
                    Text(page.title).font(.system(size: 22, weight: .bold))
                    if !page.subtitle.isEmpty { Text(page.subtitle).font(.system(size: 13)).foregroundStyle(Theme.secondary).lineLimit(3) }
                }
            }.padding(.horizontal, 16).padding(.top, 64)
        }
    }
}

struct Pill: View {
    let title: String
    let icon: String?
    let filled: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon { Image(systemName: icon) }
                Text(title).font(.system(size: 13, weight: .semibold))
            }
            .padding(.horizontal, 14).frame(height: 32)
            .foregroundStyle(filled ? Color(white: 0.01) : .white)
            .background(Capsule().fill(filled ? Color.white : .clear))
            .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: filled ? 0 : 1))
        }.buttonStyle(Pointer())
    }
}

struct SectionView: View {
    @EnvironmentObject var player: Player
    @Environment(\.openPlayer) private var openPlayer
    let section: Section
    @State private var pos = 0
    private var isRows: Bool { section.items.first?.isRow == true }
    private var single: Bool { !isRows && section.items.count == 1 }

    var body: some View {
        ScrollViewReader { proxy in
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(section.title).font(.system(size: 20, weight: .bold))
                    Spacer()
                    if isRows && section.items.contains(where: { $0.videoId != nil }) {
                        Pill(title: "Tocar tudo", icon: nil, filled: false) { if let t = section.items.first(where: { $0.videoId != nil }) { player.play(t, in: section.items) } }
                    }
                    if !isRows && !single {
                        arrow("chevron.left") { go(-3, proxy) }
                        arrow("chevron.right") { go(3, proxy) }
                    }
                }.padding(.horizontal, 16).opacity(section.title.isEmpty ? 0 : 1).frame(height: section.title.isEmpty ? 0 : nil)
                if isRows {
                    VStack(spacing: 0) {
                        ForEach(section.items) { i in
                            act(i) { Row(item: i, linkArtist: i.videoId != nil) }
                            Divider().overlay(Theme.line).padding(.leading, 86)
                        }
                    }
                } else if single {
                    act(section.items[0]) { Card(item: section.items[0]) }.padding(.horizontal, 16)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 12) {  // não lazy: o LazyHStack media a altura pelo espaçador de 1pt
                            Color.clear.frame(width: 4, height: 1).id("start")  // margem de 16 (4 + spacing), sobrevive ao scrollTo
                            ForEach(section.items) { i in act(i) { Card(item: i) }.id(i.id) }
                        }.padding(.trailing, 16)
                    }
                }
            }
        }
    }

    private func go(_ d: Int, _ proxy: ScrollViewProxy) {
        pos = min(max(pos + d, 0), section.items.count - 1)
        withAnimation { if pos == 0 { proxy.scrollTo("start", anchor: .leading) } else { proxy.scrollTo(section.items[pos].id, anchor: .leading) } }
    }

    private func arrow(_ name: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name).font(.system(size: 13, weight: .bold)).frame(width: 34, height: 34)
                .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                .contentShape(Circle())
        }.buttonStyle(Pointer())
    }

    // Faixa toca; o resto abre a página.
    @ViewBuilder private func act<C: View>(_ i: Item, @ViewBuilder _ label: () -> C) -> some View {
        if i.videoId != nil {
            // Sem Button externo: o nome do artista na linha é um botão próprio e tem prioridade sobre o toque.
            label().contentShape(Rectangle()).onTapGesture { if i.videoId == player.current?.videoId { openPlayer() } else { player.play(i, in: section.items) } }.pointer()
        } else if let b = i.browseId {
            NavigationLink(value: b) { label() }.buttonStyle(Pointer())
        }
    }
}

struct Card: View {
    let item: Item
    // Artistas (UC...) saem redondos e centralizados, como nos "Artistas inscritos" do site.
    private var round: Bool { item.browseId?.hasPrefix("UC") == true }
    var body: some View {
        VStack(spacing: 6) {
            Thumb(url: item.thumb, size: 88, round: round)
            Text(item.title).font(.system(size: 12, weight: .semibold)).lineLimit(1)
            Text(item.subtitle).font(.system(size: 11)).foregroundStyle(Theme.secondary).lineLimit(1)
        }
        .multilineTextAlignment(round ? .center : .leading)
        .frame(width: 88, alignment: round ? .center : .leading)
    }
}

struct Row: View {
    @EnvironmentObject var player: Player
    let item: Item
    var linkArtist = false
    private var isCurrent: Bool { item.videoId != nil && item.videoId == player.current?.videoId }

    var body: some View {
        HStack(spacing: 14) {
            Thumb(url: item.thumb, size: 56).overlay { if isCurrent { NowPlayingBadge(playing: player.playing) } }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title).font(.system(size: 15, weight: .semibold)).lineLimit(1)
                    .foregroundStyle(isCurrent ? Theme.accent : .white)
                subtitle.font(.system(size: 12.5)).foregroundStyle(Theme.secondary).lineLimit(1)
            }
            Spacer()
        }.padding(.horizontal, 16).padding(.vertical, 7).contentShape(Rectangle())
    }

    // Nome do artista clicável quando o subtítulo começa com ele.
    @ViewBuilder private var subtitle: some View {
        if linkArtist, let n = item.artistName, let id = item.artistId, item.subtitle.hasPrefix(n) {
            HStack(spacing: 0) {
                NavigationLink(value: id) { Text(n) }.buttonStyle(Pointer())
                Text(String(item.subtitle.dropFirst(n.count)))
            }
        } else {
            Text(item.subtitle)
        }
    }
}

// Selo sobre a capa da faixa atual: ondas animadas tocando, pausa quando parada.
struct NowPlayingBadge: View {
    let playing: Bool
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4).fill(.black.opacity(0.55))
            Image(systemName: playing ? "waveform" : "pause.fill").font(.system(size: 20, weight: .bold))
                .symbolEffect(.variableColor.iterative, isActive: playing)
        }.foregroundStyle(.white)
    }
}

struct Thumb: View {
    let url: URL?
    let size: CGFloat
    var round = false
    var body: some View {
        AsyncImage(url: url?.sized(Int(size * 2))) { $0.resizable().scaledToFill() } placeholder: { Color.white.opacity(0.08) }
            .frame(width: size, height: size).clipShape(RoundedRectangle(cornerRadius: round ? size / 2 : 4))
    }
}
