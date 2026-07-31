import SwiftUI

/// Unbestimmter Fortschrittsbalken im XP-Stil: grüne Luna-Blöcke wandern
/// wie beim XP-Bootscreen durch eine eingesunkene weiße Leiste.
struct XPProgressBar: View {
    var width: CGFloat = 180

    private static let blockWidth: CGFloat = 9
    private static let blockGap: CGFloat = 2
    private static let blockCount = 5
    private static let cycle: Double = 1.8

    /// Grüner Verlauf der Blöcke wie im Luna-Fortschrittsbalken.
    private static let blockGradient = LinearGradient(
        colors: [Color(hex: 0xB6EFB6), Color(hex: 0x4FC24F), Color(hex: 0x1F9E1F)],
        startPoint: .top, endPoint: .bottom
    )

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let phase = (timeline.date.timeIntervalSinceReferenceDate / Self.cycle)
                .truncatingRemainder(dividingBy: 1)
            let chunk = CGFloat(Self.blockCount) * (Self.blockWidth + Self.blockGap) - Self.blockGap
            HStack(spacing: Self.blockGap) {
                ForEach(0..<Self.blockCount, id: \.self) { _ in
                    Rectangle()
                        .fill(Self.blockGradient)
                        .frame(width: Self.blockWidth)
                }
            }
            .padding(.vertical, 3)
            .offset(x: -chunk + phase * (width + chunk))
            .frame(width: width, height: 16, alignment: .leading)
            .clipped()
        }
        .background(Color.white)
        .bevel(sunken: true)
    }
}

/// Ladeanzeige für leere Tabellen: XP-Balken mit Statustext darunter.
struct XPLoadingIndicator: View {
    let text: String
    var barWidth: CGFloat = 180

    var body: some View {
        VStack(spacing: 8) {
            XPProgressBar(width: barWidth)
            Text(text)
                .font(.tahoma(11))
                .foregroundStyle(XP.darkShadow)
        }
    }
}
