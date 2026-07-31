import SwiftUI
import AppKit

// MARK: - Echter Fenster-Blur

/// `NSVisualEffectView` als SwiftUI-Fläche – das einzige Mittel, um auf macOS
/// den Inhalt *hinter* dem Fenster durchscheinen zu lassen.
struct VisualEffect: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .underWindowBackground
    var blending: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blending
        view.state = .active
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = material
        view.blendingMode = blending
        view.state = .active
    }
}

// MARK: - Glasflächen

/// Wie stark eine Glasfläche vom Untergrund abhebt.
enum GlassTone {
    /// Große Flächen: Tabelle, Spieltagsliste.
    case card
    /// Knöpfe, Auswahlfelder, Pillen – liegen auf Karten und brauchen mehr Körper.
    case control
    /// Frei schwebende Fenster (Info, Einstellungen) mit kräftigem Schatten.
    case floating

    fileprivate var material: Material {
        switch self {
        case .card: return .regularMaterial
        case .control: return .thickMaterial
        case .floating: return .regularMaterial
        }
    }

    /// Deckende Ersatzfläche für den Aufnahmemodus (siehe `Theme.capturing`).
    fileprivate var captureFill: Color {
        let base = Color.adaptive(light: 0xFFFFFF, dark: 0x2C2E33)
        switch self {
        case .card: return base.opacity(0.80)
        case .control: return base.opacity(0.92)
        case .floating: return base.opacity(0.94)
        }
    }

    fileprivate var shadow: (color: Color, radius: CGFloat, y: CGFloat) {
        switch self {
        case .card: return (.black.opacity(0.16), 18, 8)
        case .control: return (.black.opacity(0.12), 6, 2)
        case .floating: return (.black.opacity(0.30), 30, 14)
        }
    }
}

/// Eine Glasscheibe: Material, sanfter Lichteinfall von oben, feine Kante.
struct GlassSurface<S: InsettableShape>: View {
    let shape: S
    var tone: GlassTone = .card
    /// Optionale Einfärbung, etwa der Akzent bei ausgewählten Elementen.
    var tint: Color? = nil

    private var fill: AnyShapeStyle {
        Theme.capturing ? AnyShapeStyle(tone.captureFill) : AnyShapeStyle(tone.material)
    }

    var body: some View {
        let shadow = tone.shadow
        return shape
            .fill(fill)
            .overlay {
                if let tint {
                    shape.fill(tint.opacity(0.18))
                }
            }
            .overlay {
                // Lichtkante: oben hell, nach unten auslaufend.
                shape.fill(
                    LinearGradient(
                        colors: [.white.opacity(0.16), .white.opacity(0.02)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
            }
            .overlay {
                shape.strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.55), .white.opacity(0.08)],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: 1
                )
            }
            .compositingGroup()
            .shadow(color: shadow.color, radius: shadow.radius, y: shadow.y)
    }
}

/// Legt eine Glasfläche hinter den Inhalt.
///
/// Ab macOS 26 übernimmt das echte Liquid Glass des Systems, darunter tritt die
/// handgebaute Scheibe an seine Stelle. Der Übergang steckt bewusst nur hier.
private struct GlassBackground: ViewModifier {
    let tone: GlassTone
    let radius: CGFloat
    let tint: Color?

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        #if compiler(>=6.2)
        if #available(macOS 26.0, *), !Theme.capturing {
            return AnyView(content.glassEffect(.regular, in: shape))
        }
        #endif
        return AnyView(content.background(GlassSurface(shape: shape, tone: tone, tint: tint)))
    }
}

extension View {
    /// Glasfläche mit abgerundeten Ecken hinter dem Inhalt.
    func glass(
        _ tone: GlassTone = .card,
        radius: CGFloat = Theme.Radius.card,
        tint: Color? = nil
    ) -> some View {
        modifier(GlassBackground(tone: tone, radius: radius, tint: tint))
    }
}

// MARK: - Fensterhintergrund

/// Untergrund des Fensters: Schreibtisch-Blur mit einem warmen Schimmer in
/// Markenrot. Er gibt dem Glas darüber überhaupt erst etwas zum Brechen.
struct WindowBackdrop: View {
    var body: some View {
        ZStack {
            if Theme.capturing {
                LinearGradient(
                    colors: [
                        Color.adaptive(light: 0xF3F4F7, dark: 0x1B1D21),
                        Color.adaptive(light: 0xE4E7ED, dark: 0x141518),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
            } else {
                VisualEffect(material: .underWindowBackground, blending: .behindWindow)
            }

            RadialGradient(
                colors: [Theme.accent.opacity(0.16), .clear],
                center: .init(x: 0.08, y: -0.05),
                startRadius: 0,
                endRadius: 420
            )
            RadialGradient(
                colors: [Theme.zoneChampions.opacity(0.10), .clear],
                center: .init(x: 1.05, y: 1.0),
                startRadius: 0,
                endRadius: 380
            )
        }
        .allowsHitTesting(false)
    }
}
