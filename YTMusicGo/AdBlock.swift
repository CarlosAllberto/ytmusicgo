import WebKit

/// Compila os arquivos rules*.json do bundle e os adiciona ao WKUserContentController.
/// Para listas extras, basta soltar um rules-algo.json em Resources/ (ver scripts/convert-filters.py).
enum AdBlock {
    static func install(in ucc: WKUserContentController, done: @escaping () -> Void) {
        let urls = (Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? [])
            .filter { $0.lastPathComponent.hasPrefix("rules") }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        let group = DispatchGroup()
        for url in urls {
            guard let json = try? String(contentsOf: url) else { continue }
            group.enter()
            let id = "ytmusicgo." + url.deletingPathExtension().lastPathComponent
            WKContentRuleListStore.default().compileContentRuleList(forIdentifier: id, encodedContentRuleList: json) { list, error in
                if let list { ucc.add(list) } else { NSLog("YTMusicGo: regras %@ inválidas: %@", id, "\(String(describing: error))") }
                group.leave()
            }
        }
        group.notify(queue: .main, execute: done)
    }
}
