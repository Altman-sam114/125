import SwiftUI

struct HUDView: View {
    let gameState: GameState
    let nextActionHint: String?
    let onEndTurn: () -> Void
    let onNewGame: (() -> Void)?

    init(
        gameState: GameState,
        nextActionHint: String? = nil,
        onEndTurn: @escaping () -> Void,
        onNewGame: (() -> Void)? = nil
    ) {
        self.gameState = gameState
        self.nextActionHint = nextActionHint
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

                if let objectiveProgressText {
                    GridRow {
                        metric(objectiveProgressLabel, objectiveProgressText)
                        metric(mandateProgressLabel, mandateProgressText ?? emptyProgressText)
                    }
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

            if let nextActionHint, gameState.isTangSongScenario {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.blue)
                        .frame(width: 18)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("下一步")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.blue)
                        Text(nextActionHint)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(.blue.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 6))
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
        let winnerName = gameState.displayName(for: winner)
        if let reason = gameState.victoryState.reason {
            return gameState.isTangSongScenario
                ? "\(winnerName)胜利：\(reason.displayName(isTangSongScenario: true))"
                : "\(winnerName) Victory: \(reason.displayName(isTangSongScenario: false))"
        }
        if gameState.isTangSongScenario {
            return "\(winnerName)胜利"
        }
        return "\(winnerName) Victory"
    }

    private var objectiveProgressText: String? {
        guard let progress = primaryObjectiveProgress else {
            return nil
        }
        return gameState.isTangSongScenario
            ? "\(progress.controlledCount)/\(progress.requiredCount) 州府"
            : "\(progress.controlledCount)/\(progress.requiredCount)"
    }

    private var mandateProgressText: String? {
        guard let progress = primaryObjectiveProgress,
              let mandateScore = progress.mandateScore,
              let mandateThreshold = progress.mandateThreshold else {
            return nil
        }
        return "\(mandateScore)/\(mandateThreshold)"
    }

    private var primaryObjectiveProgress: VictoryObjectiveProgress? {
        let progress = VictoryRules().objectiveProgress(in: gameState)
        return progress.first { $0.status == "majorVictory" } ?? progress.first
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

    private var objectiveProgressLabel: String {
        gameState.isTangSongScenario ? "统一进度" : "Objective"
    }

    private var mandateProgressLabel: String {
        gameState.isTangSongScenario ? "天命进度" : "Mandate"
    }

    private var emptyProgressText: String {
        gameState.isTangSongScenario ? "无门槛" : "None"
    }

    private var queueLabel: String {
        gameState.isTangSongScenario ? "队列" : "Queue"
    }
}
