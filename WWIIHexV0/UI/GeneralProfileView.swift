import SwiftUI

struct GeneralProfileView: View {
    let general: GeneralData
    let assignment: GeneralAssignment?
    let zone: FrontZone?
    let assignedDivisions: [Division]
    let hqUnderAttack: Bool
    let isTangSongScenario: Bool
    let factionDisplayName: (Faction) -> String
    let onClose: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 16) {
                    identityBlock
                    VStack(alignment: .leading, spacing: 12) {
                        biographyBlock
                        statusBlock
                    }
                }

                skillsBlock
                assignedUnitsBlock
            }
            .padding(18)
        }
        .background(.ultraThinMaterial)
        .safeAreaInset(edge: .top) {
            HStack {
                Text(isTangSongScenario ? "将领档案" : "General Profile")
                    .font(.headline)
                Spacer()
                Button(isTangSongScenario ? "关闭" : "Close", systemImage: "xmark", action: onClose)
                    .buttonStyle(.bordered)
                    .accessibilityLabel(isTangSongScenario ? "关闭将领档案" : "Close General Profile")
                    .accessibilityHint(isTangSongScenario ? "返回当前战局面板。" : "Returns to the current game panel.")
            }
            .padding(12)
            .background(PlatformStyles.systemBackground)
        }
    }

    private var identityBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(initials)
                .font(.title.weight(.bold))
                .frame(width: 112, height: 144)
                .background(PlatformStyles.selectionTint)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityHidden(true)

            Text(general.localizedName)
                .font(.title3.weight(.semibold))
            Text(rankLabel(for: general))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(factionDisplayName(general.faction))
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(PlatformStyles.tertiarySystemBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .frame(minWidth: 132, alignment: .leading)
    }

    private var biographyBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isTangSongScenario ? "履历" : "Biography")
                .font(.headline)
            Text(biographyText(for: general))
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            LabeledContent(isTangSongScenario ? "用兵" : "Command Style") {
                Text(styleLabel(general.commandStyle))
            }
            if let zone {
                LabeledContent(isTangSongScenario ? "所辖方面" : "Assigned Zone") {
                    Text(zoneDisplayName(for: zone))
                        .multilineTextAlignment(.trailing)
                }
            }
            if hqUnderAttack {
                Label(isTangSongScenario ? "本营州府受敌压迫" : "HQ region contested", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
                    .accessibilityLabel(isTangSongScenario ? "警告：本营州府受敌压迫" : "Warning: HQ region contested")
            }
        }
    }

    private var statusBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isTangSongScenario ? "朝廷关系" : "Relationship")
                .font(.headline)
            metricBar(title: isTangSongScenario ? "忠诚" : "Loyalty", value: assignment?.loyalty ?? general.baseLoyalty)
            metricBar(title: isTangSongScenario ? "军心" : "Satisfaction", value: assignment?.satisfaction ?? general.baseSatisfaction)
            LabeledContent(isTangSongScenario ? "亲征干预" : "Player Interventions") {
                Text("\(assignment?.interventionCount ?? 0)")
            }
        }
    }

    private var skillsBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isTangSongScenario ? "特长" : "Skills")
                .font(.headline)
            if general.skills.isEmpty {
                Text(isTangSongScenario ? "暂无特长配置。" : "No explicit skills configured.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], alignment: .leading, spacing: 8) {
                    ForEach(general.skills, id: \.self) { skill in
                        Label(skillLabel(skill), systemImage: "star.fill")
                            .font(.caption.weight(.semibold))
                            .lineLimit(2)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(PlatformStyles.tertiarySystemBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(skillAccessibilityLabel(skill))
                    }
                }
            }
        }
    }

    private var assignedUnitsBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isTangSongScenario ? "辖下军队" : "Assigned Units")
                .font(.headline)
            if assignedDivisions.isEmpty {
                Text(isTangSongScenario ? "暂无在列军队。" : "No active divisions assigned.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(assignedDivisions, id: \.id) { division in
                    LabeledContent(division.name) {
                        Text(strengthText(for: division))
                    }
                    .font(.caption)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(unitAccessibilityLabel(for: division))
                    .accessibilityValue(strengthAccessibilityText(for: division))
                }
            }
        }
    }

    private func metricBar(title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text("\(value)")
            }
            .font(.caption)
            ProgressView(value: Double(value), total: 100)
                .tint(value >= 65 ? .green : value >= 40 ? .orange : .red)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(metricAccessibilityValue(value))
    }

    private var initials: String {
        if isTangSongScenario {
            let firstCharacter = general.localizedName.trimmingCharacters(in: .whitespacesAndNewlines).first
            if let firstCharacter, !containsLatinLetters(String(firstCharacter)) {
                return String(firstCharacter)
            }
            return "将"
        }
        let words = general.localizedName.split(separator: " ")
        let letters = words.prefix(2).compactMap(\.first)
        return letters.isEmpty ? String(general.name.prefix(2)).uppercased() : String(letters).uppercased()
    }

    private func styleLabel(_ style: ZoneCommanderAgentConfig.CommandStyle) -> String {
        if isTangSongScenario {
            switch style {
            case .aggressive:
                return "锐进"
            case .balanced:
                return "持重"
            case .cautious:
                return "谨慎"
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

    private func skillAccessibilityLabel(_ skill: String) -> String {
        isTangSongScenario ? "特长：\(skillLabel(skill))" : "Skill: \(skillLabel(skill))"
    }

    private func zoneDisplayName(for zone: FrontZone) -> String {
        guard isTangSongScenario else {
            return zone.name
        }
        let trimmed = zone.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || containsLatinLetters(trimmed) {
            return "未命名方面"
        }
        return trimmed
    }

    private func metricAccessibilityValue(_ value: Int) -> String {
        isTangSongScenario ? "\(value)，满百" : "\(value) out of 100"
    }

    private func unitAccessibilityLabel(for division: Division) -> String {
        isTangSongScenario ? "\(division.name)，兵力" : "\(division.name), strength"
    }

    private func strengthText(for division: Division) -> String {
        isTangSongScenario
            ? "\(division.strength)／\(division.maxStrength)"
            : "\(division.strength)/\(division.maxStrength)"
    }

    private func strengthAccessibilityText(for division: Division) -> String {
        isTangSongScenario
            ? "\(division.strength)，满额\(division.maxStrength)"
            : "\(division.strength) out of \(division.maxStrength)"
    }
}
