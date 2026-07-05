import Foundation

struct CommandValidator {
    private let movementRules = MovementRules()
    private let warRelationRules = WarRelationRules()

    func validate(_ command: Command, in state: GameState) -> CommandValidation {
        switch command {
        case .move(let divisionId, let destination):
            return validateMove(divisionId: divisionId, destination: destination, in: state)
        case .attack(let attackerId, let targetId):
            return validateAttack(attackerId: attackerId, targetId: targetId, in: state)
        case .besiege(let attackerId, let targetRegionId):
            return validateBesiege(attackerId: attackerId, targetRegionId: targetRegionId, in: state)
        case .repairFortification(let defenderId, let targetRegionId):
            return validateRepairFortification(defenderId: defenderId, targetRegionId: targetRegionId, in: state)
        case .relieveSiege(let relieverId, let targetRegionId):
            return validateRelieveSiege(relieverId: relieverId, targetRegionId: targetRegionId, in: state)
        case .hold(let divisionId):
            return validateUnitCommand(divisionId: divisionId, in: state)
        case .allowRetreat(let divisionId):
            return validateUnitCommand(divisionId: divisionId, in: state)
        case .resupply(let divisionId):
            return validateRecoveryCommand(divisionId: divisionId, in: state)
        case .queueProduction(let kind):
            return validateProduction(kind: kind, in: state)
        case .endTurn:
            return validateEndTurn(in: state)
        }
    }

    private func validateMove(divisionId: String, destination: HexCoord, in state: GameState) -> CommandValidation {
        let unitValidation = validateUnitCommand(divisionId: divisionId, in: state)
        guard unitValidation.isValid,
              let division = state.division(id: divisionId) else {
            return unitValidation
        }

        guard state.map.contains(destination) else {
            return .invalid(.destinationOutOfBounds)
        }

        guard state.map.tile(at: destination)?.isPassable == true else {
            return .invalid(.noPath)
        }

        if state.division(at: destination) != nil {
            return .invalid(.destinationOccupied)
        }

        if let path = movementRules.shortestPathIgnoringMovement(for: division, to: destination, in: state),
           path.cost > division.movement {
            return .invalid(.insufficientMovement)
        }

        guard movementRules.shortestPath(for: division, to: destination, in: state) != nil else {
            return .invalid(.noPath)
        }

        return .valid
    }

    private func validateRelieveSiege(
        relieverId: String,
        targetRegionId: RegionId,
        in state: GameState
    ) -> CommandValidation {
        let unitValidation = validateUnitCommand(divisionId: relieverId, in: state)
        guard unitValidation.isValid,
              let reliever = state.division(id: relieverId) else {
            return unitValidation
        }

        guard let region = state.map.region(id: targetRegionId) else {
            return .invalid(.regionNotFound)
        }

        guard let record = state.siegeState.record(for: targetRegionId),
              record.defenderFaction == reliever.faction else {
            return .invalid(.noActiveSiege)
        }

        guard region.controller == reliever.faction else {
            return .invalid(.invalidTargetFaction)
        }

        guard canRelieve(reliever, targetRegion: region, in: state) else {
            return .invalid(.targetOutOfRange)
        }

        return .valid
    }

    private func validateAttack(attackerId: String, targetId: String, in state: GameState) -> CommandValidation {
        let unitValidation = validateUnitCommand(divisionId: attackerId, in: state)
        guard unitValidation.isValid,
              let attacker = state.division(id: attackerId) else {
            return unitValidation
        }

        guard let target = state.division(id: targetId) else {
            return .invalid(.targetNotFound)
        }

        guard warRelationRules.canTarget(attacker: attacker.faction, target: target.faction, in: state) else {
            return .invalid(.invalidTargetFaction)
        }

        guard attacker.coord.distance(to: target.coord) <= attacker.range else {
            return .invalid(.targetOutOfRange)
        }

        return .valid
    }

    private func validateBesiege(attackerId: String, targetRegionId: RegionId, in state: GameState) -> CommandValidation {
        let unitValidation = validateUnitCommand(divisionId: attackerId, in: state)
        guard unitValidation.isValid,
              let attacker = state.division(id: attackerId) else {
            return unitValidation
        }

        guard let region = state.map.region(id: targetRegionId) else {
            return .invalid(.regionNotFound)
        }

        guard region.isPassable,
              isSiegeTarget(region, in: state) else {
            return .invalid(.invalidSiegeTarget)
        }

        guard warRelationRules.canTarget(attacker: attacker.faction, target: region.controller, in: state) else {
            return .invalid(.invalidTargetFaction)
        }

        guard canInvest(attacker, targetRegion: region) else {
            return .invalid(.targetOutOfRange)
        }

        return .valid
    }

    private func validateRepairFortification(
        defenderId: String,
        targetRegionId: RegionId,
        in state: GameState
    ) -> CommandValidation {
        let unitValidation = validateUnitCommand(divisionId: defenderId, in: state)
        guard unitValidation.isValid,
              let defender = state.division(id: defenderId) else {
            return unitValidation
        }

        guard let region = state.map.region(id: targetRegionId) else {
            return .invalid(.regionNotFound)
        }

        guard region.isPassable,
              isSiegeTarget(region, in: state) else {
            return .invalid(.invalidSiegeTarget)
        }

        guard region.controller == defender.faction else {
            return .invalid(.invalidTargetFaction)
        }

        guard defender.location(in: state.map) == targetRegionId else {
            return .invalid(.invalidRegionForHex)
        }

        guard let record = state.siegeState.record(for: targetRegionId),
              record.defenderFaction == defender.faction else {
            return .invalid(.noActiveSiege)
        }

        guard record.fortification < record.maxFortification else {
            return .invalid(.fortificationAlreadyFull)
        }

        return .valid
    }

    private func validateUnitCommand(divisionId: String, in state: GameState) -> CommandValidation {
        guard phaseAllowsCommands(in: state) else {
            return .invalid(.wrongPhase)
        }

        guard let division = state.division(id: divisionId) else {
            return .invalid(.divisionNotFound)
        }

        guard division.faction == state.activeFaction else {
            return .invalid(.wrongFaction)
        }

        guard !division.hasActed, !division.isRetreating else {
            return .invalid(.alreadyActed)
        }

        guard division.canAct else {
            return .invalid(.alreadyActed)
        }

        return .valid
    }

    private func validateRecoveryCommand(divisionId: String, in state: GameState) -> CommandValidation {
        guard phaseAllowsCommands(in: state) else {
            return .invalid(.wrongPhase)
        }

        guard let division = state.division(id: divisionId) else {
            return .invalid(.divisionNotFound)
        }

        guard division.faction == state.activeFaction else {
            return .invalid(.wrongFaction)
        }

        guard !division.hasActed, !division.isDestroyed, !division.isRetreating else {
            return .invalid(.alreadyActed)
        }

        return .valid
    }

    private func validateEndTurn(in state: GameState) -> CommandValidation {
        phaseAllowsCommands(in: state) ? .valid : .invalid(.wrongPhase)
    }

    private func validateProduction(kind: ProductionKind, in state: GameState) -> CommandValidation {
        guard phaseAllowsCommands(in: state) else {
            return .invalid(.wrongPhase)
        }

        guard EconomyRules().canQueueProduction(kind: kind, faction: state.activeFaction, in: state) else {
            return .invalid(.insufficientResources)
        }

        return .valid
    }

    private func phaseAllowsCommands(in state: GameState) -> Bool {
        state.effectiveTurnOrderState.allowsCommands(
            activeFaction: state.activeFaction,
            phase: state.phase
        )
    }

    private func isSiegeTarget(_ region: RegionNode, in state: GameState) -> Bool {
        if region.city != nil || region.terrain == .fortress || region.supplyValue >= 4 {
            return true
        }

        return region.displayHexes.contains { coord in
            guard let tile = state.map.tile(at: coord) else {
                return false
            }
            return tile.baseTerrain == .city ||
                tile.baseTerrain == .fortress ||
                tile.cityName != nil ||
                tile.fortressName != nil
        }
    }

    private func canInvest(_ attacker: Division, targetRegion region: RegionNode) -> Bool {
        let maxDistance = max(1, attacker.range)
        return region.displayHexes.contains { targetHex in
            attacker.coord.distance(to: targetHex) <= maxDistance
        }
    }

    private func canRelieve(_ reliever: Division, targetRegion region: RegionNode, in state: GameState) -> Bool {
        if reliever.location(in: state.map) == region.id {
            return true
        }

        let maxDistance = max(1, reliever.range)
        return region.displayHexes.contains { targetHex in
            reliever.coord.distance(to: targetHex) <= maxDistance
        }
    }
}
