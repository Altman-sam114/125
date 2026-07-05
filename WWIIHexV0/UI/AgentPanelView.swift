import SwiftUI

struct AgentPanelView: View {
    let record: AgentDecisionRecord?
    let rulerRecord: RulerDecisionRecord?
    let directiveRecords: [WarDirectiveRecord]
    let isTangSongScenario: Bool

    init(
        record: AgentDecisionRecord?,
        rulerRecord: RulerDecisionRecord? = nil,
        directiveRecords: [WarDirectiveRecord] = [],
        isTangSongScenario: Bool = false
    ) {
        self.record = record
        self.rulerRecord = rulerRecord
        self.directiveRecords = directiveRecords
        self.isTangSongScenario = isTangSongScenario
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(isTangSongScenario ? "军议" : "AI Decision")
                .font(.headline)

            LabeledContent(isTangSongScenario ? "主事" : "Agent") {
                Text(record?.agentId ?? (isTangSongScenario ? "privy_council" : "guderian"))
            }

            LabeledContent(isTangSongScenario ? "来源" : "Provider") {
                Text(record?.provider ?? (isTangSongScenario ? "确定性军议" : "MockAI"))
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
                    Text(rulerRecord.rulerAgentId)
                }
                LabeledContent(isTangSongScenario ? "国策" : "Posture") {
                    Text(rulerRecord.posture.displayName)
                }
                if let zoneId = rulerRecord.preferredFrontZoneId {
                    LabeledContent(isTangSongScenario ? "重点" : "Focus") {
                        Text(zoneId.rawValue)
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
                            Text(result.commandDisplayName ?? result.orderType?.rawValue ?? "Order")
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
                                Text(directive.zoneId?.rawValue ?? "global")
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
                                Text((isTangSongScenario ? "将令：" : "Commander: ") + commanderAgentId)
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
        let targets = directive.targetRegionIds.map(\.rawValue).joined(separator: ", ")
        let targetText = targets.isEmpty ? (isTangSongScenario ? "无目标" : "no target") : targets
        if isTangSongScenario {
            return "\(type) / \(tactic) / 成 \(executed)，拒 \(rejected) / \(targetText)"
        }
        return "\(type) / \(tactic) / \(executed) ok, \(rejected) rejected / \(targetText)"
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
        regionIds.map(\.rawValue).joined(separator: ", ")
    }

    private var rawJSONPlaceholder: String {
        """
        {
          "agentId": "\(isTangSongScenario ? "privy_council" : "guderian")",
          "status": "placeholder",
          "orders": []
        }
        """
    }
}
