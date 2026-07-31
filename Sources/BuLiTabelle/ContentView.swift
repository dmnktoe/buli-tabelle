import SwiftUI

struct TableModeBar: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TableMode.allCases) { mode in
                let active = model.tableMode == mode
                Button {
                    model.tableMode = mode
                } label: {
                    Text(mode.display)
                        .font(.tahoma(11, bold: active))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 20)
                        .background(active ? Color.white : XP.face)
                        .bevel(sunken: active)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            TitleBar()
            InfoStrip()
            Color(hex: 0xC9C5B2).frame(height: 1)

            HStack(alignment: .top, spacing: 6) {
                ActionColumn()
                VStack(spacing: 5) {
                    FilterBar()
                    TableModeBar()
                    TablePanel()
                }
            }
            .padding(6)

            if model.showSpieltagMenu {
                MatchdayPanel()
            }
            SpieltagMenuBar()
            StatusBar()
        }
        .frame(width: 620)
        .background(XP.face)
        .sheet(item: $model.alert) { info in
            RetroAlertView(info: info) { model.alert = nil }
        }
    }
}
