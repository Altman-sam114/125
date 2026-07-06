#if os(macOS)
import SwiftUI

@main
struct WWIIHexV0MacApp: App {
    @StateObject private var container = AppContainer.bootstrap()

    var body: some Scene {
        WindowGroup {
            RootGameView(container: container)
                .frame(minWidth: 1200, minHeight: 760)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1440, height: 900)
        .commands {
            CommandMenu("军务") {
                Button("结束回合", action: container.advanceOrRunAI)
                    .keyboardShortcut(.return, modifiers: [.command])

                Button("重新开局", action: container.resetGame)
                    .keyboardShortcut("n", modifiers: [.command, .shift])
            }
        }
    }
}
#endif
