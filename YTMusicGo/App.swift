import SwiftUI
import WebKit
import AVFoundation

@main
struct YTMusicGoApp: App {
    @StateObject private var tabs = TabState()

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
            VStack(spacing: 0) {
                WebView(tabs: tabs).ignoresSafeArea(.container, edges: tabs.playerOpen ? .bottom : [])
                if !tabs.playerOpen { TabBar(tabs: tabs) }
            }
            .background(Color.black.ignoresSafeArea())
            .ignoresSafeArea(.keyboard, edges: .bottom) // teclado cobre a tab bar e o player em vez de empurrá-los
        }
    }
}

// Recebe do inject-ui.js a rota atual e se a página do player está aberta.
final class TabState: NSObject, ObservableObject, WKScriptMessageHandler {
    @Published var path = "/"
    @Published var playerOpen = false
    weak var web: WKWebView?

    func userContentController(_ c: WKUserContentController, didReceive m: WKScriptMessage) {
        guard let body = m.body as? [String: Any] else { return }
        path = body["path"] as? String ?? path
        playerOpen = body["playerOpen"] as? Bool ?? playerOpen
    }

    func open(_ browseId: String) {
        web?.evaluateJavaScript("window.__ytmTab('\(browseId)')")
    }
}

struct TabBar: View {
    @ObservedObject var tabs: TabState

    private static let items = [
        (label: "Início", icon: "house.fill", path: "/", browseId: "FEmusic_home"),
        (label: "Explorar", icon: "safari.fill", path: "/explore", browseId: "FEmusic_explore"),
        (label: "Biblioteca", icon: "rectangle.stack.fill", path: "/library", browseId: "FEmusic_library_landing"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Self.items, id: \.path) { item in
                Button { tabs.open(item.browseId) } label: {
                    VStack(spacing: 2) {
                        Image(systemName: item.icon).font(.system(size: 20))
                        Text(item.label).font(.caption2)
                    }
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .foregroundStyle(tabs.path == item.path ? Color.white : Color.white.opacity(0.6))
                }
                .accessibilityAddTraits(tabs.path == item.path ? .isSelected : [])
            }
        }
        .padding(.top, 8)
        .padding(.bottom, -14) // avança sobre a área do home indicator
        .overlay(alignment: .top) { Color.white.opacity(0.1).frame(height: 1) }
    }
}

struct WebView: UIViewRepresentable {
    let tabs: TabState

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

        ucc.add(tabs, name: "ytmTabs")

        let web = WKWebView(frame: .zero, configuration: config)
        tabs.web = web
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
