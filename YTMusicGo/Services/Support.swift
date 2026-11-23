import Foundation

extension URL {
    // Miniaturas do YouTube vêm pequenas (=w60-h60...); pede a mesma imagem em `px` pixels para telas grandes.
    func sized(_ px: Int) -> URL {
        var s = absoluteString
        guard s.contains("googleusercontent.com") || s.contains("ggpht.com"),
              let r = s.range(of: "=[ws]\\d+[^/]*$", options: .regularExpression) else { return self }
        s.replaceSubrange(r, with: "=w\(px)-h\(px)-l90-rj")
        return URL(string: s) ?? self
    }
}
