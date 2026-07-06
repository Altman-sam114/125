import SwiftUI

struct DiplomacyPanelView: View {
    let diplomacyState: DiplomacyState
    let activeFaction: Faction
    let mandateState: MandateState
    let isTangSongScenario: Bool
    let factionDisplayName: (Faction) -> String
    let regionDisplayName: (RegionId) -> String
    let zoneDisplayName: (FrontZoneId) -> String

    init(
        diplomacyState: DiplomacyState,
        activeFaction: Faction,
        mandateState: MandateState = .empty,
        isTangSongScenario: Bool = false,
        factionDisplayName: @escaping (Faction) -> String = { $0.displayName },
        regionDisplayName: @escaping (RegionId) -> String = { $0.rawValue },
        zoneDisplayName: @escaping (FrontZoneId) -> String = { $0.rawValue }
    ) {
        self.diplomacyState = diplomacyState
        self.activeFaction = activeFaction
        self.mandateState = mandateState
        self.isTangSongScenario = isTangSongScenario
        self.factionDisplayName = factionDisplayName
        self.regionDisplayName = regionDisplayName
        self.zoneDisplayName = zoneDisplayName
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(isTangSongScenario ? "外交" : "Diplomacy")
                .font(.headline)

            if let rulerRecord = diplomacyState.latestRulerRecord {
                rulerSection(rulerRecord)
                Divider()
            }

            mandateSection
            Divider()
            countrySection
            Divider()
            blocSection
            Divider()
            relationSection
            Divider()
            pacificationSection
        }
        .padding(12)
        .background(PlatformStyles.systemBackground)
        .clipShape(.rect(cornerRadius: 8))
    }

    private var mandateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isTangSongScenario ? "天命" : "Legitimacy")
                .font(.subheadline.weight(.semibold))

            ForEach(mandateFactions, id: \.self) { faction in
                LabeledContent(displayName(for: faction)) {
                    Text("\(mandateState.legitimacy(for: faction))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(faction == activeFaction ? .primary : .secondary)
                }
                .font(.caption)
            }
        }
    }

    private var countrySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isTangSongScenario ? "诸国" : "Countries")
                .font(.subheadline.weight(.semibold))

            ForEach(diplomacyState.countries) { country in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(country.name)
                            .font(.caption.weight(.semibold))
                        Text(countrySubtitle(country))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(warSupportText(country.warSupport))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(country.faction == activeFaction ? .primary : .secondary)
                }
            }
        }
    }

    private var blocSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isTangSongScenario ? "集团" : "Blocs")
                .font(.subheadline.weight(.semibold))

            ForEach(diplomacyState.blocs) { bloc in
                LabeledContent(bloc.name) {
                    Text(isTangSongScenario ? "\(bloc.memberCountryIds.count) 国" : "\(bloc.memberCountryIds.count) member(s)")
                        .foregroundStyle(bloc.faction == activeFaction ? .primary : .secondary)
                }
                .font(.caption)
            }
        }
    }

    private var relationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isTangSongScenario ? "关系" : "Relations")
                .font(.subheadline.weight(.semibold))

            if diplomacyState.relations.isEmpty {
                Text(isTangSongScenario ? "暂无外交关系。" : "No diplomatic relations.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(diplomacyState.relations) { relation in
                    HStack {
                        Text("\(countryName(relation.firstCountryId)) - \(countryName(relation.secondCountryId))")
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                        Text(relation.status.displayName(isTangSongScenario: isTangSongScenario))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(relation.status.isHostile ? .red : .secondary)
                    }
                }
            }
        }
    }

    private var pacificationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isTangSongScenario ? "归附记录" : "Pacification")
                .font(.subheadline.weight(.semibold))

            if diplomacyState.pacificationRecords.isEmpty {
                Text(isTangSongScenario ? "暂无招抚记录。" : "No pacification records.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(recentPacificationRecords) { record in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("\(countryName(record.actorCountryId)) -> \(countryName(record.targetCountryId))")
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                            Spacer()
                            Text(record.resultStatus.displayName(isTangSongScenario: isTangSongScenario))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text(pacificationDetail(record))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }
        }
    }

    private func rulerSection(_ record: RulerDecisionRecord) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(isTangSongScenario ? "君主" : "Ruler")
                .font(.subheadline.weight(.semibold))
            LabeledContent(isTangSongScenario ? "主事" : "Agent") {
                Text(rulerDisplayName(record.rulerAgentId))
            }
            LabeledContent(isTangSongScenario ? "国策" : "Posture") {
                Text(record.posture.displayName(isTangSongScenario: isTangSongScenario))
            }
            if let zoneId = record.preferredFrontZoneId {
                LabeledContent(isTangSongScenario ? "重点" : "Focus") {
                    Text(displayName(for: zoneId))
                }
            }
            Text(rulerRationale(record))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .font(.caption)
    }

    private var mandateFactions: [Faction] {
        let factions = Set(diplomacyState.countries.map(\.faction) + Faction.allCases)
        return factions.sorted { $0.rawValue < $1.rawValue }
    }

    private var recentPacificationRecords: [PacificationRecord] {
        Array(diplomacyState.pacificationRecords.suffix(5).reversed())
    }

    private func countryName(_ countryId: CountryId) -> String {
        diplomacyState.country(id: countryId)?.name ?? (isTangSongScenario ? "未知政权" : countryId.rawValue)
    }

    private func countrySubtitle(_ country: CountryProfile) -> String {
        let blocName = diplomacyState.blocs.first { $0.id == country.blocId }?.name
            ?? (isTangSongScenario ? "未命名集团" : country.blocId.rawValue)
        let separator = isTangSongScenario ? " / " : " | "
        return "\(displayName(for: country.faction))\(separator)\(blocName)"
    }

    private func warSupportText(_ warSupport: Int) -> String {
        isTangSongScenario ? "战意 \(warSupport)" : "\(warSupport)"
    }

    private func pacificationDetail(_ record: PacificationRecord) -> String {
        let regions = record.targetRegionIds.map { displayName(for: $0) }.joined(separator: ", ")
        if isTangSongScenario {
            return "回合 \(record.turn)；天命 \(record.mandateDelta >= 0 ? "+" : "")\(record.mandateDelta)；州府 \(regions)"
        }
        return "Turn \(record.turn); mandate \(record.mandateDelta >= 0 ? "+" : "")\(record.mandateDelta); regions \(regions)"
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

    private func displayName(for faction: Faction) -> String {
        let name = factionDisplayName(faction)
        guard isTangSongScenario else {
            return name
        }

        let normalized = name.lowercased()
        if normalized == faction.rawValue.lowercased()
            || normalized == faction.displayName.lowercased()
            || normalized == "germany" {
            return faction == .allies ? "宋" : "割据诸国"
        }
        return name
    }

    private func rulerDisplayName(_ rulerAgentId: String) -> String {
        guard isTangSongScenario else {
            return rulerAgentId
        }
        let normalized = rulerAgentId.lowercased()
        if normalized.contains("song") || normalized.contains("emperor") || normalized.contains("ruler") {
            return "君主诏令"
        }
        if normalized.contains("separatist") || normalized.contains("warlord") || normalized.contains("germany") {
            return "割据国主"
        }
        return "国主议事"
    }

    private func rulerRationale(_ record: RulerDecisionRecord) -> String {
        guard isTangSongScenario else {
            return record.rationale
        }

        let posture = record.posture.displayName(isTangSongScenario: true)
        if !record.targetRegionIds.isEmpty {
            let targets = record.targetRegionIds.map { displayName(for: $0) }.joined(separator: ", ")
            return "朝议：\(posture)，目标 \(targets)。"
        }
        if let zoneId = record.preferredFrontZoneId {
            return "朝议：\(posture)，重点 \(displayName(for: zoneId))。"
        }
        return "朝议：\(posture)，审时度势。"
    }
}

private extension DiplomaticStatus {
    func displayName(isTangSongScenario: Bool) -> String {
        guard isTangSongScenario else {
            return displayName
        }
        switch self {
        case .allied:
            return "盟好"
        case .tributary:
            return "称臣"
        case .coBelligerent:
            return "协战"
        case .neutral:
            return "中立"
        case .hostile:
            return "敌对"
        case .atWar:
            return "交战"
        case .submitting:
            return "归附中"
        case .negotiating:
            return "议和"
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
