import Foundation

struct CommandExecutor {
    private let movementRules = MovementRules()
    private let combatRules = CombatRules()
    private let supplyRules = SupplyRules()
    private let occupationRules = OccupationRules()
    private let strategicSynchronizer = StrategicStateSynchronizer()
    private let warRelationRules = WarRelationRules()
    private let retreatLossThreshold = 0.35
    private let siegeSupplyPressureThreshold = 10

    func execute(_ command: Command, in state: GameState) -> GameState {
        var nextState = state

        switch command {
        case .move(let divisionId, let destination):
            executeMove(divisionId: divisionId, destination: destination, in: &nextState)
        case .attack(let attackerId, let targetId):
            executeAttack(attackerId: attackerId, targetId: targetId, in: &nextState)
        case .besiege(let attackerId, let targetRegionId):
            executeBesiege(attackerId: attackerId, targetRegionId: targetRegionId, in: &nextState)
        case .repairFortification(let defenderId, let targetRegionId):
            executeRepairFortification(defenderId: defenderId, targetRegionId: targetRegionId, in: &nextState)
        case .relieveSiege(let relieverId, let targetRegionId):
            executeRelieveSiege(relieverId: relieverId, targetRegionId: targetRegionId, in: &nextState)
        case .demandSurrender(let negotiatorId, let targetRegionId):
            executeDemandSurrender(negotiatorId: negotiatorId, targetRegionId: targetRegionId, in: &nextState)
        case .hold(let divisionId):
            executeHold(divisionId: divisionId, in: &nextState)
        case .allowRetreat(let divisionId):
            executeAllowRetreat(divisionId: divisionId, in: &nextState)
        case .resupply(let divisionId):
            executeResupply(divisionId: divisionId, in: &nextState)
        case .queueProduction(let kind):
            executeQueueProduction(kind: kind, in: &nextState)
        case .endTurn:
            executeEndTurn(in: &nextState)
        }

        return nextState
    }

    private func executeMove(divisionId: String, destination: HexCoord, in state: inout GameState) {
        guard let index = state.divisionIndex(id: divisionId) else {
            return
        }

        let origin = state.divisions[index].coord
        let sourceZoneId = state.warDeploymentState.zoneId(for: origin, map: state.map)
        if let direction = directionForMove(from: origin, to: destination, division: state.divisions[index], in: state) {
            state.divisions[index].facing = direction
        }
        state.divisions[index].coord = destination
        state.divisions[index].hasActed = true

        if occupationRules.canOccupy(division: state.divisions[index], destination: destination, in: state),
           var tile = state.map.tile(at: destination) {
            tile.controller = state.divisions[index].faction
            state.map.setTile(tile)
            if let destinationRegionId = state.map.region(for: destination),
               let sourceZoneId {
                applyStrategicAdvance(
                    regionId: destinationRegionId,
                    hex: destination,
                    sourceZoneId: sourceZoneId,
                    faction: state.divisions[index].faction,
                    state: &state
                )
            }
            _ = strategicSynchronizer.synchronizeAfterOccupationChange(
                in: &state,
                affectedRegionIds: state.map.region(for: destination).map { [$0] } ?? []
            )
        }

        state.appendEvent("\(state.divisions[index].name) moved to \(destination.q),\(destination.r).")
    }

    private func executeAttack(attackerId: String, targetId: String, in state: inout GameState) {
        guard let attackerIndex = state.divisionIndex(id: attackerId),
              let targetIndex = state.divisionIndex(id: targetId) else {
            return
        }

        let attacker = state.divisions[attackerIndex]
        let defender = state.divisions[targetIndex]
        let damage = combatRules.attackDamage(attacker: attacker, defender: defender, in: state)
        let attackerFacing = attacker.coord.direction(to: defender.coord) ?? attacker.facing

        state.divisions[attackerIndex].hasActed = true
        state.divisions[attackerIndex].facing = attackerFacing
        applyCombatDamage(damage, to: targetId, in: &state)

        let attackOutcome = resolveCombatResult(for: defender, damage: damage, in: &state)
        state.appendEvent(
            combatLog(
                prefix: "\(attacker.name) attacked \(defender.name)",
                subjectName: defender.name,
                damage: damage,
                outcome: attackOutcome
            )
        )

        if attackOutcome.wasDestroyed {
            return
        }

        if attackOutcome.shouldRetreat {
            supplyRules.resolveRetreat(for: targetId, in: &state)
        }

        guard let updatedDefender = state.division(id: targetId),
              let updatedAttacker = state.division(id: attackerId) else {
            return
        }

        if !attackOutcome.shouldRetreat,
           combatRules.canCounterAttack(defender: updatedDefender, attacker: updatedAttacker) {
            let counterDamage = combatRules.counterAttackDamage(defender: updatedDefender, attacker: updatedAttacker, in: state)
            applyCombatDamage(counterDamage, to: attackerId, in: &state)

            let counterOutcome = resolveCombatResult(for: updatedAttacker, damage: counterDamage, in: &state)
            state.appendEvent(
                combatLog(
                    prefix: "\(updatedDefender.name) counterattacked \(updatedAttacker.name)",
                    subjectName: updatedAttacker.name,
                    damage: counterDamage,
                    outcome: counterOutcome
                )
            )

            if counterOutcome.shouldRetreat && !counterOutcome.wasDestroyed {
                supplyRules.resolveRetreat(for: attackerId, in: &state)
            }
        }
    }

    private func executeBesiege(attackerId: String, targetRegionId: RegionId, in state: inout GameState) {
        guard let attackerIndex = state.divisionIndex(id: attackerId),
              let region = state.map.region(id: targetRegionId) else {
            return
        }

        let attacker = state.divisions[attackerIndex]
        let pressureGain = siegePressure(for: attacker, targetRegion: region, in: state)
        let fortificationDamage = siegeFortificationDamage(
            pressureGain: pressureGain,
            attacker: attacker,
            targetRegion: region,
            in: state
        )
        let record = state.siegeState.startOrUpdate(
            targetRegionId: targetRegionId,
            attackerFaction: attacker.faction,
            defenderFaction: region.controller,
            turn: state.turn,
            pressureGain: pressureGain,
            fortificationDamage: fortificationDamage,
            maxFortification: maxFortification(for: region, in: state),
            besiegingDivisionId: attacker.id
        )

        if let targetHex = closestHex(in: region, to: attacker.coord),
           let direction = attacker.coord.direction(to: targetHex) {
            state.divisions[attackerIndex].facing = direction
        }
        state.divisions[attackerIndex].hasActed = true

        let targetName = siegeTargetName(region)
        state.appendEvent(
            state.isTangSongScenario
                ? "\(attacker.name)围困\(targetName)：围城压力 +\(pressureGain)，城防 -\(fortificationDamage)，当前 \(record.fortification)/\(record.maxFortification)。"
                : "\(attacker.name) besieged \(targetName): pressure +\(pressureGain), fortification -\(fortificationDamage), now \(record.fortification)/\(record.maxFortification).",
            category: .siege
        )
    }

    private func executeRepairFortification(defenderId: String, targetRegionId: RegionId, in state: inout GameState) {
        guard let defenderIndex = state.divisionIndex(id: defenderId),
              let region = state.map.region(id: targetRegionId) else {
            return
        }

        let defender = state.divisions[defenderIndex]
        let repairGain = fortificationRepair(for: defender, targetRegion: region, in: state)
        guard let record = state.siegeState.repairFortification(
            targetRegionId: targetRegionId,
            defenderFaction: defender.faction,
            turn: state.turn,
            repairGain: repairGain
        ) else {
            return
        }

        state.divisions[defenderIndex].hasActed = true
        state.appendEvent(
            state.isTangSongScenario
                ? "\(defender.name)修筑\(siegeTargetName(region))城防：+\(repairGain)，当前 \(record.fortification)/\(record.maxFortification)。"
                : "\(defender.name) repaired \(siegeTargetName(region)) fortification: +\(repairGain), now \(record.fortification)/\(record.maxFortification).",
            category: .siege
        )
    }

    private func executeRelieveSiege(relieverId: String, targetRegionId: RegionId, in state: inout GameState) {
        guard let relieverIndex = state.divisionIndex(id: relieverId),
              let region = state.map.region(id: targetRegionId) else {
            return
        }

        let reliever = state.divisions[relieverIndex]
        let relief = siegeRelief(for: reliever, targetRegion: region, in: state)
        guard let record = state.siegeState.reducePressure(
            targetRegionId: targetRegionId,
            defenderFaction: reliever.faction,
            turn: state.turn,
            relief: relief
        ) else {
            return
        }

        if let targetHex = closestHex(in: region, to: reliever.coord),
           let direction = reliever.coord.direction(to: targetHex) {
            state.divisions[relieverIndex].facing = direction
        }
        state.divisions[relieverIndex].hasActed = true

        if record.pressure == 0 {
            state.appendEvent(
                state.isTangSongScenario
                    ? "\(reliever.name)驰援\(siegeTargetName(region))：解围力度 \(relief)，围城解除。"
                    : "\(reliever.name) relieved \(siegeTargetName(region)): relief \(relief), siege lifted.",
                category: .siege
            )
        } else {
            state.appendEvent(
                state.isTangSongScenario
                    ? "\(reliever.name)驰援\(siegeTargetName(region))：围城压力 -\(relief)，当前 \(record.pressure)。"
                    : "\(reliever.name) relieved \(siegeTargetName(region)): pressure -\(relief), now \(record.pressure).",
                category: .siege
            )
        }
    }

    private func executeDemandSurrender(negotiatorId: String, targetRegionId: RegionId, in state: inout GameState) {
        guard let negotiator = state.division(id: negotiatorId),
              let region = state.map.region(id: targetRegionId),
              let record = state.siegeState.record(for: targetRegionId),
              record.attackerFaction == negotiator.faction,
              record.defenderFaction == region.controller,
              record.pressure >= siegeSupplyPressureThreshold,
              record.fortification == 0,
              defendersAreReadyToSurrender(record: record, in: region, state: state) else {
            return
        }

        let capturedHexes = surrenderCandidateHexes(
            in: region,
            defenderFaction: record.defenderFaction,
            map: state.map
        )
        guard !capturedHexes.isEmpty else {
            return
        }

        let sourceZoneId = state.warDeploymentState.zoneId(for: negotiator.coord, map: state.map)
        let surrenderedDefenders = state.divisions
            .filter {
                $0.faction == record.defenderFaction &&
                    $0.location(in: state.map) == region.id &&
                    !$0.isDestroyed
            }
            .sorted { $0.id < $1.id }

        for defender in surrenderedDefenders {
            eliminateDivision(defender, in: &state)
        }

        for hex in capturedHexes {
            guard var tile = state.map.tile(at: hex) else { continue }
            tile.controller = negotiator.faction
            state.map.setTile(tile)
            if let sourceZoneId {
                applyStrategicAdvance(
                    regionId: targetRegionId,
                    hex: hex,
                    sourceZoneId: sourceZoneId,
                    faction: negotiator.faction,
                    state: &state
                )
            }
        }

        if let negotiatorIndex = state.divisionIndex(id: negotiatorId) {
            if let targetHex = closestHex(in: region, to: state.divisions[negotiatorIndex].coord),
               let direction = state.divisions[negotiatorIndex].coord.direction(to: targetHex) {
                state.divisions[negotiatorIndex].facing = direction
            }
            state.divisions[negotiatorIndex].hasActed = true
        }

        state.siegeState.removeRecord(for: targetRegionId)
        _ = strategicSynchronizer.synchronizeAfterOccupationChange(
            in: &state,
            affectedRegionIds: [targetRegionId],
            turn: state.turn
        )

        state.appendEvent(
            state.isTangSongScenario
                ? "\(negotiator.name)招降\(siegeTargetName(region))：守军纳降 \(surrenderedDefenders.count) 支，交割 \(capturedHexes.count) 个地块。"
                : "\(negotiator.name) demanded surrender of \(siegeTargetName(region)): \(surrenderedDefenders.count) defender(s) capitulated, \(capturedHexes.count) hex(es) transferred.",
            category: .siege
        )
    }

    private func executeHold(divisionId: String, in state: inout GameState) {
        guard let index = state.divisionIndex(id: divisionId) else {
            return
        }

        state.divisions[index].retreatMode = .hold
        state.divisions[index].hasActed = true
        state.appendEvent(
            state.isTangSongScenario
                ? "\(state.divisions[index].name)转为固守：不主动退却，防御提升，损失略增。"
                : "\(state.divisions[index].name) set stance to HOLD: no retreat, +20% defense, +20% losses."
        )
    }

    private func executeAllowRetreat(divisionId: String, in state: inout GameState) {
        guard let index = state.divisionIndex(id: divisionId) else {
            return
        }

        state.divisions[index].retreatMode = .retreatable
        state.divisions[index].hasActed = true
        state.appendEvent(
            state.isTangSongScenario
                ? "\(state.divisions[index].name)改为准退：重创后可自动退却。"
                : "\(state.divisions[index].name) set stance to RETREATABLE: auto-retreat after severe losses."
        )
    }

    private func executeResupply(divisionId: String, in state: inout GameState) {
        guard let index = state.divisionIndex(id: divisionId) else {
            return
        }

        supplyRules.applyResupplyRest(to: divisionId, in: &state)
        state.divisions[index].hasActed = true
    }

    private func executeQueueProduction(kind: ProductionKind, in state: inout GameState) {
        _ = EconomyRules().queueProduction(kind: kind, faction: state.activeFaction, in: &state)
    }

    private func executeEndTurn(in state: inout GameState) {
        let supplyRules = SupplyRules()
        let victoryRules = VictoryRules()
        let economyRules = EconomyRules()

        supplyRules.updateSupplyStates(in: &state)
        applySiegeSupplyPressure(in: &state)
        economyRules.resolveFactionTurn(for: state.activeFaction, in: &state)
        supplyRules.advanceRetreats(in: &state)
        supplyRules.applyEncirclementAttrition(in: &state)
        victoryRules.updateVictoryState(in: &state)

        let nextTurnOrderState = state.effectiveTurnOrderState.advancedAfterEndTurn(
            fallbackActiveFaction: state.activeFaction
        )
        state.turnOrderState = nextTurnOrderState
        state.activeFaction = nextTurnOrderState.activeLegacyFaction(fallback: state.activeFaction)
        state.phase = nextTurnOrderState.phase
        state.turn = nextTurnOrderState.round

        resetActionsForActiveFaction(in: &state)
        state = StrategicStateBootstrapper().refreshRuntimeState(state)
        state.appendEvent(
            state.isTangSongScenario
                ? "回合推进至 \(state.turn)，\(state.displayName(for: state.activeFaction))行动。"
                : "Turn advanced to \(state.turn), \(state.activeFaction.displayName) active."
        )
    }

    private func resetActionsForActiveFaction(in state: inout GameState) {
        for index in state.divisions.indices where state.divisions[index].faction == state.activeFaction {
            state.divisions[index].hasActed = false
        }
    }

    private func directionForMove(
        from origin: HexCoord,
        to destination: HexCoord,
        division: Division,
        in state: GameState
    ) -> HexDirection? {
        if let path = movementRules.shortestPath(for: division, to: destination, in: state),
           path.coords.count >= 2 {
            let previous = path.coords[path.coords.count - 2]
            return previous.direction(to: destination)
        }

        return origin.direction(to: destination)
    }

    private func applyCombatDamage(_ damage: CombatDamage, to divisionId: String, in state: inout GameState) {
        guard let index = state.divisionIndex(id: divisionId) else {
            return
        }

        state.divisions[index].receiveStrengthDamage(damage.strengthDamage)
    }

    private func resolveCombatResult(
        for originalDivision: Division,
        damage: CombatDamage,
        in state: inout GameState
    ) -> CombatResultSummary {
        guard let index = state.divisionIndex(id: originalDivision.id) else {
            return CombatResultSummary(shouldRetreat: false, wasDestroyed: true, extraStrengthDamage: 0)
        }

        let shouldRetreat = state.divisions[index].retreatMode == .retreatable &&
            !state.divisions[index].isDestroyed &&
            damage.lossRatio >= retreatLossThreshold
        var extraStrengthDamage = 0

        if state.divisions[index].retreatMode == .hold && !state.divisions[index].isDestroyed {
            extraStrengthDamage += max(1, Int((Double(damage.strengthDamage) * 0.2).rounded()))
            state.divisions[index].receiveStrengthDamage(extraStrengthDamage)
        }

        if shouldRetreat && state.divisions[index].supplyState == .encircled && !state.divisions[index].isDestroyed {
            extraStrengthDamage = max(1, damage.strengthDamage / 2)
            state.divisions[index].receiveStrengthDamage(extraStrengthDamage)
        }

        if state.divisions[index].isDestroyed {
            eliminateDivision(originalDivision, in: &state)
            return CombatResultSummary(
                shouldRetreat: shouldRetreat,
                wasDestroyed: true,
                extraStrengthDamage: extraStrengthDamage
            )
        }

        if shouldRetreat {
            state.divisions[index].hasActed = true
        }

        return CombatResultSummary(
            shouldRetreat: shouldRetreat,
            wasDestroyed: false,
            extraStrengthDamage: extraStrengthDamage
        )
    }

    private func eliminateDivision(_ division: Division, in state: inout GameState) {
        state.victoryState.recordEliminatedDivision(faction: division.faction)
        state.removeDivision(id: division.id)
    }

    private func applyStrategicAdvance(
        regionId: RegionId,
        hex: HexCoord,
        sourceZoneId: FrontZoneId,
        faction: Faction,
        state: inout GameState
    ) {
        let advancingTheaterId = TheaterId(sourceZoneId.rawValue)
        guard state.theaterState.theaters[advancingTheaterId] != nil,
              state.theaterState.dynamicTheaterId(for: hex, map: state.map) != advancingTheaterId else {
            return
        }
        guard shouldAdvanceDynamicTheater(
            hex: hex,
            sourceZoneId: sourceZoneId,
            faction: faction,
            state: state
        ) else {
            return
        }

        state.theaterState = TheaterSystem().expandDynamicTheater(
            state: state.theaterState,
            map: state.map,
            divisions: state.divisions,
            breakthroughHex: hex,
            advancingTheaterId: advancingTheaterId,
            faction: faction
        ).state

        let oldZoneId = state.warDeploymentState.zoneId(for: hex, map: state.map)
        if oldZoneId != sourceZoneId {
            state.warDeploymentState = WarDeploymentManager().advanceHex(
                hex,
                from: oldZoneId,
                to: sourceZoneId,
                state: state.warDeploymentState,
                map: state.map,
                divisions: state.divisions,
                turn: state.turn
            )
        }

        state.appendEvent(
            "Hex \(hex.q),\(hex.r) reassigned to dynamic theater \(advancingTheaterId.rawValue).",
            category: .theaterChange,
            relatedRecordId: nil
        )
    }

    private func shouldAdvanceDynamicTheater(
        hex: HexCoord,
        sourceZoneId: FrontZoneId,
        faction: Faction,
        state: GameState
    ) -> Bool {
        let destinationZoneId = state.warDeploymentState.zoneId(for: hex, map: state.map)
        if let destinationZoneId,
           destinationZoneId != sourceZoneId,
           let destinationFaction = state.warDeploymentState.frontZones[destinationZoneId]?.faction {
            return destinationFaction != faction
        }

        if let destinationTheaterId = state.theaterState.dynamicTheaterId(for: hex, map: state.map),
           destinationTheaterId != TheaterId(sourceZoneId.rawValue),
           let destinationFaction = state.theaterState.theaters[destinationTheaterId]?.controllingFaction {
            return destinationFaction != faction
        }

        if let controller = state.map.tile(at: hex)?.controller {
            return controller != faction
        }

        return false
    }

    private func applySiegeSupplyPressure(in state: inout GameState) {
        guard !state.siegeState.records.isEmpty else {
            return
        }

        var retainedRecords: [SiegeRecord] = []
        for record in state.siegeState.records.sorted(by: { $0.targetRegionId.rawValue < $1.targetRegionId.rawValue }) {
            guard let region = state.map.region(id: record.targetRegionId),
                  region.controller == record.defenderFaction else {
                state.appendEvent(
                    state.isTangSongScenario
                        ? "围城解除：\(record.targetRegionId.rawValue) 已不由原守方控制。"
                        : "Siege lifted: \(record.targetRegionId.rawValue) is no longer controlled by the original defender.",
                    category: .siege
                )
                continue
            }

            let maintainers = record.besiegingDivisionIds
                .compactMap { state.division(id: $0) }
                .filter { canMaintainSiege($0, record: record, region: region, in: state) }
                .sorted { $0.id < $1.id }

            guard !maintainers.isEmpty else {
                state.appendEvent(
                    state.isTangSongScenario
                        ? "围城解除：\(siegeTargetName(region)) 外无有效围困军队。"
                        : "Siege lifted: no effective besieging unit remains around \(siegeTargetName(region)).",
                    category: .siege
                )
                continue
            }

            var updatedRecord = record
            updatedRecord.lastUpdatedTurn = state.turn
            updatedRecord.besiegingDivisionIds = maintainers.map(\.id)

            if updatedRecord.pressure >= siegeSupplyPressureThreshold {
                if updatedRecord.fortification > 0 {
                    state.appendEvent(
                        state.isTangSongScenario
                            ? "\(siegeTargetName(region))城防尚存 \(updatedRecord.fortification)/\(updatedRecord.maxFortification)，围城断粮压力暂未突破。"
                            : "\(siegeTargetName(region)) fortification remains \(updatedRecord.fortification)/\(updatedRecord.maxFortification); siege supply pressure has not broken through.",
                        category: .siege
                    )
                } else {
                    let affectedCount = applySiegeLowSupply(record: updatedRecord, in: &state)
                    if affectedCount > 0 {
                        state.appendEvent(
                            state.isTangSongScenario
                                ? "\(siegeTargetName(region))城防已破、被围断粮：\(affectedCount) 支守军降为缺粮。"
                                : "\(siegeTargetName(region)) fortification is broken: \(affectedCount) defender(s) degraded to low supply.",
                            category: .siege
                        )
                    }
                }
            }

            retainedRecords.append(updatedRecord)
        }

        state.siegeState = SiegeState(records: retainedRecords)
    }

    private func applySiegeLowSupply(record: SiegeRecord, in state: inout GameState) -> Int {
        var affectedCount = 0
        for index in state.divisions.indices {
            let division = state.divisions[index]
            guard division.faction == record.defenderFaction,
                  division.location(in: state.map) == record.targetRegionId,
                  division.supplyState == .supplied else {
                continue
            }

            state.divisions[index].supplyState = .lowSupply
            affectedCount += 1
        }
        return affectedCount
    }

    private func canMaintainSiege(
        _ division: Division,
        record: SiegeRecord,
        region: RegionNode,
        in state: GameState
    ) -> Bool {
        guard division.faction == record.attackerFaction,
              !division.isDestroyed,
              warRelationRules.canTarget(attacker: division.faction, target: record.defenderFaction, in: state) else {
            return false
        }

        let maximumDistance = max(1, division.range)
        return region.displayHexes.contains { division.coord.distance(to: $0) <= maximumDistance }
    }

    private func siegePressure(for attacker: Division, targetRegion region: RegionNode, in state: GameState) -> Int {
        var pressure = max(2, attacker.attack / 2)
        let roles = attacker.tangSongCombatRoles

        if state.isTangSongScenario {
            if roles.contains(.siegeEngine) {
                pressure += 4
            }
            if roles.contains(.imperialGuard) {
                pressure += 1
            }
            if attacker.supplyState == .lowSupply {
                pressure -= 1
            } else if attacker.supplyState == .encircled {
                pressure -= 2
            }
            if region.terrain == .fortress {
                pressure = max(2, pressure - 1)
            }
        }

        return max(1, pressure)
    }

    private func siegeFortificationDamage(
        pressureGain: Int,
        attacker: Division,
        targetRegion region: RegionNode,
        in state: GameState
    ) -> Int {
        var damage = max(1, pressureGain / 3)
        let roles = attacker.tangSongCombatRoles

        if state.isTangSongScenario {
            if roles.contains(.siegeEngine) {
                damage += 2
            }
            if roles.contains(.cavalry) && !roles.contains(.siegeEngine) {
                damage -= 1
            }
            if region.terrain == .fortress {
                damage = max(1, damage - 1)
            }
        }

        return max(1, damage)
    }

    private func fortificationRepair(for defender: Division, targetRegion region: RegionNode, in state: GameState) -> Int {
        var repair = max(2, defender.defense / 2)
        let roles = defender.tangSongCombatRoles

        if state.isTangSongScenario {
            if roles.contains(.garrison) {
                repair += 2
            }
            if roles.contains(.crossbowGarrison) {
                repair += 1
            }
            if roles.contains(.imperialGuard) {
                repair += 1
            }
            if defender.supplyState == .lowSupply {
                repair -= 1
            } else if defender.supplyState == .encircled {
                repair -= 2
            }
            if region.terrain == .fortress {
                repair += 1
            }
        }

        return max(1, repair)
    }

    private func siegeRelief(for reliever: Division, targetRegion region: RegionNode, in state: GameState) -> Int {
        var relief = max(2, (reliever.attack + reliever.defense) / 3)
        let roles = reliever.tangSongCombatRoles

        if state.isTangSongScenario {
            if roles.contains(.cavalry) {
                relief += 2
            }
            if roles.contains(.imperialGuard) {
                relief += 1
            }
            if reliever.location(in: state.map) == region.id {
                relief += 1
            }
            if reliever.supplyState == .lowSupply {
                relief -= 1
            } else if reliever.supplyState == .encircled {
                relief -= 2
            }
        }

        return max(1, relief)
    }

    private func defendersAreReadyToSurrender(
        record: SiegeRecord,
        in region: RegionNode,
        state: GameState
    ) -> Bool {
        let defenders = state.divisions.filter {
            $0.faction == record.defenderFaction &&
                $0.location(in: state.map) == region.id &&
                !$0.isDestroyed
        }

        return defenders.allSatisfy { $0.supplyState != .supplied }
    }

    private func surrenderCandidateHexes(
        in region: RegionNode,
        defenderFaction: Faction,
        map: MapState
    ) -> [HexCoord] {
        let candidates = region.displayHexes.isEmpty ? [region.representativeHex] : region.displayHexes
        return candidates.filter { coord in
            guard let tile = map.tile(at: coord),
                  tile.isCapturable else {
                return false
            }
            return tile.controller == defenderFaction || tile.controller == nil
        }
    }

    private func maxFortification(for region: RegionNode, in state: GameState) -> Int {
        var value = 8

        if let city = region.city {
            value += city.isCapital ? 4 : 2
            value += min(3, city.victoryPoints / 2)
        }

        if region.terrain == .fortress {
            value += 4
        }

        if state.isTangSongScenario {
            if region.supplyValue >= 4 {
                value += 2
            }
            if region.infrastructure >= 3 {
                value += 1
            }
        }

        return SiegeRecord.normalizedMaxFortification(value)
    }

    private func closestHex(in region: RegionNode, to origin: HexCoord) -> HexCoord? {
        region.displayHexes.min {
            let lhsDistance = origin.distance(to: $0)
            let rhsDistance = origin.distance(to: $1)
            if lhsDistance != rhsDistance {
                return lhsDistance < rhsDistance
            }
            if $0.q != $1.q {
                return $0.q < $1.q
            }
            return $0.r < $1.r
        }
    }

    private func siegeTargetName(_ region: RegionNode) -> String {
        region.city?.name ?? region.name
    }

    private func combatLog(
        prefix: String,
        subjectName: String,
        damage: CombatDamage,
        outcome: CombatResultSummary
    ) -> String {
        var parts = [
            "\(prefix): strength -\(damage.strengthDamage)"
        ]

        if outcome.shouldRetreat {
            parts.append("\(subjectName) triggered automatic retreat")
        }

        if outcome.extraStrengthDamage > 0 {
            parts.append("extra strength -\(outcome.extraStrengthDamage)")
        }

        if outcome.wasDestroyed {
            parts.append("\(subjectName) was destroyed")
        }

        return parts.joined(separator: "; ") + "."
    }
}

private struct CombatResultSummary: Equatable {
    let shouldRetreat: Bool
    let wasDestroyed: Bool
    let extraStrengthDamage: Int
}
