import SwiftUI

struct EconomyPanelView: View {
    let gameState: GameState
    let playerFaction: Faction
    let observerModeEnabled: Bool
    let onQueueProduction: (ProductionKind) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(gameState.isTangSongScenario ? "府库" : "Economy")
                .font(.headline)

            ledgerSection(for: gameState.activeFaction)

            Divider()

            productionControls

            Divider()

            queueSection(for: gameState.activeFaction)
        }
        .padding(12)
        .background(PlatformStyles.systemBackground)
        .clipShape(.rect(cornerRadius: 8))
    }

    private func ledgerSection(for faction: Faction) -> some View {
        let ledger = gameState.economyState.ledger(for: faction)

        return VStack(alignment: .leading, spacing: 8) {
            Text("\(gameState.displayName(for: faction)) \(gameState.isTangSongScenario ? "府库" : "Ledger")")
                .font(.subheadline.weight(.semibold))

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
                GridRow {
                    metric(manpowerLabel, ledger.stockpile.manpower)
                    metric(industryLabel, ledger.stockpile.industry)
                    metric(suppliesLabel, ledger.stockpile.supplies)
                }

                GridRow {
                    metric(incomeManpowerLabel, ledger.lastIncome.manpower)
                    metric(incomeIndustryLabel, ledger.lastIncome.industry)
                    metric(upkeepLabel, ledger.lastUpkeep.supplies)
                }
            }
        }
    }

    private var productionControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(gameState.isTangSongScenario ? "军备" : "Production")
                .font(.subheadline.weight(.semibold))

            ForEach(ProductionKind.allCases) { kind in
                Button {
                    onQueueProduction(kind)
                } label: {
                    Label(productionName(for: kind), systemImage: iconName(for: kind))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
                .disabled(!canQueue(kind))
                .accessibilityLabel(productionAccessibilityLabel(for: kind))
                .accessibilityValue(productionAccessibilityValue(for: kind))
                .accessibilityHint(productionAccessibilityHint(for: kind))

                Text(productionCostLine(for: kind))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func queueSection(for faction: Faction) -> some View {
        let queue = gameState.economyState.ledger(for: faction).productionQueue

        return VStack(alignment: .leading, spacing: 6) {
            Text(gameState.isTangSongScenario ? "队列" : "Queue")
                .font(.subheadline.weight(.semibold))

            if queue.isEmpty {
                Text(gameState.isTangSongScenario ? "暂无军备令。" : "No active orders.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(queue) { order in
                    HStack {
                        Text(productionName(for: order.kind))
                            .lineLimit(1)
                        Spacer()
                        Text(queueStatusText(for: order))
                            .foregroundStyle(order.isReady ? .green : .secondary)
                    }
                    .font(.caption)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(queueAccessibilityLabel(for: order))
                    .accessibilityValue(queueStatusText(for: order))
                }
            }
        }
    }

    private func metric(_ label: String, _ value: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue("\(value)")
    }

    private func canQueue(_ kind: ProductionKind) -> Bool {
        !observerModeEnabled &&
            gameState.effectiveTurnOrderState.allowsCommands(
                activeFaction: playerFaction,
                phase: gameState.phase
            ) &&
            gameState.economyState.ledger(for: gameState.activeFaction).stockpile.canAfford(kind.cost)
    }

    private func resourceSummary(_ resources: EconomyResources) -> String {
        resources.summary(isTangSongScenario: gameState.isTangSongScenario)
    }

    private func productionName(for kind: ProductionKind) -> String {
        kind.displayName(isTangSongScenario: gameState.isTangSongScenario)
    }

    private func productionCostLine(for kind: ProductionKind) -> String {
        if gameState.isTangSongScenario {
            return "耗 \(resourceSummary(kind.cost))，需 \(kind.buildTurns) 回合"
        }

        return "Cost \(resourceSummary(kind.cost)) | \(kind.buildTurns) turn(s)"
    }

    private func productionAccessibilityLabel(for kind: ProductionKind) -> String {
        if gameState.isTangSongScenario {
            return "下达军备令：\(productionName(for: kind))"
        }
        return productionName(for: kind)
    }

    private func productionAccessibilityValue(for kind: ProductionKind) -> String {
        if gameState.isTangSongScenario {
            return canQueue(kind) ? "可用" : "停用"
        }
        return canQueue(kind) ? "Available" : "Unavailable"
    }

    private func productionAccessibilityHint(for kind: ProductionKind) -> String {
        let costLine = productionCostLine(for: kind)
        guard !canQueue(kind) else {
            return gameState.isTangSongScenario
                ? "\(costLine)。加入当前府库军备队列。"
                : "\(costLine). Add this item to the production queue."
        }

        if observerModeEnabled {
            return gameState.isTangSongScenario
                ? "\(costLine)。观战模式只能查看府库，不能下达军备令。"
                : "\(costLine). Observer mode is read-only."
        }

        let commandsAllowed = gameState.effectiveTurnOrderState.allowsCommands(
            activeFaction: playerFaction,
            phase: gameState.phase
        )
        if !commandsAllowed {
            return gameState.isTangSongScenario
                ? "\(costLine)。当前阶段不可下达军备令。"
                : "\(costLine). Production is unavailable during the current phase."
        }

        return gameState.isTangSongScenario
            ? "\(costLine)。当前丁口、钱帛或粮草不足。"
            : "\(costLine). Insufficient resources."
    }

    private func queueStatusText(for order: ProductionOrder) -> String {
        if order.isReady {
            return readyLabel
        }
        return gameState.isTangSongScenario
            ? "尚需 \(order.remainingTurns) 回合"
            : "\(order.remainingTurns)"
    }

    private func queueAccessibilityLabel(for order: ProductionOrder) -> String {
        if gameState.isTangSongScenario {
            return "军备队列：\(productionName(for: order.kind))"
        }
        return productionName(for: order.kind)
    }

    private func iconName(for kind: ProductionKind) -> String {
        switch kind {
        case .infantryDivision:
            return "figure.walk"
        case .panzerDivision:
            return "shield.lefthalf.filled"
        case .motorizedDivision:
            return "truck.box"
        case .artilleryDivision:
            return "scope"
        case .supplyStockpile:
            return "shippingbox"
        }
    }

    private var manpowerLabel: String {
        gameState.isTangSongScenario ? "丁口" : "MP"
    }

    private var industryLabel: String {
        gameState.isTangSongScenario ? "钱帛" : "IC"
    }

    private var suppliesLabel: String {
        gameState.isTangSongScenario ? "粮草" : "SUP"
    }

    private var incomeManpowerLabel: String {
        gameState.isTangSongScenario ? "本回合丁口" : "Income MP"
    }

    private var incomeIndustryLabel: String {
        gameState.isTangSongScenario ? "本回合钱帛" : "Income IC"
    }

    private var upkeepLabel: String {
        gameState.isTangSongScenario ? "本回合耗粮" : "Upkeep"
    }

    private var readyLabel: String {
        gameState.isTangSongScenario ? "就绪" : "Ready"
    }
}
