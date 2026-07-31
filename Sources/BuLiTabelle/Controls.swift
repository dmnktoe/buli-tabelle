import SwiftUI

/// XP-Druckknopf: erhabene Fläche, die beim Drücken eindrückt.
struct XPButtonStyle: ButtonStyle {
    var face: Color = XP.face
    var emphasized = false
    var fill = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.tahoma(11))
            .foregroundStyle(.black)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 4)
            .padding(.horizontal, fill ? 3 : 9)
            .frame(maxWidth: fill ? CGFloat.infinity : nil)
            .background(face)
            .bevel(sunken: configuration.isPressed)
            .overlay(
                emphasized
                    ? Rectangle().strokeBorder(Color.black.opacity(0.75), lineWidth: 1).padding(-1)
                    : nil
            )
            .contentShape(Rectangle())
    }
}

struct XPButton: View {
    let title: String
    var face: Color = XP.face
    var emphasized = false
    var fill = true
    let action: () -> Void

    init(
        _ title: String,
        face: Color = XP.face,
        emphasized: Bool = false,
        fill: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.face = face
        self.emphasized = emphasized
        self.fill = fill
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
        }
        .buttonStyle(XPButtonStyle(face: face, emphasized: emphasized, fill: fill))
    }
}

/// Eingedrücktes Kästchen mit Häkchen im XP-Stil.
struct XPCheckboxStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 6) {
                ZStack {
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 13, height: 13)
                        .bevel(sunken: true)
                    if configuration.isOn {
                        Text("✓")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.black)
                    }
                }
                configuration.label
                    .font(.tahoma(11))
                    .foregroundStyle(.black)
            }
        }
        .buttonStyle(.plain)
    }
}

/// Eingedrücktes Auswahlfeld mit XP-Pfeil, öffnet ein natives Menü.
struct RetroDropdown<T: Hashable>: View {
    let items: [T]
    let display: (T) -> String
    @Binding var selection: T

    var body: some View {
        Menu {
            ForEach(items, id: \.self) { item in
                Button(display(item)) { selection = item }
            }
        } label: {
            HStack(spacing: 0) {
                Text(display(selection))
                    .font(.tahoma(11))
                    .foregroundStyle(.black)
                    .lineLimit(1)
                    .padding(.leading, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ZStack {
                    XP.face
                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.system(size: 6))
                        .foregroundStyle(.black)
                }
                .frame(width: 15)
                .bevel()
            }
            .frame(height: 19)
            .background(Color.white)
            .bevel(sunken: true)
        }
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .menuStyle(.button)
    }
}
