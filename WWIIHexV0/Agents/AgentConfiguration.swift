import Foundation

extension GameAgent {
    static func defaultCommander(for faction: Faction, from loader: DataLoader, state: GameState) -> GameAgent {
        if state.isTangSongScenario {
            return tangSongMarshal(for: faction, state: state)
        }

        switch faction {
        case .germany:
            return guderian(from: loader, state: state)
        case .allies:
            return alliedMockCommander(state: state)
        }
    }

    static func guderian(from loader: DataLoader, state: GameState) -> GameAgent {
        if let definition = try? loader.loadGeneralAgents().first(where: { $0.id == "guderian" }),
           let agent = GameAgent(definition: definition) {
            return agent
        }

        return guderianFallback(
            assignedDivisionIds: state.divisions
                .filter { $0.faction == .germany }
                .map(\.id)
                .sorted()
        )
    }

    init?(definition: GeneralAgentDefinition) {
        guard let faction = Faction(rawValue: definition.faction),
              let role = AgentRole(rawValue: definition.role) else {
            return nil
        }

        self.init(
            id: definition.id,
            name: definition.name,
            faction: faction,
            role: role,
            personality: AgentPersonality(
                prompt: definition.personalityPrompt,
                traits: [definition.commandStyle],
                aggression: definition.commandStyle == "breakthrough" ? 80 : 50,
                riskTolerance: definition.commandStyle == "breakthrough" ? 75 : 50,
                autonomy: 70
            ),
            relationship: AgentRelationship(loyalty: 70, trust: 70, satisfaction: 70),
            assignedDivisionIds: definition.assignedDivisionIds
        )
    }

    static func tangSongMarshal(for faction: Faction, state: GameState) -> GameAgent {
        switch faction {
        case .germany:
            return GameAgent(
                id: "marshal_separatist_command",
                name: "割据行营",
                faction: .germany,
                role: .fieldMarshal,
                personality: AgentPersonality(
                    prompt: "依托州府城关、粮道与外援压力，牵制宋军并择机反击。",
                    traits: ["守城", "牵制"],
                    aggression: 60,
                    riskTolerance: 55,
                    autonomy: 70
                ),
                relationship: AgentRelationship(loyalty: 60, trust: 60, satisfaction: 65),
                assignedDivisionIds: assignedDivisionIds(for: faction, in: state)
            )
        case .allies:
            return GameAgent(
                id: "marshal_song_privy_council",
                name: "宋枢密院",
                faction: .allies,
                role: .fieldMarshal,
                personality: AgentPersonality(
                    prompt: "以统一州府、护持粮道和集中优势方面进军为先。",
                    traits: ["统一", "持重"],
                    aggression: 65,
                    riskTolerance: 50,
                    autonomy: 70
                ),
                relationship: AgentRelationship(loyalty: 75, trust: 75, satisfaction: 70),
                assignedDivisionIds: assignedDivisionIds(for: faction, in: state)
            )
        }
    }

    static func alliedMockCommander(state: GameState) -> GameAgent {
        GameAgent.sample(
            id: "allied_mock_commander",
            name: "Allied Mock Commander",
            faction: .allies,
            role: .armyCommander,
            assignedDivisionIds: assignedDivisionIds(for: .allies, in: state)
        )
    }

    static func guderianFallback(assignedDivisionIds: [String]) -> GameAgent {
        GameAgent(
            id: "guderian",
            name: "Heinz Guderian",
            faction: .germany,
            role: .armyCommander,
            personality: AgentPersonality(
                prompt: "Prioritize armored breakthrough, road movement, concentration of force, and rapid encirclement.",
                traits: ["breakthrough"],
                aggression: 80,
                riskTolerance: 75,
                autonomy: 70
            ),
            relationship: AgentRelationship(loyalty: 70, trust: 70, satisfaction: 70),
            assignedDivisionIds: assignedDivisionIds.isEmpty
                ? ["ger_panzer_1", "ger_motorized_1", "ger_infantry_1", "ger_artillery_1"]
                : assignedDivisionIds
        )
    }

    private static func assignedDivisionIds(for faction: Faction, in state: GameState) -> [String] {
        state.divisions
            .filter { $0.faction == faction && !$0.isDestroyed }
            .map(\.id)
            .sorted()
    }
}
