import SwiftUI
import WebKit
import AVFoundation

@main
struct YTMusicGoApp: App {
    init() {
        // Sem categoria playback o iOS silencia a página ao bloquear a tela.
        // setActive bloqueia a thread principal, então roda fora dela.
        DispatchQueue.global().async {
            try? AVAudioSession.sharedInstance().setCategory(.playback)
            try? AVAudioSession.sharedInstance().setActive(true)
        }
    }

    var body: some Scene {
        WindowGroup {
            WebView().background(Color.black).ignoresSafeArea(.container, edges: .bottom)
        }
    }
}

struct WebView: UIViewRepresentable {
    // Site desktop: os scripts injetados dependem do DOM do ytmusic-app, que o site mobile não tem.
    private static let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/27.0.1 Safari/605.1.15"

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsInlineMediaPlayback = true
        config.defaultWebpagePreferences.preferredContentMode = .desktop

        let ucc = config.userContentController
        ucc.addUserScript(WKUserScript(source: "window.__ytmOrder = { enabled: true };", injectionTime: .atDocumentStart, forMainFrameOnly: true))
        for (name, time) in [("inject-ads", WKUserScriptInjectionTime.atDocumentStart), ("inject-order", .atDocumentEnd), ("inject-ui", .atDocumentEnd)] {
            if let url = Bundle.main.url(forResource: name, withExtension: "js"), let src = try? String(contentsOf: url) {
                ucc.addUserScript(WKUserScript(source: src, injectionTime: time, forMainFrameOnly: true))
            }
        }

        let web = WKWebView(frame: .zero, configuration: config)
        web.customUserAgent = Self.userAgent
        web.isOpaque = false
        web.backgroundColor = .black
        web.scrollView.backgroundColor = .black
        #if DEBUG
        web.isInspectable = true
        #endif
        // Só carrega depois das regras de bloqueio, senão passam requisições de anúncio.
        AdBlock.install(in: ucc) { web.load(URLRequest(url: URL(string: "https://music.youtube.com")!)) }
        return web
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
