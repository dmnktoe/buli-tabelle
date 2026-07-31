import SwiftUI

/// Vereinswappen aus OpenLigaDB. SVGs werden serverseitig als PNG gerastert;
/// fehlt/lädt kein Bild, erscheinen die Anfangsbuchstaben als Fallback.
struct TeamIconView: View {
    let urlString: String?
    var fallback: String? = nil

    private func initials(_ s: String) -> String {
        let words = s.split(whereSeparator: { $0 == " " || $0 == "-" })
            .filter { $0.first?.isLetter == true }
        let letters = words.prefix(3).compactMap { $0.first }
        return String(letters).uppercased()
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2).fill(Color(hex: 0xD0CDC0))
            if let f = fallback.map(initials), !f.isEmpty {
                Text(f)
                    .font(.tahoma(7, bold: true))
                    .foregroundStyle(XP.darkShadow)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
        }
    }

    /// wsrv.nl rastert SVGs (die AsyncImage nicht rendern kann) zu PNG.
    private func proxied(_ s: String) -> URL? {
        let unreserved = CharacterSet(
            charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
        )
        guard let enc = s.addingPercentEncoding(withAllowedCharacters: unreserved) else {
            return URL(string: s)
        }
        return URL(string: "https://wsrv.nl/?url=\(enc)&w=96&h=96&fit=inside&output=png")
    }

    private func imageURL(_ s: String) -> URL? {
        let path = s.split(separator: "?", maxSplits: 1).first.map(String.init) ?? s
        if path.lowercased().hasSuffix(".svg") { return proxied(s) }
        return URL(string: s) ?? proxied(s)
    }

    var body: some View {
        Group {
            if let s = urlString, let url = imageURL(s) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .interpolation(.none)
                            .aspectRatio(contentMode: .fit)
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: Col.icon, height: Col.icon)
        .clipped()
    }
}
