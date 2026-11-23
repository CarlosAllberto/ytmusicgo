import SwiftUI
import WebKit
import CryptoKit

// Login Google numa WKWebView; "logado" = cookie SAPISID no store default (o mesmo que o Player usa).
@MainActor final class Auth: ObservableObject {
    static let shared = Auth()
    @Published var loggedIn = false
    @Published var photo: URL?
    @Published var showLogin = false
    @Published private(set) var checked = false  // até o 1º refresh não se sabe se está logado; evita piscar o aviso de login
    // Safari desktop: o site mobile não tem o DOM que os scripts injetados esperam. Usado também pelo Player.
    nonisolated static let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/27.0.1 Safari/605.1.15"

    private var store: WKHTTPCookieStore { WKWebsiteDataStore.default().httpCookieStore }

    func cookies() async -> [HTTPCookie] {
        await store.allCookies().filter { $0.domain.hasSuffix("youtube.com") }
    }

    func refresh() async {
        loggedIn = await cookies().contains { $0.name == "SAPISID" || $0.name == "__Secure-3PAPISID" }
        photo = loggedIn ? await InnerTube.avatar() : nil
        checked = true
    }

    func logout() async {
        await WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: .distantPast)
        await refresh()
    }

    // Cabeçalhos autenticados, ou nil se deslogado.
    func headers() async -> [String: String]? {
        let c = await cookies()
        guard let sid = (c.first { $0.name == "SAPISID" } ?? c.first { $0.name == "__Secure-3PAPISID" })?.value else { return nil }
        let ts = Int(Date().timeIntervalSince1970)
        let hash = Insecure.SHA1.hash(data: Data("\(ts) \(sid) https://music.youtube.com".utf8)).map { String(format: "%02x", $0) }.joined()
        return ["Cookie": c.map { "\($0.name)=\($0.value)" }.joined(separator: "; "),
                "Authorization": "SAPISIDHASH \(ts)_\(hash)",
                "X-Goog-AuthUser": "0", "X-Origin": "https://music.youtube.com"]
    }

    func login() { showLogin = true }
}

// Tela de login para `.sheet(isPresented: $auth.showLogin)`. Fecha sozinha quando o Google devolve para o YouTube Music.
struct LoginView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.websiteDataStore = .default()
        let web = WKWebView(frame: .zero, configuration: cfg)
        web.customUserAgent = Auth.userAgent
        web.navigationDelegate = context.coordinator
        web.load(URLRequest(url: URL(string: "https://accounts.google.com/ServiceLogin?service=youtube&continue=https://music.youtube.com")!))
        return web
    }

    func updateUIView(_ w: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ w: WKWebView, didFinish _: WKNavigation!) {
            guard w.url?.host == "music.youtube.com" else { return }
            Task { @MainActor in
                Auth.shared.showLogin = false
                await Auth.shared.refresh()
            }
        }
    }
}
