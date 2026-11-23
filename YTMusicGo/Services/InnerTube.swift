import Foundation

struct Item: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    var thumb: URL?
    let videoId: String?   // toca
    let browseId: String?  // abre página
    let isRow: Bool        // linha de lista (faixa) em vez de card de carrossel
    var artistName: String? = nil  // primeiro artista do subtítulo, clicável
    var artistId: String? = nil
}

struct Section: Identifiable {
    let id = UUID()
    let title: String
    let items: [Item]
}

struct Page {
    var title = ""
    var subtitle = ""
    var isArtist = false
    var channelId: String?  // artista: canal para inscrever-se
    var subscribed = false
    var thumb: URL?
    var sections: [Section] = []
    var continuation: String?
}

enum InnerTube {
    static func browse(_ browseId: String) async throws -> Page {
        parse(try await post("browse", ["browseId": browseId]))
    }

    // Home: logado, segue até 3 continuations; falha ou página vazia só encerra.
    static func home() async throws -> Page {
        var page = try await browse("FEmusic_home")
        guard await Auth.shared.headers() != nil else { return page }
        if let subs = try? await subscribedArtists() { page.sections.insert(subs, at: 0) }
        for _ in 0..<3 {
            guard let t = page.continuation,
                  let next = try? parse(await post("browse", ["continuation": t], query: "&ctoken=\(t)&continuation=\(t)&type=next")),
                  !next.sections.isEmpty else { break }
            page.sections += next.sections; page.continuation = next.continuation
        }
        return page
    }

    // Artistas inscritos: a lista vem em linhas, mas na home aparece como carrossel de cards redondos.
    private static func subscribedArtists() async throws -> Section? {
        let items = try await browse("FEmusic_library_corpus_artists").sections.flatMap(\.items)
            .map { Item(title: $0.title, subtitle: $0.subtitle, thumb: $0.thumb, videoId: nil, browseId: $0.browseId, isRow: false) }
        return items.isEmpty ? nil : Section(title: "Artistas inscritos", items: items)
    }

    // Letra: o endpoint `next` aponta para uma página MPLYt..., cujo texto vem numa prateleira de descrição.
    static func lyrics(_ videoId: String) async -> String? {
        func find(_ n: Any, _ pred: @escaping (String) -> Bool) -> String? {
            if let s = n as? String { return pred(s) ? s : nil }
            if let d = n as? [String: Any] { return d.values.lazy.compactMap { find($0, pred) }.first }
            return (n as? [Any])?.lazy.compactMap { find($0, pred) }.first
        }
        guard let next = try? await post("next", ["videoId": videoId]),
              let id = find(next, { $0.hasPrefix("MPLYt") }),
              let page = try? await post("browse", ["browseId": id]) else { return nil }
        func shelf(_ n: Any) -> [String: Any]? {
            if let d = n as? [String: Any] { return (d["musicDescriptionShelfRenderer"] as? [String: Any]) ?? d.values.lazy.compactMap(shelf).first }
            return (n as? [Any])?.lazy.compactMap(shelf).first
        }
        let t = text(shelf(page)?["description"])
        return t.isEmpty ? nil : t
    }

    // Foto da conta logada.
    static func avatar() async -> URL? {
        guard let json = try? await post("account/account_menu", [:]) else { return nil }
        func find(_ n: Any) -> URL? {
            if let d = n as? [String: Any] {
                if let p = d["accountPhoto"] { return thumb(p) }
                return d.values.lazy.compactMap(find).first
            }
            return (n as? [Any])?.lazy.compactMap(find).first
        }
        return find(json)
    }

    // Biblioteca: playlists/álbuns salvos e músicas curtidas (as curtidas são opcionais).
    static func library() async throws -> Page {
        var page = try await browse("FEmusic_liked_playlists")
        if let subs = try? await subscribedArtists() { page.sections.insert(subs, at: 0) }
        // O card "Músicas curtidas" levaria à mesma lista que vem logo abaixo; sai o card e a lista ganha o título.
        page.sections = page.sections.map { Section(title: $0.title, items: $0.items.filter { $0.browseId != "VLLM" }) }.filter { !$0.items.isEmpty }
        if let liked = try? await browse("VLLM") {
            page.sections += liked.sections.map { $0.title.isEmpty ? Section(title: "Músicas curtidas", items: $0.items) : $0 }
        }
        return page
    }

    // Sem filtro a busca só devolve o card do topo; por tipo vêm as prateleiras. Em paralelo, na ordem das seções.
    // shortcut: params fixos de artistas, músicas e álbuns; atualizar se o YouTube mudar o formato.
    static func search(_ query: String) async throws -> Page {
        let ps = ["EgWKAQIgAWoMEA4QChADEAQQCRAF", "EgWKAQIIAWoMEA4QChADEAQQCRAF", "EgWKAQIYAWoMEA4QChADEAQQCRAF"]
        let pages = try await withThrowingTaskGroup(of: (Int, Page).self) { g in
            for (i, p) in ps.enumerated() { g.addTask { (i, parse(try await post("search", ["query": query, "params": p]))) } }
            return try await g.reduce(into: [(Int, Page)]()) { $0.append($1) }
        }.sorted { $0.0 < $1.0 }
        var page = Page()
        // O card do topo é opcional: falha aqui não derruba a busca.
        if let json = try? await post("search", ["query": query]),
           let top = parse(json, card: true).sections.first(where: { $0.title == "Melhor resultado" }) { page.sections.append(top) }
        page.sections += pages.flatMap(\.1.sections)
        return page
    }

    /// Inscreve ou cancela a inscrição no canal do artista. Exige login.
    static func subscribe(_ channelId: String, _ on: Bool) async throws {
        let json = try await post(on ? "subscription/subscribe" : "subscription/unsubscribe", ["channelIds": [channelId]])
        // Recusa (ex.: sessão expirada) vem como JSON com "error", não como falha de rede.
        if (json as? [String: Any])?["error"] != nil { throw URLError(.userAuthenticationRequired) }
    }

    private static func post(_ endpoint: String, _ extra: [String: Any], query: String = "") async throws -> Any {
        var req = URLRequest(url: URL(string: "https://music.youtube.com/youtubei/v1/\(endpoint)?prettyPrint=false\(query)")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("https://music.youtube.com", forHTTPHeaderField: "Origin")
        // Logado: cookies e SAPISIDHASH à mão; sem cookie segue anônimo.
        if let h = await Auth.shared.headers() {
            req.httpShouldHandleCookies = false
            h.forEach { req.setValue($1, forHTTPHeaderField: $0) }
        }
        // shortcut: clientVersion fixo, o YouTube pode recusar versões antigas; atualizar quando quebrar.
        var body: [String: Any] = ["context": ["client": ["clientName": "WEB_REMIX", "clientVersion": "1.20241127.01.00", "hl": "pt", "gl": "BR"]]]
        body.merge(extra) { $1 }
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONSerialization.jsonObject(with: data)
    }

    // O JSON é profundo e muda de forma; varrer por prateleiras é mais estável que um caminho fixo.
    private static func parse(_ json: Any, card: Bool = false) -> Page {
        var page = Page()
        func walk(_ node: Any) {
            if let d = node as? [String: Any] {
                for (k, v) in d where page.title.isEmpty && ["musicImmersiveHeaderRenderer", "musicResponsiveHeaderRenderer", "musicDetailHeaderRenderer", "musicVisualHeaderRenderer"].contains(k) {
                    let h = v as? [String: Any]
                    page.title = text(h?["title"]); page.thumb = thumb(v)
                    page.isArtist = k == "musicImmersiveHeaderRenderer"
                    if let s = (h?["subscriptionButton"] as? [String: Any])?["subscribeButtonRenderer"] as? [String: Any] {
                        page.channelId = s["channelId"] as? String; page.subscribed = s["subscribed"] as? Bool ?? false
                    }
                    page.subtitle = text(h?["monthlyListenerCount"]).isEmpty ? text(h?["subtitle"]) : text(h?["monthlyListenerCount"])
                }
                if page.continuation == nil, let c = (d["nextContinuationData"] as? [String: Any])?["continuation"] as? String { page.continuation = c }
                if card, let c = d["musicCardShelfRenderer"] as? [String: Any] {
                    let r = (c["title"] as? [String: Any])?["runs"] as? [[String: Any]]
                    let nav = r?.first?["navigationEndpoint"] as? [String: Any]
                    let bid = (nav?["browseEndpoint"] as? [String: Any])?["browseId"] as? String
                    let i = Item(title: text(c["title"]), subtitle: text(c["subtitle"]), thumb: thumb(c["thumbnail"]),
                                 videoId: (nav?["watchEndpoint"] as? [String: Any])?["videoId"] as? String,
                                 browseId: bid, isRow: bid?.hasPrefix("UC") != true)  // artista vira card
                    if i.videoId != nil || i.browseId != nil { page.sections.append(Section(title: "Melhor resultado", items: [i])) }
                    return
                }
                for k in ["musicCarouselShelfRenderer", "musicShelfRenderer", "musicPlaylistShelfRenderer", "gridRenderer"] {
                    if let shelf = d[k] as? [String: Any] { page.sections.append(section(shelf)); return }
                }
                d.values.forEach(walk)
            } else if let a = node as? [Any] { a.forEach(walk) }
        }
        walk(json)
        page.sections.removeAll { $0.items.isEmpty }
        // Faixas de álbum não trazem miniatura própria; usa a capa da página.
        page.sections = page.sections.map { s in
            Section(title: s.title, items: s.items.map { var i = $0; i.thumb = i.thumb ?? page.thumb; return i })
        }
        return page
    }

    private static func section(_ shelf: [String: Any]) -> Section {
        let h = shelf["header"] as? [String: Any]
        let header = h?["musicCarouselShelfBasicHeaderRenderer"] as? [String: Any] ?? h?["gridHeaderRenderer"] as? [String: Any]
        let title = text((header ?? shelf)["title"])
        // gridRenderer usa "items"; as prateleiras usam "contents".
        let items = ((shelf["contents"] ?? shelf["items"]) as? [[String: Any]] ?? []).compactMap(item)
        return Section(title: title, items: items)
    }

    private static func item(_ n: [String: Any]) -> Item? {
        func ids(_ r: [String: Any]) -> (String?, String?) {
            let nav = r["navigationEndpoint"] as? [String: Any]
            return ((nav?["watchEndpoint"] as? [String: Any])?["videoId"] as? String,
                    (nav?["browseEndpoint"] as? [String: Any])?["browseId"] as? String)
        }
        // Primeiro run do subtítulo que aponta para um canal de artista (UC...).
        func artist(_ nodes: [Any?]) -> (String, String)? {
            for n in nodes { for run in (n as? [String: Any])?["runs"] as? [[String: Any]] ?? [] {
                if let id = ((run["navigationEndpoint"] as? [String: Any])?["browseEndpoint"] as? [String: Any])?["browseId"] as? String,
                   id.hasPrefix("UC"), let t = run["text"] as? String { return (t, id) }
            } }
            return nil
        }
        var out: Item?
        if let r = n["musicTwoRowItemRenderer"] as? [String: Any] {
            let (v, b) = ids(r)
            out = Item(title: text(r["title"]), subtitle: text(r["subtitle"]), thumb: thumb(r), videoId: v, browseId: b, isRow: false)
            if b?.hasPrefix("UC") != true, let a = artist([r["subtitle"]]) { out?.artistName = a.0; out?.artistId = a.1 }
        } else if let r = n["musicResponsiveListItemRenderer"] as? [String: Any] {
            let raw = (r["flexColumns"] as? [[String: Any]] ?? []).map { ($0["musicResponsiveListItemFlexColumnRenderer"] as? [String: Any])?["text"] }
            let cols = raw.map(text)
            let (_, b) = ids(r)
            let v = (r["playlistItemData"] as? [String: Any])?["videoId"] as? String
            // Artista (UC sem videoId) vira card redondo; o "Artista" do subtítulo é redundante.
            let isArtist = v == nil && b?.hasPrefix("UC") == true
            out = Item(title: cols.first ?? "", subtitle: cols.dropFirst().filter { !$0.isEmpty }.joined(separator: " • ").replacingOccurrences(of: isArtist ? "Artista • " : "\u{0}", with: ""), thumb: thumb(r), videoId: v, browseId: b, isRow: !isArtist)
            if b?.hasPrefix("UC") != true, let a = artist(Array(raw.dropFirst())) { out?.artistName = a.0; out?.artistId = a.1 }
        }
        guard let i = out, !i.title.isEmpty, i.videoId != nil || i.browseId != nil else { return nil }
        return i
    }

    private static func text(_ node: Any?) -> String {
        let runs = (node as? [String: Any])?["runs"] as? [[String: Any]] ?? []
        return runs.compactMap { $0["text"] as? String }.joined()
    }

    // Maior miniatura que aparecer dentro do nó.
    private static func thumb(_ node: Any?) -> URL? {
        if let d = node as? [String: Any] {
            if let t = d["thumbnails"] as? [[String: Any]], let u = t.last?["url"] as? String { return URL(string: u) }
            for v in d.values { if let u = thumb(v) { return u } }
        } else if let a = node as? [Any] {
            for v in a { if let u = thumb(v) { return u } }
        }
        return nil
    }
}
