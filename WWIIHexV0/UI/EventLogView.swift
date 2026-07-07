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
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(victorySummaryAccessibilityLabel())
                .accessibilityValue(victorySummaryAccessibilityValue(victorySummary))
            }

            if let settlementSummary {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("评分估算")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)

                        Spacer()

                        Text(settlementScoreText(settlementSummary.score))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.green)
                    }

                    Text(settlementSummary.grade)
                        .font(.subheadline.weight(.semibold))

                    Text(settlementSummary.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(.green.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(settlementAccessibilityLabel())
                .accessibilityValue(settlementAccessibilityValue(for: settlementSummary))
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
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(turnReportAccessibilityLabel(for: turnReportSummary))
                .accessibilityValue(turnReportAccessibilityValue(for: turnReportSummary))
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
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(objectiveAccessibilityLabel(for: progress))
                        .accessibilityValue(objectiveAccessibilityValue(for: progress))
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

                                Text(displayMessage(for: item.entry))
                                    .font(.body)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(logEntryAccessibilityLabel(for: item))
                            .accessibilityValue(logEntryAccessibilityValue(for: item))
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

    private var settlementSummary: SettlementSummary? {
        guard isTangSongScenario,
              let winner = victoryState.winner else {
            return nil
        }

        let winnerName = displayName(for: winner)
        let matchingProgress = objectiveProgress.first { $0.faction == winner && $0.isSatisfied } ??
            objectiveProgress.first { $0.faction == winner }

        let objectiveRatio: Double
        let objectiveText: String
        if let progress = matchingProgress {
            objectiveRatio = Double(progress.controlledCount) / Double(max(1, progress.requiredCount))
            objectiveText = "州府 \(progress.controlledCount)／\(progress.requiredCount)"
        } else {
            objectiveRatio = 1
            objectiveText = "州府已判定"
        }

        let mandateRatio: Double
        let mandateText: String
        if let mandateScore = matchingProgress?.mandateScore,
           let mandateThreshold = matchingProgress?.mandateThreshold {
            mandateRatio = Double(mandateScore) / Double(max(1, mandateThreshold))
            mandateText = "天命 \(mandateScore)／\(mandateThreshold)"
        } else {
            mandateRatio = 1
            mandateText = "天命无额外门槛"
        }

        let turn = currentTurn ?? matchingProgress?.currentTurn ?? 1
        let turnRequirement = matchingProgress?.turnRequirement ?? turn
        let speedRatio: Double
        if turnRequirement > 0 {
            speedRatio = max(0, min(1, Double(turnRequirement - turn + 1) / Double(turnRequirement)))
        } else {
            speedRatio = 0
        }

        let baseScore = victoryState.reason == .tangSongSeparatistSurvival ? 45 : 50
        let score = min(
            100,
            baseScore +
                Int((min(1, objectiveRatio) * 30).rounded()) +
                Int((min(1, mandateRatio) * 15).rounded()) +
                Int((speedRatio * 5).rounded())
        )

        let grade: String
        if victoryState.reason == .tangSongSeparatistSurvival {
            switch score {
            case 85...100:
                grade = "\(winnerName)守成有余"
            case 70...84:
                grade = "\(winnerName)割据稳固"
            case 55...69:
                grade = "\(winnerName)勉强自保"
            default:
                grade = "\(winnerName)余势未稳"
            }
        } else {
            switch score {
            case 90...100:
                grade = "\(winnerName)天命归一"
            case 75...89:
                grade = "\(winnerName)山河大定"
            case 60...74:
                grade = "\(winnerName)功业初成"
            default:
                grade = "\(winnerName)局势未稳"
            }
        }

        let detail = "依据当前胜负、\(objectiveText)、\(mandateText)与回合 \(turn) 展示层只读估算；不写入存档，也不改变胜利判定。"
        return SettlementSummary(score: score, grade: grade, detail: detail)
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
        if isTangSongScenario {
            return "\(turnLabel) \(entry.turn)；\(faction)；\(phase)"
        }
        if let relatedRecordId = entry.relatedRecordId {
            return "\(turnLabel) \(entry.turn) - \(faction) - \(phase) - \(relatedRecordId)"
        }
        return "\(turnLabel) \(entry.turn) - \(faction) - \(phase)"
    }

    private func settlementScoreText(_ score: Int) -> String {
        isTangSongScenario ? "\(score)／100" : "\(score) / 100"
    }

    private func displayMessage(for entry: GameLogEntry) -> String {
        guard isTangSongScenario else {
            return entry.message
        }
        return TangSongEventLogMessage.display(entry.message)
    }

    private func logEntryAccessibilityLabel(for item: LogDisplayEntry) -> String {
        let category = item.category.displayName(isTangSongScenario: isTangSongScenario)
        if isTangSongScenario {
            return "战报：\(category)"
        }
        return "Event log entry: \(category)"
    }

    private func logEntryAccessibilityValue(for item: LogDisplayEntry) -> String {
        let metadata = metadata(for: item.entry)
        let message = displayMessage(for: item.entry)
        if isTangSongScenario {
            return "\(metadata)。\(message)"
        }
        return "\(metadata). \(message)"
    }

    private func turnReportAccessibilityLabel(for summary: TurnReportSummary) -> String {
        if isTangSongScenario {
            return "战报摘要：\(summary.title)"
        }
        return summary.title
    }

    private func turnReportAccessibilityValue(for summary: TurnReportSummary) -> String {
        let highlights = summary.highlights
            .map { $0.text.replacingOccurrences(of: "• ", with: "") }
        let parts = [summary.turnText, summary.summaryText] + highlights
        return parts.joined(separator: isTangSongScenario ? "。" : ". ")
    }

    private func victorySummaryAccessibilityLabel() -> String {
        isTangSongScenario ? "胜负摘要" : "Victory summary"
    }

    private func victorySummaryAccessibilityValue(_ summary: String) -> String {
        summary
    }

    private func settlementAccessibilityLabel() -> String {
        isTangSongScenario ? "评分估算" : "Score estimate"
    }

    private func settlementAccessibilityValue(for summary: SettlementSummary) -> String {
        let parts = [
            settlementScoreText(summary.score),
            summary.grade,
            summary.detail
        ]
        return parts.joined(separator: isTangSongScenario ? "。" : ". ")
    }

    private func objectiveAccessibilityLabel(for progress: VictoryObjectiveProgress) -> String {
        let title = progress.title(
            isTangSongScenario: isTangSongScenario,
            factionDisplayName: displayName(for:)
        )
        if isTangSongScenario {
            return "胜利目标：\(title)"
        }
        return "Victory objective: \(title)"
    }

    private func objectiveAccessibilityValue(for progress: VictoryObjectiveProgress) -> String {
        let status = progress.isSatisfied ? completedText : pendingText
        let parts = [
            status,
            progress.summary(isTangSongScenario: isTangSongScenario),
            progress.detail(isTangSongScenario: isTangSongScenario)
        ]
        return parts.joined(separator: isTangSongScenario ? "。" : ". ")
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
                TurnReportHighlight(text: "• \($0.category.displayName(isTangSongScenario: true))：\(displayMessage(for: $0.entry))")
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
            highlights.append(TurnReportHighlight(text: "• 军议：\(safeTangSongNarrative(summary, fallback: "军议摘要已形成"))"))
        } else if let parsedIntent = agentRecord?.parsedIntent,
                  !parsedIntent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            highlights.append(TurnReportHighlight(text: "• 军议：\(safeTangSongNarrative(parsedIntent, fallback: "已形成方面军令"))"))
        }

        for record in directiveRecords.suffix(2).reversed() {
            let directiveName = record.directiveType?.displayName(isTangSongScenario: true) ?? "方面军令"
            let tacticName = record.tactic?.displayName(isTangSongScenario: true)
            let detail = tacticName.map { "\(directiveName)：\($0)" } ?? directiveName
            highlights.append(TurnReportHighlight(text: "• 方面：\(detail)"))
        }
        return highlights
    }

    private func safeTangSongNarrative(_ text: String, fallback: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return fallback
        }

        let rawMarkers = ["{", "}", "[", "]", "\"", ":", "_", "rawJSON", "directive", "marshal", "attack(", "move("]
        let lowercased = trimmed.lowercased()
        if trimmed.unicodeScalars.contains(where: { scalar in
            (65...90).contains(Int(scalar.value)) || (97...122).contains(Int(scalar.value))
        }) || rawMarkers.contains(where: { lowercased.contains($0.lowercased()) }) {
            return fallback
        }
        return trimmed
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

private struct SettlementSummary {
    let score: Int
    let grade: String
    let detail: String
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

enum TangSongEventLogMessage {
    static func display(_ message: String) -> String {
        if let exact = exactTranslations[message] {
            return finalized(exact)
        }

        if let command = commandResult(message) {
            return finalized(command)
        }
        if let selection = selectionMessage(message) {
            return finalized(selection)
        }
        if let combat = combatMessage(message) {
            return finalized(combat)
        }
        if let supply = supplyMessage(message) {
            return finalized(supply)
        }
        if let ai = aiMessage(message) {
            return finalized(ai)
        }

        return finalized(validationErrors(in: message))
    }

    private static let exactTranslations: [String: String] = [
        "Hold rejected: no active allied unit selected.": "固守被拒：未选择可行动的亲征军队。",
        "Allow retreat rejected: no active allied unit selected.": "准退被拒：未选择可行动的亲征军队。",
        "Resupply rejected: no active allied unit selected.": "休整被拒：未选择可行动的亲征军队。",
        "Besiege rejected: no active allied unit selected.": "围城被拒：未选择可行动的亲征军队。",
        "Besiege rejected: no adjacent enemy city, pass, or granary selected.": "围城被拒：未选择相邻敌方城池、关隘或粮仓。",
        "Repair fortification rejected: no active allied unit selected.": "修城被拒：未选择可行动的亲征军队。",
        "Repair fortification rejected: no damaged friendly besieged city selected.": "修城被拒：未选择己方受围且城防受损的州府。",
        "Relieve siege rejected: no active allied unit selected.": "解围被拒：未选择可行动的亲征军队。",
        "Relieve siege rejected: no friendly besieged city in range.": "解围被拒：射程内没有己方受围州府。",
        "Demand surrender rejected: no active allied unit selected.": "招降被拒：未选择可行动的亲征军队。",
        "Demand surrender rejected: no broken enemy siege target in range.": "招降被拒：射程内没有城防已破的敌方围城目标。",
        "Submission rejected: no active allied unit selected.": "招抚被拒：未选择可行动的亲征军队。",
        "Submission rejected: no eligible foreign capital selected.": "招抚被拒：未选择可招抚的外方国都。",
        "General order rejected: no allied front zone selected.": "将领军令被拒：未选择亲征方面防区。",
        "General order rejected: select an enemy front region to attack.": "将领军令被拒：未选择可进攻的敌前州府。",
        "General order rejected: no allied source front zone available.": "将领军令被拒：没有可用的亲征方面防区。",
        "General order rejected: not in the player command phase.": "将领军令被拒：当前不是亲征军令阶段。",
        "General order rejected: source zone is not controlled by the player.": "将领军令被拒：来源方面不归当前亲征势力。",
        "General order rejected: source zone changed during refresh.": "将领军令被拒：方面刷新后归属已变化。",
        "Production rejected: observer mode is read-only.": "军备被拒：观战模式只能查看。",
        "Player directive generated no executable commands.": "将领军令未生成可执行命令。",
        "General order produced no commands.": "将领军令没有生成底层命令。"
    ]

    private static func commandResult(_ message: String) -> String? {
        if message.hasPrefix("军令接受:") {
            let action = commandAction(in: message) ?? "军令"
            return "军令接受：\(action)已执行。"
        }
        if message.hasPrefix("军令驳回:") {
            let action = commandAction(in: message) ?? "军令"
            let reason = validationReason(in: message)
            return "军令驳回：\(action)未能执行。\(reason)"
        }
        if message.hasPrefix("Command accepted:") {
            let action = commandAction(in: message) ?? "军令"
            return "军令接受：\(action)已执行。"
        }
        if message.hasPrefix("Command rejected:") || message.hasPrefix("军令被拒：") {
            let reason = validationReason(in: message)
            return "军令驳回：未能执行。\(reason)"
        }
        if message.hasPrefix("General order submitted:") {
            let action = message.contains("attack") ? "进攻" : "固守"
            return "将领军令已提交：\(action)。"
        }
        return nil
    }

    private static func selectionMessage(_ message: String) -> String? {
        if message.hasPrefix("Selected hex ") {
            let coord = stripped(message, prefix: "Selected hex ", suffix: ".")
            let parts = coord.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            if parts.count == 2 {
                return "已选地块：第 \(parts[0]) 列，第 \(parts[1]) 行。"
            }
            return "已选地块：\(coord)。"
        }
        if message.hasPrefix("Selected region: ") {
            let region = stripped(message, prefix: "Selected region: ", suffix: ".")
                .components(separatedBy: " (")
                .first?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? "未知州府"
            return "已选州府：\(region)。"
        }
        if message.hasPrefix("Inspecting unit: ") {
            return "查看军队：\(stripped(message, prefix: "Inspecting unit: ", suffix: "."))。"
        }
        if message.hasPrefix("Selected unit: ") {
            return "选中军队：\(stripped(message, prefix: "Selected unit: ", suffix: "."))。"
        }
        if message.hasPrefix("Selected enemy unit: ") {
            return "选中敌军：\(stripped(message, prefix: "Selected enemy unit: ", suffix: "."))。"
        }
        if message.hasPrefix("Selected non-hostile unit: ") {
            return "选中非敌对军队：\(stripped(message, prefix: "Selected non-hostile unit: ", suffix: "."))。"
        }
        if message.hasPrefix("Player faction changed: ") {
            return "已切换亲征势力：\(stripped(message, prefix: "Player faction changed: ", suffix: "."))。"
        }
        if message.hasPrefix("Focused objective: ") {
            return "已定位目标州府：\(stripped(message, prefix: "Focused objective: ", suffix: "."))。"
        }
        return nil
    }

    private static func combatMessage(_ message: String) -> String? {
        guard let prefixEnd = message.range(of: ": strength -") else {
            return nil
        }
        let prefix = String(message[..<prefixEnd.lowerBound])
        let tail = String(message[prefixEnd.upperBound...])
        let damage = leadingNumber(in: tail) ?? "?"

        let verb: String
        let parties: [String]
        if prefix.contains(" counterattacked ") {
            verb = "反击"
            parties = prefix.components(separatedBy: " counterattacked ")
        } else if prefix.contains(" attacked ") {
            verb = "进攻"
            parties = prefix.components(separatedBy: " attacked ")
        } else {
            return nil
        }

        let subject = parties.count == 2 ? "\(parties[0])\(verb)\(parties[1])" : prefix
        var parts = ["\(subject)：兵力 -\(damage)"]
        if message.contains("triggered automatic retreat") {
            parts.append("触发自动退却")
        }
        if let extra = number(after: "extra strength -", in: message) {
            parts.append("额外兵力 -\(extra)")
        }
        if message.contains("was destroyed") {
            parts.append("部队溃灭")
        }
        return parts.joined(separator: "；") + "。"
    }

    private static func supplyMessage(_ message: String) -> String? {
        if message.contains(" moved to ") {
            let parts = message.components(separatedBy: " moved to ")
            if parts.count == 2 {
                return "\(parts[0])行军至 \(trimTrailingPeriod(parts[1]))。"
            }
        }
        if message.contains(" reinforced in ") {
            let name = message.components(separatedBy: " reinforced in ").first ?? "军队"
            let amount = number(after: "+", in: message) ?? "?"
            return "\(name)完成整补：兵力 +\(amount)。"
        }
        if message.contains(" could not recover while ") {
            let name = message.components(separatedBy: " could not recover while ").first ?? "军队"
            return "\(name)因粮道状态不佳，未能恢复兵力。"
        }
        if message.contains(" retreated from ") {
            let parts = message.components(separatedBy: " retreated from ")
            if parts.count == 2 {
                let route = trimTrailingPeriod(parts[1])
                    .replacingOccurrences(of: " to ", with: " 退至 ")
                return "\(parts[0])自 \(route)。"
            }
        }
        if message.contains(" failed to retreat and lost ") {
            let name = message.components(separatedBy: " failed to retreat and lost ").first ?? "军队"
            let amount = number(after: "lost ", in: message) ?? "?"
            return "\(name)退却失败：兵力 -\(amount)。"
        }
        if message.contains(" suffered encirclement attrition: ") {
            let name = message.components(separatedBy: " suffered encirclement attrition: ").first ?? "军队"
            let amount = number(after: "-", in: message) ?? "?"
            return "\(name)被围损耗：兵力 -\(amount)。"
        }
        if message.hasSuffix(" completed retreat recovery.") {
            let name = message.replacingOccurrences(of: " completed retreat recovery.", with: "")
            return "\(name)完成退却整备。"
        }
        return nil
    }

    private static func aiMessage(_ message: String) -> String? {
        if message.hasPrefix("AI "), message.contains(" resolved "), message.contains(" command result") {
            let count = number(after: " resolved ", in: message) ?? "若干"
            return "军议执行：完成 \(count) 条军令结果。"
        }
        if message.hasPrefix("AI turn requested") {
            return "军议回合暂未执行：当前阶段或政权不符合自动推进条件。"
        }
        if message.hasPrefix("Player directive generated no executable commands.") {
            return "将领军令未生成可执行命令。"
        }
        if message.contains(" command(s) were rejected by rules.") {
            let count = leadingNumber(in: message) ?? "若干"
            return "将领军令有 \(count) 道命令被规则驳回。"
        }
        if message.contains(" micromanaged division(s) excluded.") {
            let count = leadingNumber(in: message) ?? "若干"
            return "\(count) 支已手动指挥军队未纳入方面军令。"
        }
        if message.hasPrefix("Pacification target "), message.contains(" skipped:") {
            return "招抚候选已跳过：目标或谈判军队不符合当前规则。"
        }
        return nil
    }

    private static func commandAction(in message: String) -> String? {
        let pairs: [(String, String)] = [
            ("行军(", "行军"),
            ("Move(", "行军"),
            ("进攻(", "进攻"),
            ("Attack(", "进攻"),
            ("围城(", "围城"),
            ("Besiege(", "围城"),
            ("修城(", "修城"),
            ("RepairFortification(", "修城"),
            ("解围(", "解围"),
            ("RelieveSiege(", "解围"),
            ("招降(", "招降"),
            ("DemandSurrender(", "招降"),
            ("招抚(", "招抚"),
            ("ProposeSubmission(", "招抚"),
            ("固守(", "固守"),
            ("Hold(", "固守"),
            ("准退(", "准退"),
            ("AllowRetreat(", "准退"),
            ("休整(", "休整"),
            ("Resupply(", "休整"),
            ("军备(", "军备"),
            ("QueueProduction(", "军备"),
            ("结束回合", "结束回合"),
            ("End Turn", "结束回合")
        ]
        return pairs.first { message.contains($0.0) }?.1
    }

    private static func validationErrors(in message: String) -> String {
        var output = message
        for (raw, localized) in validationErrorNames {
            output = output.replacingOccurrences(of: raw, with: localized)
        }
        if output.hasPrefix("Region "), output.contains(" controller changed to ") {
            let body = output
                .replacingOccurrences(of: "Region ", with: "州府 ")
                .replacingOccurrences(of: " controller changed to ", with: " 归属改为 ")
                .replacingOccurrences(of: ".", with: "")
            return "\(body)。"
        }
        if output.hasPrefix("Hex "), output.contains(" reassigned to dynamic theater ") {
            let body = output
                .replacingOccurrences(of: "Hex ", with: "地块 ")
                .replacingOccurrences(of: " reassigned to dynamic theater ", with: " 归入动态方面 ")
                .replacingOccurrences(of: ".", with: "")
            return "\(body)。"
        }
        if containsLatinLetters(output) {
            return "战报已更新；原始记录留在调试日志中。"
        }
        return output
    }

    private static func validationReason(in message: String) -> String {
        let localized = validationErrors(in: message)
        let knownReasons = validationErrorNames
            .filter { message.contains($0.raw) || localized.contains($0.value) }
            .map(\.value)
        guard !knownReasons.isEmpty else {
            return ""
        }
        return "原因：\(Array(Set(knownReasons)).sorted().joined(separator: "、"))。"
    }

    private static let validationErrorNames: [(raw: String, value: String)] = [
        ("wrongPhase", "阶段不允许"),
        ("wrongFaction", "不归当前亲征势力"),
        ("divisionNotFound", "军队不存在"),
        ("targetNotFound", "目标不存在"),
        ("countryNotFound", "国家不存在"),
        ("alreadyActed", "军队已行动"),
        ("destinationOutOfBounds", "目标越界"),
        ("destinationOccupied", "目标地块被占"),
        ("noPath", "无可用路径"),
        ("insufficientMovement", "行动力不足"),
        ("targetOutOfRange", "目标超出射程"),
        ("invalidTargetFaction", "目标关系不合法"),
        ("regionNotFound", "州府不存在"),
        ("invalidRegionForHex", "地块州府不匹配"),
        ("invalidSiegeTarget", "围城目标不合法"),
        ("noActiveSiege", "没有有效围城"),
        ("fortificationAlreadyFull", "城防已满"),
        ("capitulationNotReady", "尚未满足招降条件"),
        ("invalidDiplomaticRelation", "外交关系不合法"),
        ("submissionNotReady", "尚未满足归附条件"),
        ("mandateTooLow", "天命不足"),
        ("insufficientResources", "资源不足"),
        ("supplyBlocked", "粮道断绝，不可主动出击")
    ]

    private static func stripped(_ message: String, prefix: String, suffix: String) -> String {
        var value = message
        if value.hasPrefix(prefix) {
            value.removeFirst(prefix.count)
        }
        if value.hasSuffix(suffix) {
            value.removeLast(suffix.count)
        }
        return value
    }

    private static func number(after marker: String, in message: String) -> String? {
        guard let range = message.range(of: marker) else {
            return nil
        }
        return leadingNumber(in: String(message[range.upperBound...]))
    }

    private static func trimTrailingPeriod(_ value: String) -> String {
        value.trimmingCharacters(in: CharacterSet(charactersIn: "."))
    }

    private static func leadingNumber(in text: String) -> String? {
        let digits = text.prefix { $0.isNumber }
        return digits.isEmpty ? nil : String(digits)
    }

    private static func containsLatinLetters(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            (65...90).contains(Int(scalar.value)) || (97...122).contains(Int(scalar.value))
        }
    }

    private static func finalized(_ output: String) -> String {
        containsLatinLetters(output) ? "战报已更新；原始记录留在调试日志中。" : output
    }
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
