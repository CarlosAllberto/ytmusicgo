import UIKit
import WebKit
import WidgetKit

/// Recebe do inject-nowplaying.js a faixa atual, grava no App Group e atualiza o widget.
final class NowPlayingBridge: NSObject, WKScriptMessageHandler {
    static let shared = NowPlayingBridge()
    weak var web: WKWebView?
    private var current = NowPlayingStore.load()

    func userContentController(_ c: WKUserContentController, didReceive m: WKScriptMessage) {
        guard let body = m.body as? [String: Any] else { return }
        let np = NowPlaying(
            title: body["title"] as? String ?? "",
            artist: body["artist"] as? String ?? "",
            isPlaying: body["playing"] as? Bool ?? false,
            artworkURL: body["artwork"] as? String
        )
        guard np != current, !np.title.isEmpty else { return }
        let artworkChanged = np.artworkURL != current.artworkURL
        current = np
        NowPlayingStore.save(np)
        if artworkChanged, let s = np.artworkURL, let url = URL(string: s) {
            downloadArtwork(url, for: s)
        } else {
            reload()
        }
    }

    func toggle() {
        web?.evaluateJavaScript("window.__ytmToggle && window.__ytmToggle()")
    }

    private func reload() {
        WidgetCenter.shared.reloadTimelines(ofKind: NowPlayingStore.widgetKind)
    }

    private func downloadArtwork(_ url: URL, for src: String) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self, let file = NowPlayingStore.artworkFile else { return }
            if let data, let image = UIImage(data: data), let jpeg = Self.resized(image, side: 400).jpegData(compressionQuality: 0.85) {
                try? jpeg.write(to: file, options: .atomic)
            } else {
                try? FileManager.default.removeItem(at: file)
            }
            DispatchQueue.main.async {
                // Só atualiza se a faixa não mudou de novo durante o download.
                if self.current.artworkURL == src { self.reload() }
            }
        }.resume()
    }

    private static func resized(_ image: UIImage, side: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { _ in
            // Preenche o quadrado cortando as sobras (capas de vídeo são 16:9).
            let s = max(side / image.size.width, side / image.size.height)
            let w = image.size.width * s, h = image.size.height * s
            image.draw(in: CGRect(x: (side - w) / 2, y: (side - h) / 2, width: w, height: h))
        }
    }
}
