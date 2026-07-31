import Foundation

/// Dünner, typisierter Client für die OpenLigaDB-JSON-API.
struct OpenLigaDBClient {
    static let shared = OpenLigaDBClient()

    private let baseURL = "https://api.openligadb.de/"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Lädt und dekodiert eine beliebige API-Ressource (case-unabhängig).
    func fetch<T: Decodable>(_ path: String) async throws -> T {
        guard let url = URL(string: baseURL + path) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder.openLigaDB.decode(T.self, from: data)
    }

    /// Alle Spiele einer Liga & Saison.
    func matches(liga: Liga, season: Int) async throws -> [OLMatch] {
        try await fetch("getmatchdata/\(liga.rawValue)/\(season)")
    }

    /// Torjägerliste einer Liga & Saison.
    func goalGetters(liga: Liga, season: Int) async throws -> [OLGoalGetter] {
        try await fetch("getgoalgetters/\(liga.rawValue)/\(season)")
    }
}
