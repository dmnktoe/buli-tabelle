import SwiftUI

/// Ein-Pixel-Kanten oben-links vs. unten-rechts – Basis für den 3D-Bevel-Look.
private struct EdgeLines: View {
    let topLeading: Color
    let bottomTrailing: Color

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                topLeading.frame(height: 1)
                Spacer(minLength: 0)
                bottomTrailing.frame(height: 1)
            }
            HStack(spacing: 0) {
                topLeading.frame(width: 1)
                Spacer(minLength: 0)
                bottomTrailing.frame(width: 1)
            }
        }
        .allowsHitTesting(false)
    }
}

/// Doppelter XP-Bevel-Rahmen; `sunken` kehrt Licht/Schatten um (eingedrückt).
struct BevelBorder: ViewModifier {
    var sunken = false

    func body(content: Content) -> some View {
        content
            .overlay(
                EdgeLines(
                    topLeading: sunken ? XP.shadow : XP.face,
                    bottomTrailing: sunken ? XP.face : XP.shadow
                )
                .padding(1)
            )
            .overlay(
                EdgeLines(
                    topLeading: sunken ? XP.darkShadow : XP.highlight,
                    bottomTrailing: sunken ? XP.highlight : XP.darkShadow
                )
            )
    }
}

extension View {
    func bevel(sunken: Bool = false) -> some View {
        modifier(BevelBorder(sunken: sunken))
    }
}
