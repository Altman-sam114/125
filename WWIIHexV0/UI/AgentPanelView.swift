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
                Text(intentDisplayText)
                    .multilineTextAlignment(.trailing)
            }

            if let contextSummary = contextDisplayText {
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
                        Text(displayName(for: zoneId))
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
                    if let mandateIntent = tangSongNarrativeText(
                        theaterSummary.mandateIntent,
                        fallback: "诏令已汇总"
                    ) {
                        LabeledContent("诏令") {
                            Text(mandateIntent)
                                .multilineTextAlignment(.trailing)
                        }
                    }

                    if let courtPolicy = tangSongNarrativeText(
                        theaterSummary.courtPolicy,
                        fallback: "朝议已拟定"
                    ) {
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

                    if let summary = tangSongNarrativeText(
                        theaterSummary.summary,
                        fallback: "军议摘要已形成"
                    ) {
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
                                if isTangSongScenario {
                                    Text("军令诊断：\(directive.diagnostics.count)项，详文已留存")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                } else {
                                    Text(directive.diagnostics.joined(separator: " / "))
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                }
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
                    if isTangSongScenario {
                        Text("军议未成：\(record.errors.count)项，详文已留存")
                        .font(.caption)
                        .foregroundStyle(.red)
                    } else {
                        ForEach(record.errors, id: \.self) { error in
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }

            rawJSONSection
        }
        .padding(12)
        .background(PlatformStyles.systemBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var rawJSONSection: some View {
        if isTangSongScenario {
            Text(displayText(record?.rawJSON) == nil ? "暂无军议原文" : "军议原文已记录")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            Text("Raw JSON")
                .font(.caption)
                .foregroundStyle(.secondary)

            debugTextBlock(record?.rawJSON ?? rawJSONPlaceholder)
        }
    }

    private func debugTextBlock(_ text: String) -> some View {
        Text(text)
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(PlatformStyles.tertiarySystemBackground)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func directiveSummary(_ directive: WarDirectiveRecord) -> String {
        let type = directive.directiveType?.displayName(isTangSongScenario: isTangSongScenario)
            ?? (isTangSongScenario ? "诊断" : "diagnostic")
        let tactic = directive.tactic?.displayName(isTangSongScenario: isTangSongScenario)
            ?? directive.category?.displayName(isTangSongScenario: isTangSongScenario)
            ?? (isTangSongScenario ? "无战术" : "none")
        let executed = directive.commandResults.filter(\.executed).count
        let rejected = directive.commandResults.count - executed
        let targets = directive.targetRegionIds.map(displayName).joined(separator: isTangSongScenario ? "、" : ", ")
        let targetText = targets.isEmpty ? (isTangSongScenario ? "无目标" : "no target") : targets
        if isTangSongScenario {
            return "\(type) · \(tactic) · 成 \(executed)，拒 \(rejected) · \(targetText)"
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
        if commandDisplayName.contains("(") || containsRawTextRisk(commandDisplayName) {
            return "军令"
        }
        return commandDisplayName
    }

    private func resultLine(_ result: CommandResultSummary) -> String {
        if isTangSongScenario {
            if !result.mappingSucceeded {
                return "军令未成：映射失败"
            }
            if result.executed {
                return "已执行"
            }
            if !result.errors.isEmpty {
                return "规则拒绝：\(result.errors.count)项"
            }
            if result.validationSucceeded == false {
                return "规则拒绝"
            }
            return "未执行"
        }

        if !result.mappingSucceeded {
            return "Mapping failed: \(result.errors.joined(separator: ", "))"
        }

        if result.executed {
            return result.message
        }

        if !result.errors.isEmpty {
            return "Rejected: \(result.errors.joined(separator: ", "))"
        }

        return result.message
    }

    private func displayText(_ value: String?) -> String? {
        guard let text = value?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            return nil
        }
        return text
    }

    private func tangSongNarrativeText(_ value: String?, fallback: String) -> String? {
        guard let text = displayText(value) else {
            return nil
        }
        return containsRawTextRisk(text) ? fallback : text
    }

    private func containsRawTextRisk(_ text: String) -> Bool {
        containsLatinLetter(text)
            || text.contains("{")
            || text.contains("}")
            || text.contains("[")
            || text.contains("]")
            || text.contains("\"")
            || text.contains("_")
    }

    private func containsLatinLetter(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            (65...90).contains(Int(scalar.value)) || (97...122).contains(Int(scalar.value))
        }
    }

    private func regionList(_ regionIds: [RegionId]) -> String {
        regionIds.map(displayName).joined(separator: isTangSongScenario ? "、" : ", ")
    }

    private func directiveZoneTitle(_ zoneId: FrontZoneId?) -> String {
        guard let zoneId else {
            return isTangSongScenario ? "全局军令" : "global"
        }
        return displayName(for: zoneId)
    }

    private func displayName(for regionId: RegionId) -> String {
        let name = regionDisplayName(regionId)
        if isTangSongScenario, name == regionId.rawValue {
            return "未命名州府"
        }
        return name
    }

    private func displayName(for zoneId: FrontZoneId) -> String {
        let name = zoneDisplayName(zoneId)
        if isTangSongScenario, name == zoneId.rawValue {
            return "未命名方面"
        }
        return name
    }

    private var intentDisplayText: String {
        if isTangSongScenario {
            if let summary = tangSongNarrativeText(
                record?.theaterDirectiveSummary?.summary,
                fallback: "军议摘要已形成"
            ) {
                return summary
            }
            if let strategicIntent = tangSongNarrativeText(
                record?.theaterDirectiveSummary?.strategicIntent,
                fallback: "已形成方面军令"
            ) {
                return strategicIntent
            }
            if record != nil {
                return "已形成方面军令"
            }
            return "暂无军议"
        }
        return record?.parsedIntent ?? "No decision submitted"
    }

    private var contextDisplayText: String? {
        guard let contextSummary = displayText(record?.contextSummary) else {
            return nil
        }
        guard isTangSongScenario else {
            return contextSummary
        }

        let normalized = contextSummary.lowercased()
        if normalized.contains("marshal")
            || normalized.contains("directive")
            || normalized.contains("json")
            || containsRawTextRisk(contextSummary) {
            return "已汇总战场、粮道与方面态势"
        }
        return contextSummary
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
          "agentId": "guderian",
          "status": "placeholder",
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
