import SwiftUI

struct GeneralCommandPanelView: View {
    let zone: FrontZone?
    let general: GeneralData?
    let assignment: GeneralAssignment?
    let assignedDivisions: [Division]
    let targetRegion: RegionNode?
    let targetZone: FrontZone?
    let hqUnderAttack: Bool
    let plannedOperations: [PlayerPlannedOperation]
    let isTangSongScenario: Bool
    var regionDisplayName: ((RegionId) -> String)?
    var zoneDisplayName: ((FrontZoneId) -> String)?
    let canHoldLine: Bool
    let canAttackRegion: Bool
    let onShowProfile: () -> Void
    let onHoldLine: () -> Void
    let onAttackRegion: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(isTangSongScenario ? "将领军令" : "General Command")
                .font(.headline)

            if let zone {
                LabeledContent(isTangSongScenario ? "方面防区" : "Front Zone") {
                    Text(zone.name)
                        .multilineTextAlignment(.trailing)
                }
            } else {
                Text(isTangSongScenario ? "未选择亲征方面防区。" : "No allied front zone selected.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let general {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center, spacing: 10) {
                        Button(action: onShowProfile) {
                            portraitBadge(for: general)
                        }
                            .accessibilityLabel(profileAccessibilityLabel(for: general))
                            .buttonStyle(.plain)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(general.localizedName)
                                .font(.subheadline.weight(.semibold))
                            Text("\(rankLabel(for: general)) / \(styleLabel(general.commandStyle))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text(biographyText(for: general))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)

                    if !general.skills.isEmpty {
                        Text(general.skills.map(skillLabel).joined(separator: "、"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let assignment {
                        metricBar(title: isTangSongScenario ? "忠诚" : "Loyalty", value: assignment.loyalty)
                        metricBar(title: isTangSongScenario ? "军心" : "Satisfaction", value: assignment.satisfaction)
                        LabeledContent(isTangSongScenario ? "亲征干预" : "Interventions") {
                            Text("\(assignment.interventionCount)")
                        }
                    }

                    Button(isTangSongScenario ? "查看档案" : "View Profile", systemImage: "person.text.rectangle", action: onShowProfile)
                        .buttonStyle(.bordered)
                }
            } else if zone != nil {
                Text(isTangSongScenario ? "该方面尚未委任将领。" : "No general assigned to this zone.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if hqUnderAttack {
                Label(isTangSongScenario ? "本营州府受敌压迫" : "HQ region contested", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
            }

            if !assignedDivisions.isEmpty {
                Text(isTangSongScenario ? "所属军队" : "Assigned Units")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(assignedDivisions.prefix(5)), id: \.id) { division in
                        Label(division.name, systemImage: unitIcon(for: division))
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
            }

            if let targetRegion, targetZone?.faction != zone?.faction {
                LabeledContent(isTangSongScenario ? "目标州府" : "Target") {
                    Text(targetRegion.name)
                }
            }

            HStack(spacing: 8) {
                Button(isTangSongScenario ? "固守防线" : "Hold Line", systemImage: "shield.fill", action: onHoldLine)
                    .disabled(!canHoldLine)
                Button(isTangSongScenario ? "进攻州府" : "Attack Region", systemImage: "arrow.up.right.circle", action: onAttackRegion)
                    .disabled(!canAttackRegion)
            }
            .buttonStyle(.bordered)

            if !plannedOperations.isEmpty {
                Text(isTangSongScenario ? "已拟军令" : "Planned Operations")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(plannedOperations) { operation in
                        Label(operationSummary(operation), systemImage: operationIcon(operation))
                            .font(.caption)
                            .lineLimit(2)
                    }
                }
            }
        }
        .padding(12)
        .background(PlatformStyles.systemBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func portraitBadge(for general: GeneralData) -> some View {
        Text(initials(for: general))
            .font(.caption.weight(.bold))
            .frame(width: 40, height: 40)
            .background(PlatformStyles.selectionTint)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .accessibilityLabel(portraitAccessibilityLabel(for: general))
    }

    private func metricBar(title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(title)
                Spacer()
                Text("\(value)")
            }
            .font(.caption)
            ProgressView(value: Double(value), total: 100)
                .tint(value >= 65 ? .green : value >= 40 ? .orange : .red)
        }
    }

    private func initials(for general: GeneralData) -> String {
        let words = general.localizedName.split(separator: " ")
        let letters = words.prefix(2).compactMap(\.first)
        return letters.isEmpty ? String(general.name.prefix(2)).uppercased() : String(letters).uppercased()
    }

    private func styleLabel(_ style: ZoneCommanderAgentConfig.CommandStyle) -> String {
        if isTangSongScenario {
            switch style {
            case .aggressive:
                return "锐意进取"
            case .balanced:
                return "攻守持衡"
            case .cautious:
                return "谨慎持重"
            }
        }

        switch style {
        case .aggressive:
            return "Aggressive"
        case .balanced:
            return "Balanced"
        case .cautious:
            return "Cautious"
        }
    }

    private func rankLabel(for general: GeneralData) -> String {
        guard isTangSongScenario else {
            return general.rank
        }
        if !containsLatinLetters(general.rank) {
            return general.rank
        }
        return general.faction == .allies ? "禁军都部署" : "方面都部署"
    }

    private func biographyText(for general: GeneralData) -> String {
        guard isTangSongScenario else {
            return general.biography
        }
        if !containsLatinLetters(general.biography) {
            return general.biography
        }
        return "\(general.localizedName)受命统辖本方面军务，按州府、粮道与战线形势调度军队。"
    }

    private func skillLabel(_ skill: String) -> String {
        guard isTangSongScenario else {
            return skill.replacingOccurrences(of: "_", with: " ")
        }
        switch skill {
        case "set_piece_attack", "offensive_planning":
            return "筹攻"
        case "logistics", "staff_coordination", "coalition_coordination":
            return "转运"
        case "defensive_master", "fortress_operations", "reserve_control", "disciplined_retreat":
            return "守城"
        case "armor_theory", "armor_expert", "breakthrough", "rapid_exploitation", "counterattack":
            return "突进"
        case "political_will", "pressure_management", "army_group_coordination":
            return "统军"
        default:
            return containsLatinLetters(skill) ? "军务" : skill
        }
    }

    private func containsLatinLetters(_ text: String) -> Bool {
        text.range(of: #"[A-Za-z]"#, options: .regularExpression) != nil
    }

    private func unitIcon(for division: Division) -> String {
        if division.isArmor {
            return "shield.lefthalf.filled"
        }
        if division.isArtillery {
            return "scope"
        }
        return "person.3.fill"
    }

    private func operationIcon(_ operation: PlayerPlannedOperation) -> String {
        operation.directiveType == .attack ? "arrow.up.right.circle" : "shield.fill"
    }

    private func operationSummary(_ operation: PlayerPlannedOperation) -> String {
        if isTangSongScenario {
            let target = operationTargetName(operation)
            return "\(directiveLabel(operation.directiveType)) / \(target)"
        }
        let target = operation.targetRegionId?.rawValue ?? operation.sourceRegionId?.rawValue ?? operation.zoneId.rawValue
        return "\(operation.directiveType.rawValue) / \(target)"
    }

    private func operationTargetName(_ operation: PlayerPlannedOperation) -> String {
        if let targetRegionId = operation.targetRegionId {
            return regionDisplayName?(targetRegionId) ?? "未命名州府"
        }
        if let sourceRegionId = operation.sourceRegionId {
            return regionDisplayName?(sourceRegionId) ?? "未命名州府"
        }
        return zoneDisplayName?(operation.zoneId) ?? "未命名方面"
    }

    private func directiveLabel(_ type: DirectiveType) -> String {
        switch type {
        case .attack:
            return "进攻"
        case .defend:
            return "固守"
        }
    }

    private func profileAccessibilityLabel(for general: GeneralData) -> String {
        isTangSongScenario ? "打开\(general.localizedName)档案" : "Open profile for \(general.localizedName)"
    }

    private func portraitAccessibilityLabel(for general: GeneralData) -> String {
        isTangSongScenario ? "\(general.localizedName)头像占位" : "\(general.localizedName) portrait placeholder"
    }
}
