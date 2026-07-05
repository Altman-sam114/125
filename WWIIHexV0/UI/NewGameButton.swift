import SwiftUI

struct NewGameButton: View {
    let action: () -> Void
    var isTangSongScenario = false

    var body: some View {
        Button(action: action) {
            Label(isTangSongScenario ? "新局" : "NEW GAME", systemImage: "arrow.counterclockwise")
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .buttonStyle(.bordered)
    }
}
