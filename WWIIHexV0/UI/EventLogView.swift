import SwiftUI

struct EventLogView: View {
    let entries: [GameLogEntry]
    var summaryEntries: [GameLogEntry] = []
    var agentDecisionRecord: AgentDecisionRecord?
    var directiveRecords: [WarDirectiveRecord] = []
    var victoryState: VictoryState = .ongoing
    var objectiveProgress: [VictoryObjectiveProgress] = []
    var currentTurn: Int?
    var isTangSongScenario = false
    var factionDisplayName: ((Faction) -> String)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isTangSongScenario ? "战报" : "Event Log")
                .font(.headline)

            if let victorySummary {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isTangSongScenario ? "胜负" : "Victory")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.blue)
                    Text(victorySummary)
                        .font(.subheadline.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(.blue.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            if let turnReportSummary {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(turnReportSummary.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)

                        Spacer()

                        Text(turnReportSummary.turnText)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    Text(turnReportSummary.summaryText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if !turnReportSummary.highlights.isEmpty {
                        VStack(alignment: .leading, spacing: 3) {
                            ForEach(turnReportSummary.highlights) { highlight in
                                Text(highlight.text)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(.orange.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            if !progressItems.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text(isTangSongScenario ? "胜利目标" : "Victory Objectives")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    ForEach(progressItems) { progress in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(progress.title(
                                    isTangSongScenario: isTangSongScenario,
                                    factionDisplayName: displayName(for:)
                                ))
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)

                                Spacer()

                                Text(progress.isSatisfied ? completedText : pendingText)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(progress.isSatisfied ? .green : .secondary)
                            }

                            Text(progress.summary(isTangSongScenario: isTangSongScenario))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)

                            Text(progress.detail(isTangSongScenario: isTangSongScenario))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    if recentEntries.isEmpty {
                        Text(isTangSongScenario ? "暂无战报。" : "No events yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(recentEntries) { item in
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(item.category.displayName(isTangSongScenario: isTangSongScenario))
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(item.category.foregroundStyle)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(item.category.backgroundStyle)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))

                                    Text(metadata(for: item.entry))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Text(item.entry.message)
                                    .font(.body)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .frame(minHeight: 120)
        }
        .padding(12)
        .background(PlatformStyles.systemBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var recentEntries: [LogDisplayEntry] {
        entries
            .suffix(60)
            .reversed()
            .map { LogDisplayEntry(entry: $0, category: LogDisplayCategory(entry: $0)) }
    }

    private var progressItems: [VictoryObjectiveProgress] {
        Array(objectiveProgress.prefix(3))
    }

    private var victorySummary: String? {
        guard let winner = victoryState.winner else {
            return nil
        }
        let winnerName = displayName(for: winner)
        if let reason = victoryState.reason {
            return reason.eventMessage(winnerName: winnerName, isTangSongScenario: isTangSongScenario)
        }
        if isTangSongScenario {
            return "\(winnerName)胜利。"
        }
        return "\(winnerName) victory."
    }

    private var completedText: String {
        isTangSongScenario ? "达成" : "Met"
    }

    private var pendingText: String {
        isTangSongScenario ? "推进中" : "Pending"
    }

    private func displayName(for faction: Faction) -> String {
        factionDisplayName?(faction) ?? faction.displayName
    }

    private func metadata(for entry: GameLogEntry) -> String {
        let faction = entry.faction.map { displayName(for: $0) } ??
            (isTangSongScenario ? "系统" : "System")
        let phase = entry.phase?.displayName(isTangSongScenario: isTangSongScenario) ??
            (isTangSongScenario ? "开局" : "Setup")
        let turnLabel = isTangSongScenario ? "回合" : "Turn"
        if let relatedRecordId = entry.relatedRecordId {
            return "\(turnLabel) \(entry.turn) - \(faction) - \(phase) - \(relatedRecordId)"
        }
        return "\(turnLabel) \(entry.turn) - \(faction) - \(phase)"
    }

    private var turnReportSummary: TurnReportSummary? {
        guard isTangSongScenario else {
            return nil
        }
        let sourceEntries = summaryEntries.isEmpty ? entries : summaryEntries
        guard !sourceEntries.isEmpty || agentDecisionRecord != nil || !directiveRecords.isEmpty else {
            return nil
        }

        let agentTurns = agentDecisionRecord.map { [$0.turn] } ?? []
        let knownTurns = sourceEntries.map(\.turn) + directiveRecords.map(\.turn) + agentTurns
        let latestTurn = knownTurns.max() ?? currentTurn ?? 0
        let preferredTurn = currentTurn ?? latestTurn
        let preferredEntries = sourceEntries.filter { $0.turn == preferredTurn }
        let selectedTurn = preferredEntries.isEmpty ? latestTurn : preferredTurn
        let turnEntries = preferredEntries.isEmpty
            ? sourceEntries.filter { $0.turn == latestTurn }
            : preferredEntries
        let turnDirectives = directiveRecords.filter { $0.turn == selectedTurn }
        let turnAgentRecord = agentDecisionRecord?.turn == selectedTurn ? agentDecisionRecord : nil

        let displayEntries = turnEntries.map {
            LogDisplayEntry(entry: $0, category: LogDisplayCategory(entry: $0))
        }
        let counts = turnReportCounts(
            from: displayEntries,
            agentRecord: turnAgentRecord,
            directiveRecords: turnDirectives
        )
        let summaryText = turnReportText(
            counts: counts,
            entryCount: turnEntries.count,
            directiveCount: turnDirectives.count,
            hasAgentRecord: turnAgentRecord != nil
        )
        let logHighlights = displayEntries
            .reversed()
            .filter { $0.category != .event || counts.isEmpty }
            .prefix(3)
            .map {
                TurnReportHighlight(text: "• \($0.category.displayName(isTangSongScenario: true))：\($0.entry.message)")
            }
        let aiHighlights = turnReportAIHighlights(agentRecord: turnAgentRecord, directiveRecords: turnDirectives)
        let highlights = Array((aiHighlights + logHighlights).prefix(4))

        return TurnReportSummary(
            title: selectedTurn == preferredTurn ? "本回合战报" : "最近战报",
            turnText: "回合 \(selectedTurn)",
            summaryText: summaryText,
            highlights: Array(highlights)
        )
    }

    private func turnReportCounts(
        from entries: [LogDisplayEntry],
        agentRecord: AgentDecisionRecord?,
        directiveRecords: [WarDirectiveRecord]
    ) -> [TurnReportCategoryCount] {
        let preferredOrder: [LogDisplayCategory] = [
            .combat,
            .regionOwnerChange,
            .siege,
            .supply,
            .diplomacy,
            .frontChange,
            .theaterChange,
            .retreat,
            .reinforcement,
            .encirclement
        ]
        let grouped = Dictionary(grouping: entries, by: \.category)
        var counts: [TurnReportCategoryCount] = preferredOrder.compactMap { category -> TurnReportCategoryCount? in
            guard let count = grouped[category]?.count, count > 0 else {
                return nil
            }
            return TurnReportCategoryCount(
                category: category,
                label: category.displayName(isTangSongScenario: true),
                count: count
            )
        }
        if agentRecord != nil || !directiveRecords.isEmpty {
            counts.append(TurnReportCategoryCount(
                category: nil,
                label: "军议",
                count: directiveRecords.count + (agentRecord == nil ? 0 : 1)
            ))
        }
        return counts
    }

    private func turnReportText(
        counts: [TurnReportCategoryCount],
        entryCount: Int,
        directiveCount: Int,
        hasAgentRecord: Bool
    ) -> String {
        guard !counts.isEmpty else {
            return "本回合暂无战斗、围城、粮道、外交、州府变化或军议记录。"
        }

        let parts = counts.prefix(5).map { "\($0.label) \($0.count)" }
        let suffix = counts.count > 5 ? "等" : ""
        let total = entryCount + directiveCount + (hasAgentRecord ? 1 : 0)
        return "本回合汇总 \(total) 项：\(parts.joined(separator: "、"))\(suffix)。"
    }

    private func turnReportAIHighlights(
        agentRecord: AgentDecisionRecord?,
        directiveRecords: [WarDirectiveRecord]
    ) -> [TurnReportHighlight] {
        var highlights: [TurnReportHighlight] = []
        if let summary = agentRecord?.theaterDirectiveSummary?.summary,
           !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            highlights.append(TurnReportHighlight(text: "• 军议：\(summary)"))
        } else if let parsedIntent = agentRecord?.parsedIntent,
                  !parsedIntent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            highlights.append(TurnReportHighlight(text: "• 军议：\(parsedIntent)"))
        }

        for record in directiveRecords.suffix(2).reversed() {
            let directiveName = record.directiveType?.displayName(isTangSongScenario: true) ?? "方面军令"
            let tacticName = record.tactic?.displayName(isTangSongScenario: true)
            let detail = tacticName.map { "\(directiveName) / \($0)" } ?? directiveName
            highlights.append(TurnReportHighlight(text: "• 方面：\(detail)"))
        }
        return highlights
    }
}

private struct LogDisplayEntry: Identifiable {
    let entry: GameLogEntry
    let category: LogDisplayCategory

    var id: UUID {
        entry.id
    }
}

private struct TurnReportSummary {
    let title: String
    let turnText: String
    let summaryText: String
    let highlights: [TurnReportHighlight]
}

private struct TurnReportHighlight: Identifiable {
    let id = UUID()
    let text: String
}

private struct TurnReportCategoryCount {
    let category: LogDisplayCategory?
    let label: String
    let count: Int
}

private enum LogDisplayCategory: Hashable {
    case combat
    case retreat
    case reinforcement
    case encirclement
    case siege
    case supply
    case frontChange
    case theaterChange
    case regionOwnerChange
    case diplomacy
    case event

    init(entry: GameLogEntry) {
        switch entry.category {
        case .combat:
            self = .combat
            return
        case .retreat:
            self = .retreat
            return
        case .reinforce:
            self = .reinforcement
            return
        case .encircle:
            self = .encirclement
            return
        case .siege:
            self = .siege
            return
        case .supply:
            self = .supply
            return
        case .frontChange:
            self = .frontChange
            return
        case .theaterChange:
            self = .theaterChange
            return
        case .regionOwnerChange:
            self = .regionOwnerChange
            return
        case .diplomacy:
            self = .diplomacy
            return
        case .event:
            break
        }

        let message = entry.message
        let text = message.lowercased()

        if text.contains("retreat") || text.contains("routed") || text.contains("routing") ||
            message.contains("退却") || message.contains("撤退") {
            self = .retreat
        } else if text.contains("reinforce") || text.contains("replacement") || text.contains("replenish") ||
            message.contains("整补") || message.contains("补员") {
            self = .reinforcement
        } else if text.contains("siege") || text.contains("besiege") ||
            message.contains("围城") || message.contains("解围") || message.contains("招降") {
            self = .siege
        } else if text.contains("encircle") || text.contains("encircled") || message.contains("合围") {
            self = .encirclement
        } else if text.contains("attack") || text.contains("damage") || text.contains("combat") ||
            text.contains("hit") || message.contains("进攻") || message.contains("攻击") || message.contains("战斗") {
            self = .combat
        } else if text.contains("supply") || text.contains("supplied") ||
            message.contains("粮道") || message.contains("粮草") || message.contains("补给") {
            self = .supply
        } else {
            self = .event
        }
    }

    func displayName(isTangSongScenario: Bool) -> String {
        if isTangSongScenario {
            switch self {
            case .combat:
                return "战斗"
            case .retreat:
                return "退却"
            case .reinforcement:
                return "整补"
            case .encirclement:
                return "合围"
            case .siege:
                return "围城"
            case .supply:
                return "粮道"
            case .frontChange:
                return "前线"
            case .theaterChange:
                return "方面"
            case .regionOwnerChange:
                return "州府"
            case .diplomacy:
                return "外交"
            case .event:
                return "事件"
            }
        }

        switch self {
        case .combat:
            return "Combat"
        case .retreat:
            return "Retreat"
        case .reinforcement:
            return "Reinforce"
        case .encirclement:
            return "Encircle"
        case .siege:
            return "Siege"
        case .supply:
            return "Supply"
        case .frontChange:
            return "Front"
        case .theaterChange:
            return "Theater"
        case .regionOwnerChange:
            return "Region"
        case .diplomacy:
            return "Diplomacy"
        case .event:
            return "Event"
        }
    }

    var foregroundStyle: Color {
        switch self {
        case .combat:
            return .red
        case .retreat:
            return .orange
        case .reinforcement:
            return .green
        case .encirclement:
            return .purple
        case .siege:
            return .brown
        case .supply:
            return .teal
        case .frontChange:
            return .blue
        case .theaterChange:
            return .indigo
        case .regionOwnerChange:
            return .mint
        case .diplomacy:
            return .cyan
        case .event:
            return .secondary
        }
    }

    var backgroundStyle: Color {
        foregroundStyle.opacity(0.12)
    }
}
