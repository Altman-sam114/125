import Foundation

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

    private func updateTangSongVictoryState(in state: inout GameState) {
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
}
