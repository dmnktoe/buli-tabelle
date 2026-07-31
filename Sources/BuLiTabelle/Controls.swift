import SwiftUI

// MARK: - Knöpfe

/// Glasknopf: hebt sich beim Überfahren an, sinkt beim Drücken leicht ein.
struct GlassButtonStyle: ButtonStyle {
    /// Hervorgehoben – gefüllt in Markenrot statt durchscheinend.
    var prominent = false
    var radius: CGFloat = Theme.Radius.control
    var insets = EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)

    func makeBody(configuration: Configuration) -> some View {
        Surface(configuration: configuration, prominent: prominent, radius: radius, insets: insets)
    }

    /// Eigener View, damit Hover-Zustand und Aktivierung beobachtbar sind –
    /// ein `ButtonStyle` selbst hängt nicht im View-Graph.
    private struct Surface: View {
        let configuration: ButtonStyleConfiguration
        let prominent: Bool
        let radius: CGFloat
        let insets: EdgeInsets

        @Environment(\.isEnabled) private var isEnabled
        @State private var hovering = false

        var body: some View {
            let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
            return configuration.label
                .font(.ui(12, .medium))
                .foregroundStyle(prominent ? Color.white : Color.primary)
                .padding(insets)
                .background {
                    if prominent {
                        shape
                            .fill(Theme.accentGradient)
                            .overlay(shape.strokeBorder(Color.white.opacity(0.3), lineWidth: 1))
                            .shadow(color: Theme.accent.opacity(0.35), radius: 8, y: 3)
                    } else {
                        GlassSurface(shape: shape, tone: .control)
                    }
                }
                .overlay {
                    if hovering && isEnabled {
                        shape.fill(Color.white.opacity(prominent ? 0.14 : 0.22))
                    }
                }
                .clipShape(shape)
                .contentShape(shape)
                .opacity(isEnabled ? 1 : 0.4)
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .animation(Theme.quick, value: configuration.isPressed)
                .animation(Theme.quick, value: hovering)
                .onHover { hovering = $0 }
        }
    }
}

/// Knopf mit Beschriftung im Glas-Look.
struct GlassButton: View {
    let title: String
    var systemImage: String?
    var prominent = false
    let action: () -> Void

    init(
        _ title: String,
        systemImage: String? = nil,
        prominent: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.prominent = prominent
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let systemImage {
                    Image(systemName: systemImage).font(.system(size: 11, weight: .semibold))
                }
                Text(title)
            }
        }
        .buttonStyle(GlassButtonStyle(prominent: prominent))
    }
}

/// Quadratischer Knopf mit reinem Symbol – für die Kopfleiste.
struct IconButton: View {
    let systemName: String
    let help: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 30, height: 28)
        }
        .buttonStyle(GlassButtonStyle(radius: 9, insets: EdgeInsets()))
        .help(help)
    }
}

/// Symbolknopf, der ein Menü öffnet.
struct IconMenu<Content: View>: View {
    let systemName: String
    let help: String
    @ViewBuilder let content: Content

    var body: some View {
        Menu {
            content
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.primary)
                .frame(width: 30, height: 28)
                .glass(.control, radius: 9)
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .fixedSize()
        .help(help)
    }
}

// MARK: - Auswahl

/// Auswahlfeld im Glas-Look; öffnet ein natives Menü.
struct GlassPicker<T: Hashable>: View {
    let items: [T]
    let display: (T) -> String
    @Binding var selection: T
    /// Kleines Symbol links im Feld.
    var systemImage: String? = nil

    var body: some View {
        Menu {
            ForEach(items, id: \.self) { item in
                Toggle(
                    display(item),
                    isOn: Binding(
                        get: { item == selection },
                        set: { isOn in if isOn { selection = item } }
                    )
                )
            }
        } label: {
            HStack(spacing: 5) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                Text(display(selection))
                    .font(.ui(12, .medium))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .frame(height: 28)
            .glass(.control, radius: Theme.Radius.control)
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
    }
}

/// Segmentierte Auswahl mit gleitender Glaspille.
struct GlassSegmented<T: Hashable & Identifiable>: View {
    let items: [T]
    let display: (T) -> String
    @Binding var selection: T

    @Namespace private var indicator

    var body: some View {
        HStack(spacing: 2) {
            ForEach(items) { item in
                let active = item == selection
                Button {
                    withAnimation(Theme.spring) { selection = item }
                } label: {
                    Text(display(item))
                        .font(.ui(12, active ? .semibold : .regular))
                        .foregroundStyle(active ? Color.primary : Color.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 24)
                        .background {
                            if active {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.primary.opacity(0.10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                                    )
                                    .matchedGeometryEffect(id: "segment", in: indicator)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .glass(.control, radius: 12)
    }
}

// MARK: - Zustände

/// Ladeanzeige für leere Tabellen und Panels.
struct LoadingIndicator: View {
    let text: String

    var body: some View {
        VStack(spacing: 10) {
            ProgressView()
                .progressViewStyle(.circular)
                .controlSize(.small)
            Text(text)
                .font(.ui(11))
                .foregroundStyle(.secondary)
        }
    }
}

/// Hinweis, wenn nichts anzuzeigen ist.
struct EmptyStateView: View {
    let systemImage: String
    let text: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(.tertiary)
            Text(text)
                .font(.ui(11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 24)
    }
}
