import Foundation

enum Faction: String, Codable, Equatable, CaseIterable {
    case germany
    case allies

    var opponent: Faction {
        switch self {
        case .germany:
            return .allies
        case .allies:
            return .germany
        }
    }

    var displayName: String {
        switch self {
        case .germany:
            return "Germany"
        case .allies:
            return "Allies"
        }
    }
}

struct PowerId: Hashable, Codable, Equatable, RawRepresentable, ExpressibleByStringLiteral {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    init(stringLiteral value: StringLiteralType) {
        self.rawValue = value
    }

    init(_ value: String) {
        self.rawValue = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        rawValue = try container.decode(String.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

enum PowerControlMode: String, Codable, Equatable, CaseIterable {
    case human
    case ai
    case inactive
}

struct PowerProfile: Identifiable, Codable, Equatable {
    let id: PowerId
    var displayName: String
    var shortName: String
    var controlMode: PowerControlMode
    var legacyFactionBridge: Faction?

    init(
        id: PowerId,
        displayName: String,
        shortName: String,
        controlMode: PowerControlMode,
        legacyFactionBridge: Faction? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.shortName = shortName
        self.controlMode = controlMode
        self.legacyFactionBridge = legacyFactionBridge
    }
}

enum PowerRelationStatus: String, Codable, Equatable, CaseIterable {
    case allied
    case tributary
    case neutral
    case hostile
    case atWar
    case submitting
    case negotiating

    var isHostile: Bool {
        self == .hostile || self == .atWar
    }
}

struct PowerRelation: Identifiable, Codable, Equatable {
    let firstPowerId: PowerId
    let secondPowerId: PowerId
    var status: PowerRelationStatus
    var sinceTurn: Int

    var id: String {
        "\(firstPowerId.rawValue):\(secondPowerId.rawValue)"
    }

    init(firstPowerId: PowerId, secondPowerId: PowerId, status: PowerRelationStatus, sinceTurn: Int = 1) {
        if firstPowerId.rawValue <= secondPowerId.rawValue {
            self.firstPowerId = firstPowerId
            self.secondPowerId = secondPowerId
        } else {
            self.firstPowerId = secondPowerId
            self.secondPowerId = firstPowerId
        }
        self.status = status
        self.sinceTurn = max(1, sinceTurn)
    }
}

struct TurnOrderState: Codable, Equatable {
    var powerOrder: [PowerId]
    var activePowerId: PowerId
    var round: Int
    var phase: GamePhase
    var profiles: [PowerProfile]
    var playerControlledPowerIds: [PowerId]
    var relations: [PowerRelation]

    init(
        powerOrder: [PowerId],
        activePowerId: PowerId,
        round: Int,
        phase: GamePhase,
        profiles: [PowerProfile],
        playerControlledPowerIds: [PowerId],
        relations: [PowerRelation] = []
    ) {
        self.powerOrder = powerOrder
        self.activePowerId = activePowerId
        self.round = max(1, round)
        self.phase = phase
        self.profiles = profiles.sorted { $0.id.rawValue < $1.id.rawValue }
        self.playerControlledPowerIds = playerControlledPowerIds.sorted { $0.rawValue < $1.rawValue }
        self.relations = relations.sorted { $0.id < $1.id }
    }

    static func legacy(
        activeFaction: Faction,
        phase: GamePhase,
        round: Int,
        playerFaction: Faction = .allies,
        aiFaction: Faction = .germany
    ) -> TurnOrderState {
        let profiles = Faction.allCases.map { faction in
            PowerProfile(
                id: faction.powerId,
                displayName: faction.displayName,
                shortName: faction.displayName,
                controlMode: faction == aiFaction ? .ai : (faction == playerFaction ? .human : .inactive),
                legacyFactionBridge: faction
            )
        }

        return TurnOrderState(
            powerOrder: Faction.allCases.map(\.powerId),
            activePowerId: activeFaction.powerId,
            round: round,
            phase: phase,
            profiles: profiles,
            playerControlledPowerIds: [playerFaction.powerId],
            relations: [
                PowerRelation(
                    firstPowerId: Faction.germany.powerId,
                    secondPowerId: Faction.allies.powerId,
                    status: .atWar,
                    sinceTurn: round
                )
            ]
        )
    }

    func profile(for powerId: PowerId) -> PowerProfile? {
        profiles.first { $0.id == powerId }
    }

    func legacyFaction(for powerId: PowerId) -> Faction? {
        profile(for: powerId)?.legacyFactionBridge ?? Faction(powerId: powerId)
    }

    func activeLegacyFaction(fallback: Faction) -> Faction {
        legacyFaction(for: activePowerId) ?? fallback
    }

    func allowsCommands(activeFaction: Faction, phase currentPhase: GamePhase) -> Bool {
        guard currentPhase != .resolution,
              phase == currentPhase else {
            return false
        }
        return legacyFaction(for: activePowerId) == activeFaction
    }

    func shouldRunAI(activeFaction: Faction, phase currentPhase: GamePhase, observerModeEnabled: Bool) -> Bool {
        guard allowsCommands(activeFaction: activeFaction, phase: currentPhase),
              let profile = profile(for: activePowerId) else {
            return false
        }

        if profile.controlMode == .ai {
            return true
        }

        return observerModeEnabled && playerControlledPowerIds.contains(profile.id)
    }

    func normalized(activeFaction: Faction, phase currentPhase: GamePhase, round currentRound: Int) -> TurnOrderState {
        guard allowsCommands(activeFaction: activeFaction, phase: currentPhase) else {
            var normalized = self
            normalized.activePowerId = activeFaction.powerId
            normalized.phase = currentPhase
            normalized.round = max(1, currentRound)
            if normalized.profile(for: activeFaction.powerId) == nil {
                normalized.profiles.append(
                    PowerProfile(
                        id: activeFaction.powerId,
                        displayName: activeFaction.displayName,
                        shortName: activeFaction.displayName,
                        controlMode: .inactive,
                        legacyFactionBridge: activeFaction
                    )
                )
            }
            if !normalized.powerOrder.contains(activeFaction.powerId) {
                normalized.powerOrder.append(activeFaction.powerId)
            }
            return normalized
        }

        var normalized = self
        normalized.round = max(1, currentRound)
        return normalized
    }

    func advancedAfterEndTurn(fallbackActiveFaction: Faction) -> TurnOrderState {
        let activeIndex = powerOrder.firstIndex(of: activePowerId) ?? 0
        guard !powerOrder.isEmpty else {
            return Self.legacy(
                activeFaction: fallbackActiveFaction,
                phase: phase,
                round: round
            )
        }

        let nextIndex = (activeIndex + 1) % powerOrder.count
        let nextPowerId = powerOrder[nextIndex]
        let nextRound = nextIndex == 0 ? round + 1 : round
        var next = self
        next.activePowerId = nextPowerId
        next.round = nextRound
        next.phase = phaseForPower(nextPowerId)
        return next
    }

    private func phaseForPower(_ powerId: PowerId) -> GamePhase {
        guard let profile = profile(for: powerId) else {
            return .alliedPlayer
        }
        return profile.controlMode == .ai ? .germanAI : .alliedPlayer
    }
}

struct WarRelationRules {
    func relationStatus(between lhs: PowerId, and rhs: PowerId, in relations: [PowerRelation]) -> PowerRelationStatus? {
        let relationId = PowerRelation(firstPowerId: lhs, secondPowerId: rhs, status: .neutral).id
        return relations.first { $0.id == relationId }?.status
    }

    func canTarget(attacker: Faction, target: Faction, in state: GameState) -> Bool {
        guard attacker != target else {
            return false
        }

        let turnOrder = state.effectiveTurnOrderState
        guard let status = relationStatus(
            between: attacker.powerId,
            and: target.powerId,
            in: turnOrder.relations
        ) else {
            return true
        }
        return status.isHostile
    }
}

extension Faction {
    var powerId: PowerId {
        PowerId(rawValue)
    }

    init?(powerId: PowerId) {
        self.init(rawValue: powerId.rawValue)
    }
}
