import SwiftUI

struct AgentPanelView: View {
    let record: AgentDecisionRecord?
    let rulerRecord: RulerDecisionRecord?
    let directiveRecords: [WarDirectiveRecord]
    let isTangSongScenario: Bool
    let regionDisplayName: (RegionId) -> String
    let zoneDisplayName: (FrontZoneId) -> String

    init(
        record: AgentDecisionRecord?,
        rulerRecord: RulerDecisionRecord? = nil,
        directiveRecords: [WarDirectiveRecord] = [],
        isTangSongScenario: Bool = false,
        regionDisplayName: @escaping (RegionId) -> String = { $0.rawValue },
        zoneDisplayName: @escaping (FrontZoneId) -> String = { $0.rawValue }
    ) {
        self.record = record
        self.rulerRecord = rulerRecord
        self.directiveRecords = directiveRecords
        self.isTangSongScenario = isTangSongScenario
        self.regionDisplayName = regionDisplayName
        self.zoneDisplayName = zoneDisplayName
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(isTangSongScenario ? "军议" : "AI Decision")
                .font(.headline)

            LabeledContent(isTangSongScenario ? "主事" : "Agent") {
                Text(agentDisplayName(record?.agentId))
            }

            LabeledContent(isTangSongScenario ? "来源" : "Provider") {
                Text(providerDisplayName(record?.provider))
            }

            LabeledContent(isTangSongScenario ? "意图" : "Intent") {
                Text(record?.parsedIntent ?? (isTangSongScenario ? "暂无军议" : "No decision submitted"))
                    .multilineTextAlignment(.trailing)
            }

            if let contextSummary = record?.contextSummary {
                LabeledContent(isTangSongScenario ? "战况" : "Context") {
                    Text(contextSummary)
                        .multilineTextAlignment(.trailing)
                }
            }

            if let rulerRecord {
                Divider()
                LabeledContent(isTangSongScenario ? "君主" : "Ruler") {
                    Text(agentDisplayName(rulerRecord.rulerAgentId))
                }
                LabeledContent(isTangSongScenario ? "国策" : "Posture") {
                    Text(rulerRecord.posture.displayName(isTangSongScenario: isTangSongScenario))
                }
                if let zoneId = rulerRecord.preferredFrontZoneId {
                    LabeledContent(isTangSongScenario ? "重点" : "Focus") {
                        Text(zoneDisplayName(zoneId))
                    }
                }
            }

            if isTangSongScenario,
               let theaterSummary = record?.theaterDirectiveSummary,
               theaterSummary.hasDisplayableContent {
                Text("诏令朝议")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 6) {
                    if let mandateIntent = displayText(theaterSummary.mandateIntent) {
                        LabeledContent("诏令") {
                            Text(mandateIntent)
                                .multilineTextAlignment(.trailing)
                        }
                    }

                    if let courtPolicy = displayText(theaterSummary.courtPolicy) {
                        LabeledContent("朝议") {
                            Text(courtPolicy)
                                .multilineTextAlignment(.trailing)
                        }
                    }

                    if !theaterSummary.pacificationTargets.isEmpty {
                        LabeledContent("招抚") {
                            Text(regionList(theaterSummary.pacificationTargets))
                                .multilineTextAlignment(.trailing)
                        }
                    }

                    if !theaterSummary.supplyPriorities.isEmpty {
                        LabeledContent("转运") {
                            Text(regionList(theaterSummary.supplyPriorities))
                                .multilineTextAlignment(.trailing)
                        }
                    }

                    if let summary = displayText(theaterSummary.summary) {
                        LabeledContent("摘要") {
                            Text(summary)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
                .font(.caption)
                .padding(6)
                .background(PlatformStyles.tertiarySystemBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            if let record, !record.commandResults.isEmpty {
                Text(isTangSongScenario ? "军令结果" : "Command Results")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(record.commandResults) { result in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(commandResultTitle(result))
                                .font(.caption)
                                .bold()
                            Text(resultLine(result))
                                .font(.caption)
                                .foregroundStyle(result.executed ? .primary : .secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            if !directiveRecords.isEmpty {
                Text(isTangSongScenario ? "方面军令" : "Zone Directives")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(directiveRecords) { directive in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text(directiveZoneTitle(directive.zoneId))
                                    .font(.caption.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(PlatformStyles.selectionTint)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))

                                Text(directiveSummary(directive))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                            }

                            if let commanderAgentId = directive.commanderAgentId {
                                Text((isTangSongScenario ? "将令：" : "Commander: ") + agentDisplayName(commanderAgentId))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            if !directive.diagnostics.isEmpty {
                                Text(directive.diagnostics.joined(separator: " / "))
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(6)
                        .background(PlatformStyles.tertiarySystemBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }

            if let record, !record.errors.isEmpty {
                Text(isTangSongScenario ? "异常" : "Errors")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(record.errors, id: \.self) { error in
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }

            Text(isTangSongScenario ? "原始 JSON" : "Raw JSON")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(record?.rawJSON ?? rawJSONPlaceholder)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(PlatformStyles.tertiarySystemBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(12)
        .background(PlatformStyles.systemBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func directiveSummary(_ directive: WarDirectiveRecord) -> String {
        let type = directive.directiveType?.displayName(isTangSongScenario: isTangSongScenario)
            ?? (isTangSongScenario ? "诊断" : "diagnostic")
        let tactic = directive.tactic?.displayName(isTangSongScenario: isTangSongScenario)
            ?? directive.category?.displayName(isTangSongScenario: isTangSongScenario)
            ?? (isTangSongScenario ? "无战术" : "none")
        let executed = directive.commandResults.filter(\.executed).count
        let rejected = directive.commandResults.count - executed
        let targets = directive.targetRegionIds.map(regionDisplayName).joined(separator: ", ")
        let targetText = targets.isEmpty ? (isTangSongScenario ? "无目标" : "no target") : targets
        if isTangSongScenario {
            return "\(type) / \(tactic) / 成 \(executed)，拒 \(rejected) / \(targetText)"
        }
        return "\(type) / \(tactic) / \(executed) ok, \(rejected) rejected / \(targetText)"
    }

    private func commandResultTitle(_ result: CommandResultSummary) -> String {
        if let commandDisplayName = displayText(result.commandDisplayName) {
            return commandDisplayTitle(commandDisplayName)
        }
        if let orderType = result.orderType {
            return orderType.displayName(isTangSongScenario: isTangSongScenario)
        }
        return isTangSongScenario ? "军令" : "Order"
    }

    private func commandDisplayTitle(_ commandDisplayName: String) -> String {
        guard isTangSongScenario else {
            return commandDisplayName
        }

        let normalized = commandDisplayName.lowercased()
        if normalized.hasPrefix("move(") || commandDisplayName.hasPrefix("行军(") {
            return "行军"
        }
        if normalized.hasPrefix("attack(") || commandDisplayName.hasPrefix("进攻(") {
            return "进攻"
        }
        if normalized.hasPrefix("besiege(") || commandDisplayName.hasPrefix("围城(") {
            return "围城"
        }
        if normalized.hasPrefix("repairfortification(") || commandDisplayName.hasPrefix("修城(") {
            return "修城"
        }
        if normalized.hasPrefix("relievesiege(") || commandDisplayName.hasPrefix("解围(") {
            return "解围"
        }
        if normalized.hasPrefix("demandsurrender(") || commandDisplayName.hasPrefix("招降(") {
            return "招降"
        }
        if normalized.hasPrefix("proposesubmission(") || commandDisplayName.hasPrefix("招抚(") {
            return "招抚"
        }
        if normalized.hasPrefix("pacificationcandidate(") || commandDisplayName.hasPrefix("招抚候选(") {
            return "招抚候选"
        }
        if normalized.hasPrefix("hold(") || commandDisplayName.hasPrefix("固守(") {
            return "固守"
        }
        if normalized.hasPrefix("allowretreat(") || commandDisplayName.hasPrefix("准退(") {
            return "准退"
        }
        if normalized.hasPrefix("resupply(") || commandDisplayName.hasPrefix("休整(") {
            return "休整"
        }
        if normalized.hasPrefix("queueproduction(") || commandDisplayName.hasPrefix("军备(") {
            return "军备"
        }
        if normalized == "end turn" || commandDisplayName == "结束回合" {
            return "结束回合"
        }
        return commandDisplayName.contains("(") ? "军令" : commandDisplayName
    }

    private func resultLine(_ result: CommandResultSummary) -> String {
        if !result.mappingSucceeded {
            let prefix = isTangSongScenario ? "映射失败" : "Mapping failed"
            return "\(prefix): \(result.errors.joined(separator: ", "))"
        }

        if result.executed {
            return result.message
        }

        if !result.errors.isEmpty {
            let prefix = isTangSongScenario ? "规则拒绝" : "Rejected"
            return "\(prefix): \(result.errors.joined(separator: ", "))"
        }

        return result.message
    }

    private func displayText(_ value: String?) -> String? {
        guard let text = value?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            return nil
        }
        return text
    }

    private func regionList(_ regionIds: [RegionId]) -> String {
        regionIds.map(regionDisplayName).joined(separator: ", ")
    }

    private func directiveZoneTitle(_ zoneId: FrontZoneId?) -> String {
        guard let zoneId else {
            return isTangSongScenario ? "全局军令" : "global"
        }
        return zoneDisplayName(zoneId)
    }

    private func agentDisplayName(_ agentId: String?) -> String {
        guard let agentId = displayText(agentId) else {
            return isTangSongScenario ? "宋枢密院" : "guderian"
        }
        guard isTangSongScenario else {
            return agentId
        }

        let normalized = agentId.lowercased()
        if normalized.contains("privy") || normalized.contains("song") || normalized == "guderian" {
            return "宋枢密院"
        }
        if normalized.contains("separatist") || normalized.contains("warlord") || normalized.contains("germany") {
            return "割据行营"
        }
        if normalized.contains("ruler") || normalized.contains("emperor") {
            return "君主诏令"
        }
        if normalized.contains("commander") || normalized.contains("zone") {
            return "方面主将"
        }
        return "军议主事"
    }

    private func providerDisplayName(_ provider: String?) -> String {
        guard let provider = displayText(provider) else {
            return isTangSongScenario ? "确定性军议" : "MockAI"
        }
        guard isTangSongScenario else {
            return provider
        }

        let normalized = provider.lowercased()
        if normalized.contains("mock") || normalized.contains("simulated") || normalized.contains("deterministic") {
            return "确定性军议"
        }
        if normalized.contains("local") || normalized.contains("llm") {
            return "本地军议"
        }
        return "军议来源"
    }

    private var rawJSONPlaceholder: String {
        """
        {
          "agentId": "\(isTangSongScenario ? "宋枢密院" : "guderian")",
          "status": "\(isTangSongScenario ? "暂无军议" : "placeholder")",
          "orders": []
        }
        """
    }
}

private extension AgentOrderType {
    func displayName(isTangSongScenario: Bool) -> String {
        guard isTangSongScenario else {
            return rawValue
        }
        switch self {
        case .move:
            return "行军"
        case .attack:
            return "进攻"
        case .hold:
            return "固守"
        case .resupply:
            return "整补"
        }
    }
}

private extension RulerStrategicPosture {
    func displayName(isTangSongScenario: Bool) -> String {
        guard isTangSongScenario else {
            return displayName
        }
        switch self {
        case .offensive:
            return "进取"
        case .defensive:
            return "固守"
        case .coalitionMaintenance:
            return "维系诸国"
        case .stabilizeFront:
            return "安定边面"
        }
    }
}
