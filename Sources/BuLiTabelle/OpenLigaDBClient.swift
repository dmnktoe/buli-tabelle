import Foundation

/// Dünner, typisierter Client für die OpenLigaDB-JSON-API.
struct OpenLigaDBClient {
    static let shared = OpenLigaDBClient()

    private let baseURL = "https://api.openligadb.de/"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    private func request(_ path: String, fresh: Bool) throws -> URLRequest {
        guard let url = URL(string: baseURL + path) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        // Live-Abfragen dürfen sich nicht am Cache bedienen – sonst steht der
        // Spielstand still, obwohl längst ein Tor gefallen ist.
        if fresh { request.cachePolicy = .reloadIgnoringLocalCacheData }
        return request
    }

    /// Lädt und dekodiert eine beliebige API-Ressource (case-unabhängig).
    func fetch<T: Decodable>(_ path: String, fresh: Bool = false) async throws -> T {
        let prepared = try request(path, fresh: fresh)
        let (data, _) = try await session.data(for: prepared)
        return try JSONDecoder.openLigaDB.decode(T.self, from: data)
    }

    /// Alle Spiele einer Liga & Saison.
    func matches(liga: Liga, season: Int) async throws -> [OLMatch] {
        try await fetch("getmatchdata/\(liga.rawValue)/\(season)")
    }

    /// Die Spiele eines einzelnen Spieltags bzw. einer Pokalrunde. Für den
    /// Live-Abgleich, weil dafür nicht die ganze Saison neu geladen werden muss.
    func matches(liga: Liga, season: Int, period: Int) async throws -> [OLMatch] {
        try await fetch("getmatchdata/\(liga.rawValue)/\(season)/\(period)", fresh: true)
    }

    /// Zeitstempel der letzten Änderung an einer Saison.
    ///
    /// Die Antwort ist ein nackter JSON-String. Sie kostet ein paar Byte und
    /// erspart uns die Spieldaten, solange sich nichts getan hat.
    func lastChangeDate(liga: Liga, season: Int) async throws -> String {
        let prepared = try request("getlastchangedate/\(liga.rawValue)/\(season)", fresh: true)
        let (data, response) = try await session.data(for: prepared)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        let stamp = String(decoding: data, as: UTF8.self)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\" \n\r\t"))
        guard !stamp.isEmpty else { throw URLError(.cannotParseResponse) }
        return stamp
    }

    /// Torjägerliste einer Liga & Saison.
    func goalGetters(liga: Liga, season: Int) async throws -> [OLGoalGetter] {
        try await fetch("getgoalgetters/\(liga.rawValue)/\(season)")
    }
}
