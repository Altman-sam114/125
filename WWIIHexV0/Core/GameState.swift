import Foundation

struct SiegeRecord: Codable, Equatable, Identifiable {
    var id: String {
        targetRegionId.rawValue
    }

    var targetRegionId: RegionId
    var attackerFaction: Faction
    var defenderFaction: Faction
    var startedTurn: Int
    var lastUpdatedTurn: Int
    var pressure: Int
    var fortification: Int
    var maxFortification: Int
    var besiegingDivisionIds: [String]

    init(
        targetRegionId: RegionId,
        attackerFaction: Faction,
        defenderFaction: Faction,
        startedTurn: Int,
        lastUpdatedTurn: Int,
        pressure: Int,
        fortification: Int? = nil,
        maxFortification: Int = Self.defaultMaxFortification,
        besiegingDivisionIds: [String]
    ) {
        let normalizedMaxFortification = Self.normalizedMaxFortification(maxFortification)
        self.targetRegionId = targetRegionId
        self.attackerFaction = attackerFaction
        self.defenderFaction = defenderFaction
        self.startedTurn = max(1, startedTurn)
        self.lastUpdatedTurn = max(1, lastUpdatedTurn)
        self.pressure = Self.clampPressure(pressure)
        self.maxFortification = normalizedMaxFortification
        self.fortification = Self.clampFortification(
            fortification ?? normalizedMaxFortification,
            max: normalizedMaxFortification
        )
        self.besiegingDivisionIds = Self.normalizedDivisionIds(besiegingDivisionIds)
    }

    private enum CodingKeys: String, CodingKey {
        case targetRegionId
        case attackerFaction
        case defenderFaction
        case startedTurn
        case lastUpdatedTurn
        case pressure
        case fortification
        case maxFortification
        case besiegingDivisionIds
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedPressure = try container.decodeIfPresent(Int.self, forKey: .pressure) ?? 0
        let decodedMaxFortification = Self.normalizedMaxFortification(
            try container.decodeIfPresent(Int.self, forKey: .maxFortification) ?? Self.defaultMaxFortification
        )
        let decodedFortification = try container.decodeIfPresent(Int.self, forKey: .fortification) ??
            max(0, decodedMaxFortification - min(decodedMaxFortification, decodedPressure / 10))

        self.init(
            targetRegionId: try container.decode(RegionId.self, forKey: .targetRegionId),
            attackerFaction: try container.decode(Faction.self, forKey: .attackerFaction),
            defenderFaction: try container.decode(Faction.self, forKey: .defenderFaction),
            startedTurn: try container.decodeIfPresent(Int.self, forKey: .startedTurn) ?? 1,
            lastUpdatedTurn: try container.decodeIfPresent(Int.self, forKey: .lastUpdatedTurn) ?? 1,
            pressure: decodedPressure,
            fortification: decodedFortification,
            maxFortification: decodedMaxFortification,
            besiegingDivisionIds: try container.decodeIfPresent([String].self, forKey: .besiegingDivisionIds) ?? []
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(targetRegionId, forKey: .targetRegionId)
        try container.encode(attackerFaction, forKey: .attackerFaction)
        try container.encode(defenderFaction, forKey: .defenderFaction)
        try container.encode(startedTurn, forKey: .startedTurn)
        try container.encode(lastUpdatedTurn, forKey: .lastUpdatedTurn)
        try container.encode(pressure, forKey: .pressure)
        try container.encode(fortification, forKey: .fortification)
        try container.encode(maxFortification, forKey: .maxFortification)
        try container.encode(besiegingDivisionIds, forKey: .besiegingDivisionIds)
    }

    static let defaultMaxFortification = 10

    static func clampPressure(_ value: Int) -> Int {
        max(0, min(100, value))
    }

    static func normalizedMaxFortification(_ value: Int) -> Int {
        max(1, min(30, value))
    }

    static func clampFortification(_ value: Int, max maxFortification: Int) -> Int {
        max(0, min(normalizedMaxFortification(maxFortification), value))
    }

    static func normalizedDivisionIds(_ ids: [String]) -> [String] {
        Array(Set(ids)).sorted()
    }
}

struct SiegeState: Codable, Equatable {
    var records: [SiegeRecord]

    init(records: [SiegeRecord] = []) {
        self.records = records.sorted { $0.targetRegionId.rawValue < $1.targetRegionId.rawValue }
    }

    static let empty = SiegeState()

    func record(for regionId: RegionId) -> SiegeRecord? {
        records.first { $0.targetRegionId == regionId }
    }

    @discardableResult
    mutating func startOrUpdate(
        targetRegionId: RegionId,
        attackerFaction: Faction,
        defenderFaction: Faction,
        turn: Int,
        pressureGain: Int,
        fortificationDamage: Int = 0,
        maxFortification: Int = SiegeRecord.defaultMaxFortification,
        besiegingDivisionId: String
    ) -> SiegeRecord {
        let normalizedTurn = max(1, turn)
        let normalizedMaxFortification = SiegeRecord.normalizedMaxFortification(maxFortification)
        let normalizedFortificationDamage = max(0, fortificationDamage)
        if let index = records.firstIndex(where: { $0.targetRegionId == targetRegionId }) {
            var record = records[index]
            if record.attackerFaction != attackerFaction || record.defenderFaction != defenderFaction {
                record = SiegeRecord(
                    targetRegionId: targetRegionId,
                    attackerFaction: attackerFaction,
                    defenderFaction: defenderFaction,
                    startedTurn: normalizedTurn,
                    lastUpdatedTurn: normalizedTurn,
                    pressure: pressureGain,
                    fortification: normalizedMaxFortification - normalizedFortificationDamage,
                    maxFortification: normalizedMaxFortification,
                    besiegingDivisionIds: [besiegingDivisionId]
                )
            } else {
                record.lastUpdatedTurn = normalizedTurn
                record.pressure = SiegeRecord.clampPressure(record.pressure + pressureGain)
                if normalizedMaxFortification > record.maxFortification {
                    let extraFortification = normalizedMaxFortification - record.maxFortification
                    record.maxFortification = normalizedMaxFortification
                    record.fortification = SiegeRecord.clampFortification(
                        record.fortification + extraFortification,
                        max: normalizedMaxFortification
                    )
                }
                record.fortification = SiegeRecord.clampFortification(
                    record.fortification - normalizedFortificationDamage,
                    max: record.maxFortification
                )
                record.besiegingDivisionIds = SiegeRecord.normalizedDivisionIds(
                    record.besiegingDivisionIds + [besiegingDivisionId]
                )
            }
            records[index] = record
            records.sort { $0.targetRegionId.rawValue < $1.targetRegionId.rawValue }
            return record
        }

        let record = SiegeRecord(
            targetRegionId: targetRegionId,
            attackerFaction: attackerFaction,
            defenderFaction: defenderFaction,
            startedTurn: normalizedTurn,
            lastUpdatedTurn: normalizedTurn,
            pressure: pressureGain,
            fortification: normalizedMaxFortification - normalizedFortificationDamage,
            maxFortification: normalizedMaxFortification,
            besiegingDivisionIds: [besiegingDivisionId]
        )
        records.append(record)
        records.sort { $0.targetRegionId.rawValue < $1.targetRegionId.rawValue }
        return record
    }

    @discardableResult
    mutating func repairFortification(
        targetRegionId: RegionId,
        defenderFaction: Faction,
        turn: Int,
        repairGain: Int
    ) -> SiegeRecord? {
        guard let index = records.firstIndex(where: { $0.targetRegionId == targetRegionId }) else {
            return nil
        }

        var record = records[index]
        guard record.defenderFaction == defenderFaction else {
            return nil
        }

        record.lastUpdatedTurn = max(1, turn)
        record.fortification = SiegeRecord.clampFortification(
            record.fortification + max(0, repairGain),
            max: record.maxFortification
        )
        records[index] = record
        records.sort { $0.targetRegionId.rawValue < $1.targetRegionId.rawValue }
        return record
    }

    mutating func removeRecord(for regionId: RegionId) {
        records.removeAll { $0.targetRegionId == regionId }
    }
}

struct GameState: Codable, Equatable {
    var scenarioId: String
    var turn: Int
    var maxTurns: Int
    var activeFaction: Faction
    var phase: GamePhase
    var turnOrderState: TurnOrderState
    var map: MapState
    var theaterState: TheaterState
    var frontLineState: FrontLineState
    var warDeploymentState: WarDeploymentState
    var economyState: EconomyState
    var diplomacyState: DiplomacyState
    var siegeState: SiegeState
    var divisions: [Division]
    var victoryState: VictoryState
    var selectedUnitSummary: String?
    var eventLog: [GameLogEntry]
    var warDirectiveRecords: [WarDirectiveRecord]
    var playerCommandState: PlayerCommandState

    init(
        scenarioId: String,
        turn: Int,
        maxTurns: Int,
        activeFaction: Faction,
        phase: GamePhase,
        turnOrderState: TurnOrderState? = nil,
        map: MapState,
        theaterState: TheaterState = .empty,
        frontLineState: FrontLineState = .empty,
        warDeploymentState: WarDeploymentState = .empty,
        economyState: EconomyState = .empty,
        diplomacyState: DiplomacyState = .empty,
        siegeState: SiegeState = .empty,
        divisions: [Division],
        victoryState: VictoryState,
        selectedUnitSummary: String?,
        eventLog: [GameLogEntry],
        warDirectiveRecords: [WarDirectiveRecord] = [],
        playerCommandState: PlayerCommandState = .empty
    ) {
        self.scenarioId = scenarioId
        self.turn = turn
        self.maxTurns = maxTurns
        self.activeFaction = activeFaction
        self.phase = phase
        self.turnOrderState = turnOrderState ?? TurnOrderState.legacy(
            activeFaction: activeFaction,
            phase: phase,
            round: turn
        )
        self.map = map
        self.theaterState = theaterState
        self.frontLineState = frontLineState
        self.warDeploymentState = warDeploymentState
        self.economyState = economyState
        self.diplomacyState = diplomacyState
        self.siegeState = siegeState
        self.divisions = divisions
        self.victoryState = victoryState
        self.selectedUnitSummary = selectedUnitSummary
        self.eventLog = eventLog
        self.warDirectiveRecords = warDirectiveRecords
        self.playerCommandState = playerCommandState
    }

    static func initial() -> GameState {
        let map = MapState.ardennesV0()

        return GameState(
            scenarioId: "ardennes_v0",
            turn: 1,
            maxTurns: 8,
            activeFaction: .germany,
            phase: .germanAI,
            map: map,
            theaterState: .empty,
            frontLineState: .empty,
            warDeploymentState: .empty,
            economyState: .empty,
            diplomacyState: DiplomacyState.initial(for: Faction.allCases, turn: 1),
            divisions: [
                .panzer(
                    id: "ger_panzer_1",
                    name: "1st Panzer Division",
                    faction: .germany,
                    coord: HexCoord(q: 9, r: 3)
                ),
                .motorized(
                    id: "ger_motorized_1",
                    name: "2nd Motorized Division",
                    faction: .germany,
                    coord: HexCoord(q: 9, r: 4)
                ),
                .infantry(
                    id: "ger_infantry_1",
                    name: "26th Infantry Division",
                    faction: .germany,
                    coord: HexCoord(q: 10, r: 5)
                ),
                .artillery(
                    id: "ger_artillery_1",
                    name: "7th Artillery Division",
                    faction: .germany,
                    coord: HexCoord(q: 10, r: 3)
                ),
                .infantry(
                    id: "all_infantry_1",
                    name: "101st Infantry Division",
                    faction: .allies,
                    coord: HexCoord(q: 4, r: 5)
                ),
                .infantry(
                    id: "all_anti_tank_1",
                    name: "9th Anti-Tank Battalion",
                    faction: .allies,
                    coord: HexCoord(q: 5, r: 5)
                ),
                .artillery(
                    id: "all_artillery_1",
                    name: "4th Allied Artillery Group",
                    faction: .allies,
                    coord: HexCoord(q: 3, r: 5)
                ),
                .infantry(
                    id: "all_garrison_1",
                    name: "Bastogne Garrison",
                    faction: .allies,
                    coord: HexCoord(q: 5, r: 6)
                )
            ],
            victoryState: .ongoing,
            selectedUnitSummary: nil,
            eventLog: [
                GameLogEntry(
                    turn: 1,
                    faction: .germany,
                    phase: .germanAI,
                    message: "Ardennes V0 scenario initialized."
                )
            ]
        )
    }

    private enum CodingKeys: String, CodingKey {
        case scenarioId
        case turn
        case maxTurns
        case activeFaction
        case phase
        case turnOrderState
        case map
        case theaterState
        case frontLineState
        case warDeploymentState
        case economyState
        case diplomacyState
        case siegeState
        case divisions
        case victoryState
        case selectedUnitSummary
        case eventLog
        case warDirectiveRecords
        case playerCommandState
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            scenarioId: try container.decode(String.self, forKey: .scenarioId),
            turn: try container.decode(Int.self, forKey: .turn),
            maxTurns: try container.decode(Int.self, forKey: .maxTurns),
            activeFaction: try container.decode(Faction.self, forKey: .activeFaction),
            phase: try container.decode(GamePhase.self, forKey: .phase),
            turnOrderState: try container.decodeIfPresent(TurnOrderState.self, forKey: .turnOrderState),
            map: try container.decode(MapState.self, forKey: .map),
            theaterState: try container.decodeIfPresent(TheaterState.self, forKey: .theaterState) ?? .empty,
            frontLineState: try container.decodeIfPresent(FrontLineState.self, forKey: .frontLineState) ?? .empty,
            warDeploymentState: try container.decodeIfPresent(WarDeploymentState.self, forKey: .warDeploymentState) ?? .empty,
            economyState: try container.decodeIfPresent(EconomyState.self, forKey: .economyState) ?? .empty,
            diplomacyState: try container.decodeIfPresent(DiplomacyState.self, forKey: .diplomacyState) ?? .empty,
            siegeState: try container.decodeIfPresent(SiegeState.self, forKey: .siegeState) ?? .empty,
            divisions: try container.decode([Division].self, forKey: .divisions),
            victoryState: try container.decode(VictoryState.self, forKey: .victoryState),
            selectedUnitSummary: try container.decodeIfPresent(String.self, forKey: .selectedUnitSummary),
            eventLog: try container.decode([GameLogEntry].self, forKey: .eventLog),
            warDirectiveRecords: try container.decodeIfPresent([WarDirectiveRecord].self, forKey: .warDirectiveRecords) ?? [],
            playerCommandState: try container.decodeIfPresent(PlayerCommandState.self, forKey: .playerCommandState) ?? .empty
        )
    }

    var effectiveTurnOrderState: TurnOrderState {
        turnOrderState.normalized(activeFaction: activeFaction, phase: phase, round: turn)
    }

    var isTangSongScenario: Bool {
        scenarioId == "jianlong_960_unification"
    }

    var scenarioDisplayName: String {
        switch scenarioId {
        case "jianlong_960_unification":
            return "建隆元年：陈桥兵变与山河一统"
        case "ardennes_v0":
            return "Ardennes V0"
        default:
            return scenarioId
        }
    }

    var phaseDisplayName: String {
        guard phase != .resolution else {
            return phase.displayName
        }

        guard let profile = effectiveTurnOrderState.profile(for: activeFaction.powerId) else {
            return phase.displayName
        }

        switch profile.controlMode {
        case .human:
            return "Player Command"
        case .ai:
            return "AI Command"
        case .inactive:
            return "Inactive"
        }
    }

    func displayName(for faction: Faction) -> String {
        effectiveTurnOrderState.profile(for: faction.powerId)?.displayName ?? faction.displayName
    }

    func division(id: String) -> Division? {
        divisions.first { $0.id == id }
    }

    func divisionIndex(id: String) -> Int? {
        divisions.firstIndex { $0.id == id }
    }

    func division(at coord: HexCoord) -> Division? {
        divisions.first { $0.coord == coord }
    }

    mutating func updateDivision(_ division: Division) {
        guard let index = divisionIndex(id: division.id) else {
            return
        }
        divisions[index] = division
    }

    mutating func removeDivision(id: String) {
        divisions.removeAll { $0.id == id }
    }

    mutating func appendEvent(
        _ message: String,
        category: GameLogCategory = .event,
        relatedRecordId: String? = nil
    ) {
        eventLog.append(
            GameLogEntry(
                turn: turn,
                faction: activeFaction,
                phase: phase,
                category: category,
                relatedRecordId: relatedRecordId,
                message: message
            )
        )
    }
}
