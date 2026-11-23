import Foundation

// Roda os endpoints do InnerTube contra a API real (anônimo) e confere as regras do parser.
var falhas = 0
func check(_ ok: Bool, _ msg: String) { if !ok { falhas += 1; print("  FALHA: \(msg)") } }

func dump(_ nome: String, _ p: Page) {
    print("\n== \(nome): \"\(p.title)\" | \(p.subtitle) | artista=\(p.isArtist) | \(p.sections.count) seções")
    for s in p.sections {
        let i = s.items[0]
        print("  [\(s.title)] \(s.items.count) itens; ex: \(i.title) | \(i.subtitle) | v=\(i.videoId ?? "-") b=\(i.browseId ?? "-") row=\(i.isRow) art=\(i.artistName ?? "-")/\(i.artistId ?? "-") thumb=\(i.thumb != nil)")
    }
    for i in p.sections.flatMap(\.items) {
        if i.videoId == nil, i.browseId?.hasPrefix("UC") == true { check(!i.isRow, "artista em linha: \(i.title)") }
    }
}

@main struct Harness {
    static func main() async {
        do {
            let home = try await InnerTube.home()
            dump("home", home)
            check(!home.sections.isEmpty, "home vazia")

            var artistId: String?
            for q in ["Coldplay", "Anitta"] {
                let s = try await InnerTube.search(q)
                dump("busca \(q)", s)
                print("  títulos: \(s.sections.map(\.title))")
                check(s.sections.count >= 3, "busca \(q) com menos de 3 prateleiras")
                let musicas = s.sections.first { $0.title.lowercased().contains("músicas") }
                check(musicas?.items.allSatisfy(\.isRow) == true, "músicas não são linhas")
                check(musicas?.items.contains { $0.artistId?.hasPrefix("UC") == true } == true, "músicas sem artistId")
                artistId = artistId ?? s.sections.flatMap(\.items).first { $0.videoId == nil && $0.browseId?.hasPrefix("UC") == true }?.browseId
            }

            guard let aid = artistId else { check(false, "nenhum artista na busca"); exit(1) }
            let artista = try await InnerTube.browse(aid)
            dump("artista \(aid)", artista)
            check(artista.isArtist, "página de artista sem isArtist")

            let itens = artista.sections.flatMap(\.items)
            guard let album = itens.first(where: { $0.browseId?.hasPrefix("MPREb_") == true })?.browseId else { check(false, "artista sem álbum"); exit(1) }
            let a = try await InnerTube.browse(album)
            dump("álbum \(album)", a)
            // Só a primeira seção são as faixas; o resto são carrosséis de recomendação.
            let faixas = a.sections.first?.items ?? []
            check(!faixas.isEmpty && faixas.allSatisfy(\.isRow), "faixas do álbum não são linhas")
            check(faixas.allSatisfy { $0.thumb == a.thumb && a.thumb != nil }, "faixas não herdam a capa")

            let plId = itens.first(where: { $0.browseId?.hasPrefix("VL") == true })?.browseId
                ?? home.sections.flatMap(\.items).first(where: { $0.browseId?.hasPrefix("VL") == true })?.browseId
                ?? "VLRDCLAK5uy_kmPRjHDECIcuVwnKsx2Ng7fyNgFKWNJFs"
            let pl = try await InnerTube.browse(plId)
            dump("playlist \(plId)", pl)
            check(!pl.sections.isEmpty, "playlist vazia")

            guard let vid = faixas.first?.videoId else { check(false, "álbum sem videoId"); exit(1) }
            let letra = await InnerTube.lyrics(vid)
            print("\n== letra \(vid): \(letra.map { "\($0.count) chars; \($0.prefix(120).replacingOccurrences(of: "\n", with: " / "))" } ?? "nil")")
            check(letra != nil, "sem letra (pode ser faixa sem letra)")
        } catch { check(false, "erro: \(error)") }

        let en = "I used to rule the world\nSeas would rise when I gave the word\nNow in the morning I sleep alone"
        let pt = await Translate.text(en)
        print("\n== tradução:\n\(pt ?? "nil")")
        check(pt != nil && pt != en, "tradução falhou")

        let u = URL(string: "https://lh3.googleusercontent.com/abc=w60-h60-l90-rj")!
        check(u.sized(544).absoluteString == "https://lh3.googleusercontent.com/abc=w544-h544-l90-rj", "sized googleusercontent")
        check(URL(string: "https://yt3.ggpht.com/x=s88-c-k")!.sized(200).absoluteString == "https://yt3.ggpht.com/x=w200-h200-l90-rj", "sized ggpht")
        let other = URL(string: "https://i.ytimg.com/vi/x/hqdefault.jpg?sqp=w60-h60")!
        check(other.sized(200) == other, "sized mexeu em ytimg")

        print("\n\(falhas == 0 ? "OK" : "\(falhas) falha(s)")")
        exit(falhas == 0 ? 0 : 1)
    }
}
