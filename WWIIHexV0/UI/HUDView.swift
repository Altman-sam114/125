import SwiftUI

struct HUDView: View {
    let gameState: GameState
    let onEndTurn: () -> Void
    let onNewGame: (() -> Void)?

    init(gameState: GameState, onEndTurn: @escaping () -> Void, onNewGame: (() -> Void)? = nil) {
        self.gameState = gameState
        self.onEndTurn = onEndTurn
        self.onNewGame = onNewGame
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(gameState.scenarioDisplayName)
                    .font(.headline)

                Spacer()

                if let onNewGame {
                    NewGameButton(action: onNewGame, isTangSongScenario: gameState.isTangSongScenario)
                }

                Button(action: onEndTurn) {
                    Label(endTurnLabel, systemImage: "forward.end")
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }
                .buttonStyle(.borderedProminent)
            }

            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 8) {
                GridRow {
                    metric(turnLabel, "\(gameState.turn) / \(gameState.maxTurns)")
                    metric(powerLabel, gameState.displayName(for: gameState.activeFaction))
                }

                GridRow {
                    metric(phaseLabel, gameState.phaseDisplayName)
                    metric(victoryLabel, victoryText)
                }

                GridRow {
                    metric(manpowerLabel, "\(activeLedger.stockpile.manpower)")
                    metric(industryLabel, "\(activeLedger.stockpile.industry)")
                }

                GridRow {
                    metric(suppliesLabel, "\(activeLedger.stockpile.supplies)")
                    metric(queueLabel, "\(activeLedger.productionQueue.count)")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(PlatformStyles.systemBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var victoryText: String {
        guard let winner = gameState.victoryState.winner else {
            return gameState.isTangSongScenario ? "未定" : "Ongoing"
        }
        if gameState.isTangSongScenario {
            return "\(gameState.displayName(for: winner))胜利"
        }
        return "\(gameState.displayName(for: winner)) Victory"
    }

    private var activeLedger: FactionEconomyLedger {
        gameState.economyState.ledger(for: gameState.activeFaction)
    }

    private var manpowerLabel: String {
        gameState.isTangSongScenario ? "丁口" : "Manpower"
    }

    private var industryLabel: String {
        gameState.isTangSongScenario ? "钱帛" : "Industry"
    }

    private var suppliesLabel: String {
        gameState.isTangSongScenario ? "粮草" : "Supplies"
    }

    private var endTurnLabel: String {
        gameState.isTangSongScenario ? "结束回合" : "End Turn"
    }

    private var turnLabel: String {
        gameState.isTangSongScenario ? "回合" : "Turn"
    }

    private var powerLabel: String {
        gameState.isTangSongScenario ? "政权" : "Power"
    }

    private var phaseLabel: String {
        gameState.isTangSongScenario ? "阶段" : "Phase"
    }

    private var victoryLabel: String {
        gameState.isTangSongScenario ? "胜负" : "Victory"
    }

    private var queueLabel: String {
        gameState.isTangSongScenario ? "队列" : "Queue"
    }
}
