import Foundation

struct VictoryObjectiveProgress: Equatable, Identifiable {
    let id: String
    let description: String
    let type: String
    let status: String
    let faction: Faction
    let objectiveNames: [String]
    let controlledCount: Int
    let requiredCount: Int
    let mandateScore: Int?
    let mandateThreshold: Int?
    let turnRequirement: Int?
    let currentTurn: Int

    var isSatisfied: Bool {
        objectiveRequirementMet && mandateRequirementMet && turnRequirementMet
    }

    var objectiveRequirementMet: Bool {
        controlledCount >= requiredCount
    }

    var mandateRequirementMet: Bool {
        guard let mandateScore, let mandateThreshold else {
            return true
        }
        return mandateScore >= mandateThreshold
    }

    var turnRequirementMet: Bool {
        guard let turnRequirement else {
            return true
        }
        return currentTurn >= turnRequirement
    }

    func title(isTangSongScenario: Bool, factionDisplayName: (Faction) -> String) -> String {
        let factionName = factionDisplayName(faction)
        if isTangSongScenario {
            switch status {
            case "majorVictory":
                return "\(factionName)统一"
            case "survival":
                return "\(factionName)守成"
            default:
                return factionName
            }
        }

        switch status {
        case "majorVictory":
            return "\(factionName) Major Victory"
        case "survival":
            return "\(factionName) Survival"
        default:
            return factionName
        }
    }

    func summary(isTangSongScenario: Bool) -> String {
        let objectiveLabel = isTangSongScenario
            ? "州府 \(controlledCount)／\(requiredCount)"
            : "Objectives \(controlledCount)/\(requiredCount)"
        var parts = [objectiveLabel]

        if let mandateScore, let mandateThreshold {
            parts.append(
                isTangSongScenario
                    ? "天命 \(mandateScore)／\(mandateThreshold)"
                    : "Mandate \(mandateScore)/\(mandateThreshold)"
            )
        }

        if let turnRequirement {
            if isTangSongScenario {
                parts.append(currentTurn >= turnRequirement ? "回合达标" : "需至 \(turnRequirement) 回合")
            } else {
                parts.append(currentTurn >= turnRequirement ? "Turn met" : "Need turn \(turnRequirement)")
            }
        }

        return parts.joined(separator: isTangSongScenario ? "；" : "; ")
    }

    func detail(isTangSongScenario: Bool) -> String {
        let objectiveList = objectiveNames.prefix(4).joined(separator: isTangSongScenario ? "、" : ", ")
        if objectiveList.isEmpty {
            return description
        }

        if objectiveNames.count > 4 {
            let suffix = isTangSongScenario ? "等" : "..."
            return "\(objectiveList)\(suffix)"
        }
        return objectiveList
    }
}

struct VictoryRules {
    func updateVictoryState(in state: inout GameState) {
        guard state.victoryState.winner == nil else {
            return
        }

        if state.isTangSongScenario {
            updateTangSongVictoryState(in: &state)
            return
        }

        let bastogneController = state.map.controllerOfObjective(named: "Bastogne")
        let stVithController = state.map.controllerOfObjective(named: "St. Vith")

        if bastogneController == .germany {
            if let heldSince = state.victoryState.germanBastogneHeldSinceTurn,
               state.turn > heldSince {
                state.victoryState.winner = .germany
                state.victoryState.reason = .bastogneHeldByGermany
                return
            } else if state.victoryState.germanBastogneHeldSinceTurn == nil {
                state.victoryState.germanBastogneHeldSinceTurn = state.turn
            }
        } else {
            state.victoryState.germanBastogneHeldSinceTurn = nil
        }

        if bastogneController == .germany && stVithController == .germany {
            state.victoryState.winner = .germany
            state.victoryState.reason = .bastogneAndStVithControlledByGermany
            return
        }

        if state.victoryState.eliminatedAlliedDivisions >= 3 {
            state.victoryState.winner = .germany
            state.victoryState.reason = .alliedUnitsDestroyed
            return
        }

        if state.victoryState.eliminatedGermanDivisions >= 3 {
            state.victoryState.winner = .allies
            state.victoryState.reason = .germanUnitsDestroyed
            return
        }

        let germanArmor = state.divisions.filter { $0.faction == .germany && $0.isArmor }
        if !germanArmor.isEmpty && germanArmor.allSatisfy({ $0.supplyState != .supplied }) {
            if let since = state.victoryState.germanArmorUnsuppliedSinceTurn,
               state.turn > since {
                state.victoryState.winner = .allies
                state.victoryState.reason = .germanArmorUnsupplied
                return
            } else if state.victoryState.germanArmorUnsuppliedSinceTurn == nil {
                state.victoryState.germanArmorUnsuppliedSinceTurn = state.turn
            }
        } else {
            state.victoryState.germanArmorUnsuppliedSinceTurn = nil
        }

        if state.turn >= state.maxTurns && bastogneController == .allies {
            state.victoryState.winner = .allies
            state.victoryState.reason = .bastogneHeldByAlliesAtFinalTurn
        }
    }

    func objectiveProgress(in state: GameState) -> [VictoryObjectiveProgress] {
        guard state.isTangSongScenario else {
            return []
        }

        if state.victoryConditions.isEmpty {
            return fallbackTangSongObjectiveProgress(in: state)
        }

        return state.victoryConditions.compactMap { condition in
            guard let faction = Faction(rawValue: condition.faction),
                  condition.type == "controlObjectives" || condition.type == "holdObjectives" else {
                return nil
            }

            let objectiveIds = objectiveIds(for: condition)
            guard !objectiveIds.isEmpty else {
                return nil
            }

            let requiredCount = condition.count ?? objectiveIds.count
            let controlledCount = controlledObjectiveCount(
                ids: objectiveIds,
                by: faction,
                in: state
            )
            let objectiveNames = objectiveIds.map { objectiveId in
                state.map.objective(id: objectiveId)?.name ?? objectiveId
            }
            let turnRequirement = condition.turn ?? condition.turns
            let mandateScore = condition.mandateThreshold.map { _ in
                state.mandateState.legitimacy(for: faction)
            }

            return VictoryObjectiveProgress(
                id: condition.id,
                description: condition.description,
                type: condition.type,
                status: condition.status,
                faction: faction,
                objectiveNames: objectiveNames,
                controlledCount: controlledCount,
                requiredCount: requiredCount,
                mandateScore: mandateScore,
                mandateThreshold: condition.mandateThreshold,
                turnRequirement: turnRequirement,
                currentTurn: state.turn
            )
        }
    }

    private func updateTangSongVictoryState(in state: inout GameState) {
        if applyTangSongScenarioVictoryConditions(in: &state) {
            return
        }

        let songMandate = state.mandateState.legitimacy(for: .allies)
        let unificationObjectiveNames = ["开封", "洛阳", "太原", "金陵", "成都", "杭州"]
        let controlledUnificationObjectives = controlledObjectiveCount(
            named: unificationObjectiveNames,
            by: .allies,
            in: state
        )

        if controlledUnificationObjectives >= 4 && songMandate >= 60 {
            state.victoryState.winner = .allies
            state.victoryState.reason = .tangSongUnificationByMandate
            return
        }

        let separatistMandate = state.mandateState.legitimacy(for: .germany)
        let separatistCoreObjectiveNames = ["太原", "金陵", "成都"]
        let controlledSeparatistCores = controlledObjectiveCount(
            named: separatistCoreObjectiveNames,
            by: .germany,
            in: state
        )

        if state.turn >= state.maxTurns &&
            controlledSeparatistCores >= 2 &&
            separatistMandate >= 35 {
            state.victoryState.winner = .germany
            state.victoryState.reason = .tangSongSeparatistSurvival
        }
    }

    private func applyTangSongScenarioVictoryConditions(in state: inout GameState) -> Bool {
        guard !state.victoryConditions.isEmpty else {
            return false
        }

        for condition in state.victoryConditions {
            guard let faction = Faction(rawValue: condition.faction),
                  let reason = tangSongVictoryReason(for: condition),
                  tangSongConditionIsSatisfied(condition, faction: faction, in: state) else {
                continue
            }

            state.victoryState.winner = faction
            state.victoryState.reason = reason
            return true
        }

        return false
    }

    private func tangSongConditionIsSatisfied(
        _ condition: VictoryConditionDefinition,
        faction: Faction,
        in state: GameState
    ) -> Bool {
        if let turn = condition.turn,
           state.turn < turn {
            return false
        }

        if let turns = condition.turns,
           state.turn < turns {
            return false
        }

        if let mandateThreshold = condition.mandateThreshold,
           state.mandateState.legitimacy(for: faction) < mandateThreshold {
            return false
        }

        switch condition.type {
        case "controlObjectives", "holdObjectives":
            let objectiveIds = objectiveIds(for: condition)
            guard !objectiveIds.isEmpty else {
                return false
            }

            let requiredCount = condition.count ?? objectiveIds.count
            return controlledObjectiveCount(
                ids: objectiveIds,
                by: faction,
                in: state
            ) >= requiredCount
        default:
            return false
        }
    }

    private func tangSongVictoryReason(for condition: VictoryConditionDefinition) -> VictoryReason? {
        switch condition.status {
        case "majorVictory":
            return .tangSongUnificationByMandate
        case "survival":
            return .tangSongSeparatistSurvival
        default:
            return nil
        }
    }

    private func objectiveIds(for condition: VictoryConditionDefinition) -> [String] {
        if let objectiveIds = condition.objectiveIds,
           !objectiveIds.isEmpty {
            return objectiveIds
        }

        if let objectiveId = condition.objectiveId {
            return [objectiveId]
        }

        return []
    }

    private func controlledObjectiveCount(
        named objectiveNames: [String],
        by faction: Faction,
        in state: GameState
    ) -> Int {
        var count = 0
        for objectiveName in objectiveNames where state.map.controllerOfObjective(named: objectiveName) == faction {
            count += 1
        }
        return count
    }

    private func controlledObjectiveCount(
        ids objectiveIds: [String],
        by faction: Faction,
        in state: GameState
    ) -> Int {
        var count = 0
        for objectiveId in objectiveIds where state.map.controllerOfObjective(id: objectiveId) == faction {
            count += 1
        }
        return count
    }

    private func fallbackTangSongObjectiveProgress(in state: GameState) -> [VictoryObjectiveProgress] {
        let unificationObjectiveNames = ["开封", "洛阳", "太原", "金陵", "成都", "杭州"]
        let separatistCoreObjectiveNames = ["太原", "金陵", "成都"]

        return [
            VictoryObjectiveProgress(
                id: "fallback_song_unification",
                description: "宋控制多数关键州府且天命达标。",
                type: "controlObjectives",
                status: "majorVictory",
                faction: .allies,
                objectiveNames: unificationObjectiveNames,
                controlledCount: controlledObjectiveCount(named: unificationObjectiveNames, by: .allies, in: state),
                requiredCount: 4,
                mandateScore: state.mandateState.legitimacy(for: .allies),
                mandateThreshold: 60,
                turnRequirement: nil,
                currentTurn: state.turn
            ),
            VictoryObjectiveProgress(
                id: "fallback_separatist_survival",
                description: "割据阵营守住核心州府至终局且天命达标。",
                type: "holdObjectives",
                status: "survival",
                faction: .germany,
                objectiveNames: separatistCoreObjectiveNames,
                controlledCount: controlledObjectiveCount(named: separatistCoreObjectiveNames, by: .germany, in: state),
                requiredCount: 2,
                mandateScore: state.mandateState.legitimacy(for: .germany),
                mandateThreshold: 35,
                turnRequirement: state.maxTurns,
                currentTurn: state.turn
            )
        ]
    }
}
