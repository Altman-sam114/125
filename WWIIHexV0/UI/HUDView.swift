import SwiftUI

struct HUDView: View {
    let gameState: GameState
    let playerFaction: Faction
    let observerModeEnabled: Bool
    let nextActionHint: String?
    let onFocusObjective: ((String) -> Void)?
    let onEndTurn: () -> Void
    let onNewGame: (() -> Void)?

    init(
        gameState: GameState,
        playerFaction: Faction = .allies,
        observerModeEnabled: Bool = false,
        nextActionHint: String? = nil,
        onFocusObjective: ((String) -> Void)? = nil,
        onEndTurn: @escaping () -> Void,
        onNewGame: (() -> Void)? = nil
    ) {
        self.gameState = gameState
        self.playerFaction = playerFaction
        self.observerModeEnabled = observerModeEnabled
        self.nextActionHint = nextActionHint
        self.onFocusObjective = onFocusObjective
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

                if gameState.isTangSongScenario {
                    GridRow {
                        metric(commandIdentityLabel, commandIdentityText)
                        metric(commandModeLabel, commandModeText)
                    }
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

            if let objectiveGuideText, gameState.isTangSongScenario {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "scope")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                        .frame(width: 18)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("目标")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                        Text(objectiveGuideText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        if !objectiveGuideItems.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(objectiveGuideItems) { item in
                                        Button {
                                            onFocusObjective?(item.id)
                                        } label: {
                                            Text(item.label)
                                                .font(.caption2.weight(.semibold))
                                                .lineLimit(1)
                                        }
                                        .buttonStyle(.bordered)
                                        .controlSize(.mini)
                                        .disabled(onFocusObjective == nil)
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(.orange.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 6))
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

    private var objectiveGuideText: String? {
        guard gameState.isTangSongScenario,
              let progress = primaryObjectiveProgress,
              progress.status == "majorVictory" else {
            return nil
        }

        let controlledNames = objectiveGuideItems.filter { $0.isControlled }.map(\.name)
        let pendingNames = objectiveGuideItems.filter { !$0.isControlled }.map(\.name)

        if pendingNames.isEmpty {
            return "关键州府已全部达成；保持天命并查看战报确认胜负。"
        }

        let controlledPart: String
        if controlledNames.isEmpty {
            controlledPart = ""
        } else {
            controlledPart = "已据 \(limitedList(controlledNames, limit: 3))；"
        }

        let pendingPart = "待取 \(limitedList(pendingNames, limit: 4))"
        return "\(controlledPart)\(pendingPart)，凑足 \(progress.requiredCount) 处并保持天命。"
    }

    private var objectiveGuideItems: [ObjectiveGuideItem] {
        guard gameState.isTangSongScenario,
              let progress = primaryObjectiveProgress,
              progress.status == "majorVictory" else {
            return []
        }

        return progress.objectiveNames.compactMap { name in
            guard let objective = gameState.map.objective(named: name) else {
                return nil
            }
            let isControlled = gameState.map.controllerOfObjective(id: objective.id) == progress.faction
            return ObjectiveGuideItem(
                id: objective.id,
                name: objective.name,
                isControlled: isControlled
            )
        }
    }

    private func limitedList(_ names: [String], limit: Int) -> String {
        let visible = names.prefix(limit).joined(separator: "、")
        return names.count > limit ? "\(visible)等" : visible
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

    private var commandIdentityLabel: String {
        gameState.isTangSongScenario ? "指挥" : "Command"
    }

    private var commandModeLabel: String {
        gameState.isTangSongScenario ? "模式" : "Mode"
    }

    private var commandIdentityText: String {
        if observerModeEnabled {
            return "观战各方"
        }

        let playerName = gameState.displayName(for: playerFaction)
        let canCommand = gameState.activeFaction == playerFaction &&
            gameState.effectiveTurnOrderState.allowsCommands(
                activeFaction: playerFaction,
                phase: gameState.phase
            )
        return canCommand ? "\(playerName)可下令" : "\(playerName)待命"
    }

    private var commandModeText: String {
        observerModeEnabled ? "只读观战" : "玩家亲征"
    }
}

private struct ObjectiveGuideItem: Identifiable {
    let id: String
    let name: String
    let isControlled: Bool

    var label: String {
        "\(isControlled ? "已据" : "待取") \(name)"
    }
}
