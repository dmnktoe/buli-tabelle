import SwiftUI

extension XP {
    /// Rot der Live-Anzeigen – dasselbe Bundesliga-Rot wie in der Fenster-Chrome.
    static let liveRed = bundesligaRed
    /// Hintergrund einer Zeile, in der gerade ein Tor gefallen ist.
    static let goalFlash = Color(hex: 0xFFF0B0)

    static let liveGradient = LinearGradient(
        colors: [bundesligaRed, bundesligaRedDark],
        startPoint: .top, endPoint: .bottom
    )
}

/// Blinkender Punkt. Der Takt kommt aus der Uhr statt aus einer Animation –
/// so blinkt jeder Punkt im Fenster im Gleichschritt, wie es sich gehört.
struct LiveDot: View {
    var size: CGFloat = 7
    var color: Color = XP.liveRed

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.6)) { timeline in
            let lit = Int(timeline.date.timeIntervalSinceReferenceDate / 0.6) % 2 == 0
            Circle()
                .fill(color)
                .frame(width: size, height: size)
                .opacity(lit ? 1 : 0.3)
        }
        .frame(width: size, height: size)
    }
}

/// Rotes „LIVE“-Schild, wahlweise mit Spielminute.
struct LiveBadge: View {
    var minute: String? = nil
    var compact = false

    var body: some View {
        HStack(spacing: 3) {
            LiveDot(size: compact ? 5 : 6, color: .white)
            Text(minute.map({ "LIVE \($0)" }) ?? "LIVE")
                .font(.tahoma(compact ? 8 : 9, bold: true))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 4)
        .frame(height: compact ? 12 : 14)
        .background(XP.liveGradient)
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .strokeBorder(Color.white.opacity(0.5), lineWidth: 0.5)
        )
    }
}

/// Die Live-Leiste. Sie tritt an die Stelle des Infobands, solange etwas läuft:
/// Sie nimmt keine zusätzliche Höhe weg und sagt in einer Zeile, was los ist.
struct LiveStrip: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        HStack(spacing: 8) {
            LiveBadge()
            Text(model.live.headline)
                .font(.tahoma(11, bold: true))
                .foregroundStyle(.black)
                .lineLimit(1)
                .help(model.liveMinuteHint)

            Spacer(minLength: 4)

            // Gespielt wird woanders? Dann führt hier der Weg hin. Erst wenn man
            // auf den laufenden Spieltag sieht, ist die Einrechnung die Frage.
            if let period = model.livePeriodElsewhere {
                Button {
                    model.jumpToSpieltag(period)
                } label: {
                    Text("→ \(model.periodLabel(period)) anzeigen")
                        .font(.tahoma(11))
                        .underline()
                        .foregroundStyle(XP.linkBlue)
                        .lineLimit(1)
                }
                .buttonStyle(.plain)
            } else if !model.liga.isCup {
                Toggle("in Tabelle einrechnen", isOn: $model.liveInTable)
                    .toggleStyle(XPCheckboxStyle())
                    .help("Rechnet die laufenden Spiele in Punkte, Tore und Platzierung ein.")
            }

            Text(model.liveUpdatedText)
                .font(.tahoma(10))
                .foregroundStyle(XP.darkShadow)
                .lineLimit(1)
                .help("Aktualisiert sich während der Spiele von selbst.")
        }
        .padding(.horizontal, 8)
        .frame(height: 22)
        .background(Color.white)
        .overlay(alignment: .leading) { XP.liveRed.frame(width: 3) }
    }
}
