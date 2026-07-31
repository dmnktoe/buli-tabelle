import SwiftUI
import AppKit

enum TitleButtonKind {
    case minimize, maximize, close
}

struct TitleButton: View {
    let kind: TitleButtonKind
    let action: () -> Void

    private var gradient: LinearGradient {
        switch kind {
        case .close:
            return LinearGradient(
                colors: [Color(hex: 0xF29179), Color(hex: 0xD64431), Color(hex: 0xB01E0F)],
                startPoint: .top, endPoint: .bottom
            )
        default:
            return LinearGradient(
                colors: [Color(hex: 0x7AA7F5), Color(hex: 0x3363C4), Color(hex: 0x1E4CA5)],
                startPoint: .top, endPoint: .bottom
            )
        }
    }

    private var symbol: String {
        switch kind {
        case .minimize: return "minus"
        case .maximize: return "square"
        case .close: return "xmark"
        }
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 3).fill(gradient)
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(Color.white.opacity(0.75), lineWidth: 1)
                Image(systemName: symbol)
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(.white)
                    .offset(y: kind == .minimize ? 3 : 0)
            }
            .frame(width: 21, height: 21)
        }
        .buttonStyle(.plain)
    }
}

struct TitleBar: View {
    @EnvironmentObject var model: AppModel
    @AppStorage("showMenuBarItem") private var showMenuBarItem = true
    @AppStorage("keepInMenuBar") private var keepInMenuBar = true

    private func closeAction() {
        if showMenuBarItem && keepInMenuBar {
            WindowBridge.shared.main?.close()
            NSApp.setActivationPolicy(.accessory)
        } else {
            NSApp.terminate(nil)
        }
    }

    var body: some View {
        HStack(spacing: 5) {
            MiniFlagIcon()
            Text("\(AppInfo.name) \(AppInfo.displayVersion)  ·  \(model.liga.display)  ·  Saison \(model.seasonShort)  ·  \(model.spieltag). Spieltag")
                .font(.tahoma(11, bold: true))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.55), radius: 0, x: 1, y: 1)
                .lineLimit(1)
            Spacer(minLength: 4)
            TitleButton(kind: .minimize) {
                WindowBridge.shared.main?.miniaturize(nil)
            }
            TitleButton(kind: .maximize) {}
                .opacity(0.55)
            TitleButton(kind: .close) {
                closeAction()
            }
        }
        .padding(.horizontal, 6)
        .frame(height: 28)
        .background(XP.titleGradient)
    }
}

struct InfoStrip: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        HStack(spacing: 6) {
            Text("1. und 2. Bundesliga sowie 3. Liga – jeder Spieltag seit 2004/05.")
                .font(.tahoma(11))
                .foregroundStyle(.black)
                .lineLimit(1)
            Spacer()
            Button {
                model.openDataSource()
            } label: {
                Text("Daten von OpenLigaDB")
                    .font(.tahoma(11))
                    .underline()
                    .foregroundStyle(XP.linkBlue)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .frame(height: 22)
        .background(Color.white)
    }
}
