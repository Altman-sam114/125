import SwiftUI

struct DiplomacyPanelView: View {
    let diplomacyState: DiplomacyState
    let activeFaction: Faction
    let mandateState: MandateState
    let isTangSongScenario: Bool
    let factionDisplayName: (Faction) -> String

    init(
        diplomacyState: DiplomacyState,
        activeFaction: Faction,
        mandateState: MandateState = .empty,
        isTangSongScenario: Bool = false,
        factionDisplayName: @escaping (Faction) -> String = { $0.displayName }
    ) {
        self.diplomacyState = diplomacyState
        self.activeFaction = activeFaction
        self.mandateState = mandateState
        self.isTangSongScenario = isTangSongScenario
        self.factionDisplayName = factionDisplayName
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
                LabeledContent(factionDisplayName(faction)) {
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
                        Text("\(factionDisplayName(country.faction)) | \(country.blocId.rawValue)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(country.warSupport)")
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
                        Text(relation.status.displayName)
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
                            Text(record.resultStatus.displayName)
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
                Text(record.rulerAgentId)
            }
            LabeledContent(isTangSongScenario ? "国策" : "Posture") {
                Text(record.posture.displayName)
            }
            if let zoneId = record.preferredFrontZoneId {
                LabeledContent(isTangSongScenario ? "重点" : "Focus") {
                    Text(zoneId.rawValue)
                }
            }
            Text(record.rationale)
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
        diplomacyState.country(id: countryId)?.name ?? countryId.rawValue
    }

    private func pacificationDetail(_ record: PacificationRecord) -> String {
        let regions = record.targetRegionIds.map(\.rawValue).joined(separator: ", ")
        if isTangSongScenario {
            return "回合 \(record.turn)；天命 \(record.mandateDelta >= 0 ? "+" : "")\(record.mandateDelta)；州府 \(regions)"
        }
        return "Turn \(record.turn); mandate \(record.mandateDelta >= 0 ? "+" : "")\(record.mandateDelta); regions \(regions)"
    }
}
