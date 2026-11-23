import Foundation

// Tradução pelo endpoint gratuito do Google (sem chave); serve para letras.
enum Translate {
    static func text(_ s: String, to lang: String = "pt") async -> String? {
        // Blocos de linhas inteiras de até ~1500 caracteres para caber na URL.
        var blocks = [""]
        for line in s.components(separatedBy: "\n") {
            if blocks[blocks.count - 1].count + line.count > 1500, !blocks[blocks.count - 1].isEmpty { blocks.append("") }
            blocks[blocks.count - 1] += (blocks[blocks.count - 1].isEmpty ? "" : "\n") + line
        }
        func call(_ b: String, _ sl: String) async -> String? {
            let q = b.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
            guard let url = URL(string: "https://translate.googleapis.com/translate_a/single?client=gtx&sl=\(sl)&tl=\(lang)&dt=t&q=\(q)"),
                  let (data, _) = try? await URLSession.shared.data(from: url),
                  let j = (try? JSONSerialization.jsonObject(with: data)) as? [Any], let parts = j.first as? [[Any]] else { return nil }
            return parts.compactMap { $0.first as? String }.joined()
        }
        var out: [String] = []
        for b in blocks {
            guard var r = await call(b, "auto") else { return nil }
            // sl=auto às vezes erra e devolve o original; tenta de novo como inglês.
            if r == b, let r2 = await call(b, "en") { r = r2 }
            out.append(r)
        }
        return out.joined(separator: "\n")
    }
}
