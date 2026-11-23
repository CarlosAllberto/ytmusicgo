import UIKit
import AVFoundation
import WebKit
import WidgetKit

// Toca pelo player oficial numa WKWebView escondida: resolve assinatura e PO token sozinho.
final class Player: NSObject, ObservableObject, WKScriptMessageHandler {
    static let shared = Player()
    @Published var current: Item?
    @Published var playing = false {
        didSet { if playing != oldValue { NowPlaying.save(playing: playing); WidgetCenter.shared.reloadTimelines(ofKind: NowPlaying.kind) } }
    }

    @Published private(set) var queue: [Item] = []
    @Published private(set) var index = 0
    @Published private(set) var position = 0.0
    @Published private(set) var duration = 0.0
    @Published var shuffle = false { didSet { applyShuffle() } }
    @Published var repeatMode = RepeatMode.off
    enum RepeatMode { case off, all, one }

    private var ordered: [Item] = []  // ordem original, para desligar o embaralhar
    private var timer: Timer?

    private let web: WKWebView
    private var rulesReady = false
    private var pending: URL?

    override init() {
        // App recém-aberto não está tocando, mesmo que o widget tenha ficado com o estado da última sessão.
        NowPlaying.save(playing: false)
        WidgetCenter.shared.reloadTimelines(ofKind: NowPlaying.kind)
        // Sem categoria playback o iOS silencia a página ao bloquear a tela. setActive bloqueia a thread, então roda fora dela.
        DispatchQueue.global().async {
            try? AVAudioSession.sharedInstance().setCategory(.playback)
            try? AVAudioSession.sharedInstance().setActive(true)
        }
        let cfg = WKWebViewConfiguration()
        cfg.websiteDataStore = .default()  // mesmo store do login
        cfg.mediaTypesRequiringUserActionForPlayback = []
        cfg.allowsInlineMediaPlayback = true
        cfg.defaultWebpagePreferences.preferredContentMode = .desktop
        web = WKWebView(frame: CGRect(x: -10000, y: 0, width: 400, height: 300), configuration: cfg)
        web.customUserAgent = Auth.userAgent
        web.isUserInteractionEnabled = false
        super.init()
        // 'ended' não borbulha, por isso captura. Avança a nossa fila em vez da rádio automática do site.
        let js = "document.addEventListener('ended',e=>{if(e.target.tagName==='VIDEO')webkit.messageHandlers.ended.postMessage(0)},true)"
        let ucc = cfg.userContentController
        ucc.addUserScript(WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: false))
        ucc.add(self, name: "ended")
        // O WebKit já publica a faixa no Now Playing do iOS com os dados do site; um MPNowPlayingInfoCenter nosso duplicava.
        // Próxima/anterior da tela bloqueada vão para a nossa fila; play/pause de lá atualizam o estado.
        // seekforward/seekbackward ficam sempre nulos: com eles o iOS troca anterior/próxima por voltar e avançar 10 s.
        // Não pelos eventos pause do vídeo: o WebKit pausa sozinho ao ir para o fundo, e o tick precisa retomar.
        let media = """
        (()=>{const ms=navigator.mediaSession;if(!ms)return;const post=a=>()=>webkit.messageHandlers.media.postMessage(a);
        const v=()=>document.querySelector('video');const own={nexttrack:post('next'),previoustrack:post('previous'),
        play:()=>{v()?.play();post('play')()},pause:()=>{v()?.pause();post('pause')()},seekforward:null,seekbackward:null};
        const set=ms.setActionHandler.bind(ms);ms.setActionHandler=(a,h)=>set(a,a in own?own[a]:h);for(const a in own)set(a,own[a])})()
        """
        ucc.addUserScript(WKUserScript(source: media, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        ucc.add(self, name: "media")
        // Bloqueio de anúncios: script que pula anúncios e regras de rede. Só carrega depois das regras.
        if let u = Bundle.main.url(forResource: "inject-ads", withExtension: "js"), let src = try? String(contentsOf: u) {
            ucc.addUserScript(WKUserScript(source: src, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        }
        AdBlock.install(in: ucc) { [weak self] in
            guard let self else { return }
            rulesReady = true
            if let u = pending { pending = nil; web.load(URLRequest(url: u)) }
        }
    }

    // Fim da faixa: 'uma' repete, 'todas' volta ao começo da fila.
    // Fim da fila com "Manter ordem": esvazia a página para o site não seguir com a rádio automática.
    func userContentController(_ c: WKUserContentController, didReceive m: WKScriptMessage) {
        if m.name == "media" {
            switch m.body as? String {
            case "next": next()
            case "previous": previous()
            case "play": playing = true
            case "pause": playing = false
            default: break
            }
            return
        }
        if repeatMode == .one, let c = current { load(c) }
        else if repeatMode == .all, index == queue.count - 1, let f = queue.first { index = 0; load(f) }
        else if index == queue.count - 1, Prefs.keepOrder { web.load(URLRequest(url: URL(string: "about:blank")!)); playing = false }
        else { next() }
    }

    func next() { step(1) }
    func previous() { step(-1) }
    private func step(_ d: Int) {
        let i = index + d
        guard queue.indices.contains(i) else { return }
        index = i
        load(queue[i])
    }

    /// Toca `t` e usa as faixas tocáveis de `list` como fila.
    func play(_ t: Item, in list: [Item] = []) {
        queue = list.filter { $0.videoId != nil }
        index = queue.firstIndex { $0.id == t.id } ?? 0
        if queue.isEmpty { queue = [t] }
        ordered = queue
        current = t
        if shuffle { applyShuffle() }
        load(t)
    }

    /// Toca a faixa `i` da fila.
    func play(at i: Int) { if queue.indices.contains(i) { index = i; load(queue[i]) } }

    // Liga: embaralha o que vem depois da atual. Desliga: volta à ordem original.
    private func applyShuffle() {
        guard let c = current, !queue.isEmpty else { return }
        if shuffle { queue = [c] + queue.filter { $0.id != c.id }.shuffled() }
        else { queue = ordered }
        index = queue.firstIndex { $0.id == c.id } ?? 0
    }

    func seek(to s: Double) {
        position = s
        web.evaluateJavaScript("(()=>{const v=document.querySelector('video');if(v)v.currentTime=\(s)})()")
    }

    // Em Modo de Pouca Energia o WebKit recusa o play() do próprio site (NotAllowedError) sem gesto do usuário,
    // mesmo com mediaTypesRequiringUserActionForPlayback vazio; o evaluateJavaScript conta como gesto, então o play sai daqui.
    private func tick() {
        web.evaluateJavaScript("(()=>{const v=document.querySelector('video');if(!v)return null;if(\(playing)&&v.paused&&!v.ended)v.play();return[v.currentTime,isFinite(v.duration)?v.duration:0]})()") { [weak self] r, _ in
            guard let self, let a = r as? [Double], a.count == 2 else { return }
            position = a[0]; duration = a[1]
        }
    }

    private func load(_ t: Item) {
        current = t
        share(t)
        attach()
        playing = true
        position = 0; duration = 0
        if timer == nil { timer = .scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.tick() } }
        let url = URL(string: "https://music.youtube.com/watch?v=\(t.videoId ?? "")")!
        if rulesReady { web.load(URLRequest(url: url)) } else { pending = url }
    }

    // Título, artista e capa para o widget. A capa vai em arquivo: o widget não baixa imagens.
    private func share(_ t: Item) {
        NowPlaying.save(title: t.title, artist: t.subtitle)
        if let f = NowPlaying.artworkURL { try? FileManager.default.removeItem(at: f) }
        WidgetCenter.shared.reloadTimelines(ofKind: NowPlaying.kind)
        guard let u = t.thumb?.sized(300), let f = NowPlaying.artworkURL else { return }
        URLSession.shared.dataTask(with: u) { [weak self] d, _, _ in
            DispatchQueue.main.async {
                guard let d, self?.current?.id == t.id else { return }  // trocou de faixa no meio
                try? d.write(to: f)
                WidgetCenter.shared.reloadTimelines(ofKind: NowPlaying.kind)
            }
        }.resume()
    }

    // Fora da hierarquia de views o WebKit suspende a página (e o allCookies() do Auth pode nunca voltar). Fica fora da tela, presa à janela principal.
    func attach() {
        if web.superview == nil, let w = UIApplication.shared.connectedScenes.compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first { w.addSubview(web) }
    }

    func toggle() { setPlaying(nil) }

    /// nil alterna; true/false força, para play e pause não se desfazerem.
    private func setPlaying(_ on: Bool?) {
        // Parado no fim da fila (página vazia): play recomeça a última faixa.
        if on != false, web.url?.absoluteString == "about:blank", let c = current { load(c); return }
        // Pelo estado nosso, não pelo v.paused: o vídeo pode estar parado esperando o play do tick.
        let want = on ?? !playing
        playing = want  // já agora, para o tick seguinte não desfazer a pausa
        web.evaluateJavaScript("(()=>{const v=document.querySelector('video');if(!v)return false;\(want)?v.play():v.pause();return !v.paused})()") { [weak self] r, _ in
            if let on = r as? Bool { self?.playing = on }
        }
    }
}
