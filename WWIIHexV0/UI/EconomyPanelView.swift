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

                Text("Cost \(resourceSummary(kind.cost)) | \(kind.buildTurns) turn(s)")
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
                        Text(order.isReady ? "Ready" : "\(order.remainingTurns)")
                            .foregroundStyle(order.isReady ? .green : .secondary)
                    }
                    .font(.caption)
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
        "\(manpowerLabel) \(resources.manpower), \(industryLabel) \(resources.industry), \(suppliesLabel) \(resources.supplies)"
    }

    private func productionName(for kind: ProductionKind) -> String {
        guard gameState.isTangSongScenario else {
            return kind.displayName
        }

        switch kind {
        case .infantryDivision:
            return "募厢军"
        case .panzerDivision:
            return "募禁军"
        case .motorizedDivision:
            return "募骑军"
        case .artilleryDivision:
            return "造器械"
        case .supplyStockpile:
            return "整备粮草"
        }
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
        gameState.isTangSongScenario ? "入丁" : "Income MP"
    }

    private var incomeIndustryLabel: String {
        gameState.isTangSongScenario ? "入帛" : "Income IC"
    }

    private var upkeepLabel: String {
        gameState.isTangSongScenario ? "耗粮" : "Upkeep"
    }
}
