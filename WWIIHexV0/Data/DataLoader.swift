import Foundation

struct DataLoader {
    private enum ScenarioResource {
        static let tangSongJianlong = "jianlong_960_unification"
        static let tangSongScenario = "tangsong_jianlong_960_scenario"
        static let tangSongRegions = "tangsong_jianlong_960_regions"
        static let tangSongUnitTemplates = "tangsong_unit_templates"
        static let ardennesScenario = "ardennes_v0_scenario"
        static let ardennesRegions = "ardennes_v02_regions"
        static let legacyUnitTemplates = "unit_templates"
    }

    private let bundle: Bundle
    private let resourceDirectory: URL?
    private let decoder: JSONDecoder

    init(bundle: Bundle = .main, resourceDirectory: URL? = nil) {
        self.bundle = bundle
        self.resourceDirectory = resourceDirectory
        self.decoder = JSONDecoder()
    }

    init(resourceDirectory: URL) {
        self.init(bundle: .main, resourceDirectory: resourceDirectory)
    }

    func loadInitialGameState() -> GameState {
        if let state = try? loadGameState(
            scenarioName: ScenarioResource.tangSongScenario,
            regionName: ScenarioResource.tangSongRegions,
            unitTemplateName: ScenarioResource.tangSongUnitTemplates
        ) {
            return state
        }

        if let state = try? loadGameState(
            scenarioName: ScenarioResource.ardennesScenario,
            regionName: ScenarioResource.ardennesRegions
        ) {
            return state
        }

        var state = GameState.initial()

        // v0.2: 叠加省份数据。加载失败时 fallback 纯 hex（不破现有行为）。
        // 省份是战略层叠加，hex 仍是战术层权威；tiles/objectives/supplySources 不变。
        if let regionData = try? loadArdennesV02Regions() {
            state.map.regions = regionData.toRegions()
            state.map.hexToRegion = regionData.toHexToRegion()
            state.map.regionEdges = regionData.toRegionEdges()
            // 反向填 HexTile.regionId，让 tile.regionId == hexToRegion[tile.coord]
            for (coord, regionId) in state.map.hexToRegion {
                if var tile = state.map.tile(at: coord) {
                    tile.regionId = regionId
                    state.map.setTile(tile)
                }
            }
            state.map = RegionOccupationRules().mapByAggregatingControllers(in: state.map)
            state.theaterState = makeTheaterState(
                map: state.map,
                regionData: regionData,
                divisions: state.divisions,
                turn: state.turn
            )
            state.frontLineState = FrontLineManager().makeInitialState(
                map: state.map,
                theaterState: state.theaterState,
                divisions: state.divisions,
                turn: state.turn
            )
            let deploymentState = WarDeploymentManager().makeInitialState(
                map: state.map,
                theaterState: state.theaterState,
                divisions: state.divisions,
                turn: state.turn
            )
            state.warDeploymentState = assignGenerals(
                to: deploymentState,
                map: state.map,
                regionData: regionData
            )
        }

        return state
    }

    func loadArdennesDataSet() throws -> ScenarioDataSet {
        let dataSet = ScenarioDataSet(
            scenario: try loadScenarioDefinition(),
            terrainRules: try loadTerrainRules(),
            unitTemplates: try loadUnitTemplates(),
            generalAgents: try loadGeneralAgents()
        )
        try validate(dataSet)
        return dataSet
    }

    func loadScenarioDefinition() throws -> ScenarioDefinition {
        try loadJSON(ScenarioDefinition.self, named: "ardennes_v0_scenario")
    }

    func loadScenarioDefinition(named resourceName: String) throws -> ScenarioDefinition {
        try loadJSON(ScenarioDefinition.self, named: resourceName)
    }

    func loadRegionDataSet(named resourceName: String) throws -> RegionDataSet {
        try loadJSON(RegionDataSet.self, named: resourceName)
    }

    /// v0.34: 加载 MapEditor 直接导出的 ScenarioDefinition + RegionDataSet。
    /// 这是编辑器输出的主验收路径，不要求走旧 Ardennes 数据集的 agent/胜利条件强校验。
    func loadGameState(
        scenarioName: String,
        regionName: String,
        unitTemplateName: String = "unit_templates"
    ) throws -> GameState {
        let scenario = try loadScenarioDefinition(named: scenarioName)
        let regionData = try loadRegionDataSet(named: regionName)
        let unitTemplates = try loadUnitTemplates(named: unitTemplateName)
        try validateScenarioReferences(in: scenario)
        var map = try makeMapState(from: scenario)
        try apply(regionData, to: &map)
        map = RegionOccupationRules().mapByAggregatingControllers(in: map)
        let divisions = try makeDivisions(from: scenario.initialUnits, templates: unitTemplates)
        let turn = scenario.initialTurn

        let theaterState = makeTheaterState(
            map: map,
            regionData: regionData,
            divisions: divisions,
            turn: turn
        )
        let frontLineState = FrontLineManager().makeInitialState(
            map: map,
            theaterState: theaterState,
            divisions: divisions,
            turn: turn
        )
        let deploymentState = WarDeploymentManager().makeInitialState(
            map: map,
            theaterState: theaterState,
            divisions: divisions,
            turn: turn
        )
        let warDeploymentState = assignGenerals(
            to: deploymentState,
            map: map,
            regionData: regionData
        )
        let phase = GamePhase(rawValue: scenario.initialPhase) ?? .germanAI
        let activeFaction = initialActiveFaction(for: scenario)
        let playerFaction = Faction(rawValue: scenario.playerFaction) ?? .allies
        let aiFaction = Faction(rawValue: scenario.aiFaction) ?? .germany
        let turnOrderState = initialTurnOrderState(
            for: scenario,
            activeFaction: activeFaction,
            phase: phase,
            turn: turn,
            playerFaction: playerFaction,
            aiFaction: aiFaction
        )

        return GameState(
            scenarioId: scenario.id,
            turn: turn,
            maxTurns: scenario.maxTurns,
            activeFaction: activeFaction,
            phase: phase,
            turnOrderState: turnOrderState,
            map: map,
            theaterState: theaterState,
            frontLineState: frontLineState,
            warDeploymentState: warDeploymentState,
            diplomacyState: initialDiplomacyState(for: scenario, turn: turn),
            mandateState: initialMandateState(for: scenario, turn: turn),
            victoryConditions: scenario.victoryConditions,
            divisions: divisions,
            victoryState: .ongoing,
            selectedUnitSummary: nil,
            eventLog: [
                GameLogEntry(
                    turn: turn,
                    faction: activeFaction,
                    phase: phase,
                    message: "Loaded \(scenario.id) from MapEditor-compatible JSON."
                )
            ]
        )
    }

    private func initialActiveFaction(for scenario: ScenarioDefinition) -> Faction {
        let phase = GamePhase(rawValue: scenario.initialPhase) ?? .alliedPlayer
        switch phase {
        case .alliedPlayer:
            return Faction(rawValue: scenario.playerFaction) ?? .allies
        case .germanAI:
            return Faction(rawValue: scenario.aiFaction) ?? .germany
        case .resolution:
            return Faction(rawValue: scenario.playerFaction) ?? .allies
        }
    }

    private func initialTurnOrderState(
        for scenario: ScenarioDefinition,
        activeFaction: Faction,
        phase: GamePhase,
        turn: Int,
        playerFaction: Faction,
        aiFaction: Faction
    ) -> TurnOrderState {
        guard scenario.id == ScenarioResource.tangSongJianlong else {
            return TurnOrderState.legacy(
                activeFaction: activeFaction,
                phase: phase,
                round: turn,
                playerFaction: playerFaction,
                aiFaction: aiFaction
            )
        }

        return TurnOrderState(
            powerOrder: [Faction.allies.powerId, Faction.germany.powerId],
            activePowerId: activeFaction.powerId,
            round: turn,
            phase: phase,
            profiles: [
                PowerProfile(
                    id: Faction.allies.powerId,
                    displayName: "宋",
                    shortName: "宋",
                    controlMode: .human,
                    legacyFactionBridge: .allies
                ),
                PowerProfile(
                    id: Faction.germany.powerId,
                    displayName: "北方与割据诸政权",
                    shortName: "割据",
                    controlMode: .ai,
                    legacyFactionBridge: .germany
                )
            ],
            playerControlledPowerIds: [Faction.allies.powerId],
            relations: [
                PowerRelation(
                    firstPowerId: Faction.allies.powerId,
                    secondPowerId: Faction.germany.powerId,
                    status: .atWar,
                    sinceTurn: turn
                )
            ]
        )
    }

    private func initialDiplomacyState(for scenario: ScenarioDefinition, turn: Int) -> DiplomacyState {
        guard scenario.id == ScenarioResource.tangSongJianlong else {
            return DiplomacyState.initial(from: scenario.factions, turn: turn)
        }

        let countries: [CountryProfile] = [
            CountryProfile(
                id: "power_song",
                name: "宋",
                faction: .allies,
                blocId: "bloc_song_court",
                rulerAgentId: "zhao_kuangyin",
                isPrimaryBelligerent: true,
                capitalRegionId: "ts_q05_r02",
                warSupport: 82
            ),
            CountryProfile(
                id: "power_northern_han",
                name: "北汉",
                faction: .germany,
                blocId: "bloc_anti_song",
                rulerAgentId: "liu_jun",
                isPrimaryBelligerent: true,
                capitalRegionId: "ts_q08_r00",
                warSupport: 78
            ),
            CountryProfile(
                id: "power_liao_edge",
                name: "辽边境压力",
                faction: .germany,
                blocId: "bloc_anti_song",
                rulerAgentId: "liao_border_council",
                capitalRegionId: "ts_q13_r00",
                warSupport: 72
            ),
            CountryProfile(
                id: "power_southern_tang",
                name: "南唐",
                faction: .germany,
                blocId: "bloc_southern_realms",
                rulerAgentId: "li_yu",
                capitalRegionId: "ts_q10_r03",
                warSupport: 68
            ),
            CountryProfile(
                id: "power_wuyue",
                name: "吴越",
                faction: .germany,
                blocId: "bloc_southern_realms",
                rulerAgentId: "qian_chu",
                capitalRegionId: "ts_q12_r04",
                warSupport: 58
            ),
            CountryProfile(
                id: "power_later_shu",
                name: "后蜀",
                faction: .germany,
                blocId: "bloc_southern_realms",
                rulerAgentId: "meng_chang",
                capitalRegionId: "ts_q01_r04",
                warSupport: 64
            )
        ]

        let blocs: [DiplomaticBloc] = [
            DiplomaticBloc(id: "bloc_song_court", name: "宋朝廷", faction: .allies, memberCountryIds: ["power_song"]),
            DiplomaticBloc(
                id: "bloc_anti_song",
                name: "北方抗宋同盟",
                faction: .germany,
                memberCountryIds: ["power_liao_edge", "power_northern_han"]
            ),
            DiplomaticBloc(
                id: "bloc_southern_realms",
                name: "南方割据诸国",
                faction: .germany,
                memberCountryIds: ["power_later_shu", "power_southern_tang", "power_wuyue"]
            )
        ]

        return DiplomacyState(
            countries: countries,
            blocs: blocs,
            relations: [
                DiplomaticRelation(firstCountryId: "power_song", secondCountryId: "power_northern_han", status: .atWar, tension: 100, sinceTurn: turn),
                DiplomaticRelation(firstCountryId: "power_song", secondCountryId: "power_liao_edge", status: .hostile, tension: 85, sinceTurn: turn),
                DiplomaticRelation(firstCountryId: "power_song", secondCountryId: "power_southern_tang", status: .hostile, tension: 72, sinceTurn: turn),
                DiplomaticRelation(firstCountryId: "power_song", secondCountryId: "power_wuyue", status: .neutral, tension: 35, sinceTurn: turn),
                DiplomaticRelation(firstCountryId: "power_song", secondCountryId: "power_later_shu", status: .hostile, tension: 60, sinceTurn: turn),
                DiplomaticRelation(firstCountryId: "power_northern_han", secondCountryId: "power_liao_edge", status: .allied, tension: 10, sinceTurn: turn),
                DiplomaticRelation(firstCountryId: "power_southern_tang", secondCountryId: "power_wuyue", status: .neutral, tension: 20, sinceTurn: turn),
                DiplomaticRelation(firstCountryId: "power_southern_tang", secondCountryId: "power_later_shu", status: .neutral, tension: 25, sinceTurn: turn),
                DiplomaticRelation(firstCountryId: "power_wuyue", secondCountryId: "power_later_shu", status: .neutral, tension: 18, sinceTurn: turn)
            ],
            lastUpdatedTurn: turn
        )
    }

    private func initialMandateState(for scenario: ScenarioDefinition, turn: Int) -> MandateState {
        guard scenario.id == ScenarioResource.tangSongJianlong else {
            return .empty
        }

        return MandateState(
            legitimacyByFaction: [
                .allies: 62,
                .germany: 38
            ],
            lastUpdatedTurn: turn
        )
    }

    func loadTerrainRules() throws -> TerrainRuleDefinition {
        try loadJSON(TerrainRuleDefinition.self, named: "terrain_rules")
    }

    func loadUnitTemplates(named resourceName: String = "unit_templates") throws -> [UnitTemplateDefinition] {
        try loadJSON(UnitTemplateCatalogDefinition.self, named: resourceName).templates
    }

    func loadGeneralAgents() throws -> [GeneralAgentDefinition] {
        try loadJSON(GeneralAgentCatalogDefinition.self, named: "general_agents").agents
    }

    func loadGeneralRegistry() throws -> GeneralRegistry {
        let catalog = try loadJSON(GeneralCatalogDefinition.self, named: "generals")
        return GeneralRegistry(generals: catalog.generals)
    }

    /// v0.2: 加载阿登省份图数据。失败时抛 DataLoaderError。
    /// 返回的 RegionDataSet 可通过 toRegions()/toRegionEdges()/toHexToRegion() 映射到 MapState 叠加层。
    func loadArdennesV02Regions() throws -> RegionDataSet {
        try loadJSON(RegionDataSet.self, named: "ardennes_v02_regions")
    }

    /// v0.2: 校验省份数据集一致性。复用 RegionGraph.validate + hexToRegion/overlap 检查。
    /// 错误聚合为 DataLoaderError.validationFailed，便于 Agent 5 测试断言。
    func validate(_ regionData: RegionDataSet) throws {
        let regions = regionData.toRegions()
        let hexToRegion = regionData.toHexToRegion()
        let regionEdges = regionData.toRegionEdges()

        // 构临时 MapState 跑 validateRegionGraph（含 hexToRegion + overlap 检查）
        let probe = MapState(
            width: 11,
            height: 9,
            tiles: [:],
            supplySources: [],
            objectives: [],
            regions: regions,
            hexToRegion: hexToRegion,
            regionEdges: regionEdges
        )
        let errors = probe.validateRegionGraph().map { DataValidationError(message: $0.description) }
        if !errors.isEmpty {
            throw DataLoaderError.validationFailed(errors)
        }
    }

    func validate(_ dataSet: ScenarioDataSet) throws {
        var errors: [DataValidationError] = []
        let scenario = dataSet.scenario

        if !scenario.map.isSparse {
            let expectedTileCount = scenario.map.width * scenario.map.height
            if scenario.map.tiles.count != expectedTileCount {
                errors.append(
                    DataValidationError(
                        message: "Map tile count \(scenario.map.tiles.count) does not match width * height \(expectedTileCount)."
                    )
                )
            }
        }

        let tileCoords = Set(scenario.map.tiles.map(\.coord))
        if tileCoords.count != scenario.map.tiles.count {
            errors.append(DataValidationError(message: "Map contains duplicate tile coordinates."))
        }

        let unitIds = scenario.initialUnits.map(\.id)
        appendDuplicateErrors(unitIds, label: "initial unit id", to: &errors)

        let occupiedCoords = scenario.initialUnits.map(\.coord)
        if Set(occupiedCoords).count != occupiedCoords.count {
            errors.append(DataValidationError(message: "Initial units contain overlapping coordinates."))
        }

        for unit in scenario.initialUnits where !tileCoords.contains(unit.coord) {
            errors.append(
                DataValidationError(
                    message: "Initial unit \(unit.id) references missing tile (\(unit.coord.q),\(unit.coord.r))."
                )
            )
        }

        let templateIds = Set(dataSet.unitTemplates.map(\.id))
        appendDuplicateErrors(dataSet.unitTemplates.map(\.id), label: "unit template id", to: &errors)
        for unit in scenario.initialUnits where !templateIds.contains(unit.templateId) {
            errors.append(
                DataValidationError(
                    message: "Initial unit \(unit.id) references unknown template \(unit.templateId)."
                )
            )
        }

        for template in dataSet.unitTemplates {
            let componentWeight = template.components.reduce(0.0) { $0 + $1.weight }
            if abs(componentWeight - 1.0) > 0.0001 {
                errors.append(
                    DataValidationError(
                        message: "Unit template \(template.id) component weights sum to \(componentWeight), expected 1.0."
                    )
                )
            }
        }

        let germanSupplySources = scenario.map.tiles.filter {
            $0.isSupplySource && $0.supplyFaction == "germany"
        }
        let alliedSupplySources = scenario.map.tiles.filter {
            $0.isSupplySource && $0.supplyFaction == "allies"
        }
        if germanSupplySources.isEmpty {
            errors.append(DataValidationError(message: "Scenario is missing a German supply source."))
        }
        if alliedSupplySources.isEmpty {
            errors.append(DataValidationError(message: "Scenario is missing an Allied supply source."))
        }

        errors.append(contentsOf: scenarioReferenceErrors(in: scenario))

        let agentIds = dataSet.generalAgents.map(\.id)
        appendDuplicateErrors(agentIds, label: "general agent id", to: &errors)

        if scenario.id == "ardennes_v0" {
            let unitIdSet = Set(unitIds)
            for agent in dataSet.generalAgents {
                for divisionId in agent.assignedDivisionIds where !unitIdSet.contains(divisionId) {
                    errors.append(
                        DataValidationError(
                            message: "Agent \(agent.id) references unknown division \(divisionId)."
                        )
                    )
                }
            }

            if let guderian = dataSet.generalAgents.first(where: { $0.id == "guderian" }) {
                let germanUnitIds = Set(scenario.initialUnits.filter { $0.faction == "germany" }.map(\.id))
                let assignedDivisionIds = Set(guderian.assignedDivisionIds)
                if assignedDivisionIds != germanUnitIds {
                    errors.append(
                        DataValidationError(
                            message: "guderian.assignedDivisionIds must exactly cover German initial units."
                        )
                    )
                }
            } else {
                errors.append(DataValidationError(message: "Scenario is missing guderian agent configuration."))
            }
        }

        if !errors.isEmpty {
            throw DataLoaderError.validationFailed(errors)
        }
    }

    private func validateScenarioReferences(in scenario: ScenarioDefinition) throws {
        let errors = scenarioReferenceErrors(in: scenario)
        if !errors.isEmpty {
            throw DataLoaderError.validationFailed(errors)
        }
    }

    private func scenarioReferenceErrors(in scenario: ScenarioDefinition) -> [DataValidationError] {
        var errors: [DataValidationError] = []

        let objectiveIds = scenario.objectives.map(\.id)
        appendDuplicateErrors(objectiveIds, label: "objective id", to: &errors)
        let objectiveIdSet = Set(objectiveIds)

        let tileObjectiveIds = scenario.map.tiles.compactMap(\.objectiveId)
        appendDuplicateErrors(tileObjectiveIds, label: "tile objective id", to: &errors)
        for objectiveId in tileObjectiveIds where !objectiveIdSet.contains(objectiveId) {
            errors.append(
                DataValidationError(
                    message: "Tile objective \(objectiveId) is not declared in scenario objectives."
                )
            )
        }

        let supportedVictoryTypes = Set(["controlObjectives", "holdObjectives"])
        let supportedVictoryStatuses = Set(["majorVictory", "survival"])
        for condition in scenario.victoryConditions {
            if Faction(rawValue: condition.faction) == nil {
                errors.append(
                    DataValidationError(
                        message: "Victory condition \(condition.id) references unknown faction \(condition.faction)."
                    )
                )
            }

            if !supportedVictoryTypes.contains(condition.type) {
                errors.append(
                    DataValidationError(
                        message: "Victory condition \(condition.id) uses unsupported type \(condition.type)."
                    )
                )
            }

            if !supportedVictoryStatuses.contains(condition.status) {
                errors.append(
                    DataValidationError(
                        message: "Victory condition \(condition.id) uses unsupported status \(condition.status)."
                    )
                )
            }

            if let count = condition.count, count <= 0 {
                errors.append(
                    DataValidationError(
                        message: "Victory condition \(condition.id) count must be positive."
                    )
                )
            }

            if let objectiveId = condition.objectiveId, !objectiveIdSet.contains(objectiveId) {
                errors.append(
                    DataValidationError(
                        message: "Victory condition \(condition.id) references unknown objective \(objectiveId)."
                    )
                )
            }

            for objectiveId in condition.objectiveIds ?? [] where !objectiveIdSet.contains(objectiveId) {
                errors.append(
                    DataValidationError(
                        message: "Victory condition \(condition.id) references unknown objective \(objectiveId)."
                    )
                )
            }
        }

        return errors
    }

    private func loadJSON<T: Decodable>(_ type: T.Type, named resourceName: String) throws -> T {
        let url = try resourceURL(named: resourceName)
        let data = try Data(contentsOf: url)
        return try decoder.decode(T.self, from: data)
    }

    private func makeMapState(from scenario: ScenarioDefinition) throws -> MapState {
        var errors: [DataValidationError] = []
        var tiles: [HexCoord: HexTile] = [:]
        var supplySources: [SupplySource] = []
        var objectives: [Objective] = []

        for tileDefinition in scenario.map.tiles {
            let coord = HexCoord(q: tileDefinition.q, r: tileDefinition.r)
            guard tiles[coord] == nil else {
                errors.append(DataValidationError(message: "Duplicate tile coordinate \(coord.q),\(coord.r)."))
                continue
            }

            guard let terrain = BaseTerrain(rawValue: tileDefinition.terrain) else {
                errors.append(DataValidationError(message: "Unknown terrain \(tileDefinition.terrain) at \(coord.q),\(coord.r)."))
                continue
            }

            let controller = Faction(rawValue: tileDefinition.controller)
            let riverEdges = Set(tileDefinition.riverEdges.compactMap(HexDirection.init(rawValue:)))
            let regionId = tileDefinition.regionId.map { RegionId($0) }
            let tile = HexTile(
                coord: coord,
                baseTerrain: terrain,
                hasRoad: tileDefinition.hasRoad,
                riverEdges: riverEdges,
                controller: controller,
                cityName: tileDefinition.cityName,
                fortressName: tileDefinition.fortressName,
                isPassable: true,
                regionId: regionId
            )
            tiles[coord] = tile

            if tileDefinition.isSupplySource,
               let supplyFactionString = tileDefinition.supplyFaction,
               let supplyFaction = Faction(rawValue: supplyFactionString) {
                supplySources.append(
                    SupplySource(
                        id: "supply_\(coord.q)_\(coord.r)",
                        faction: supplyFaction,
                        coord: coord
                    )
                )
            }
        }

        for objectiveDefinition in scenario.objectives {
            guard let type = ObjectiveType(rawValue: objectiveDefinition.kind) else {
                errors.append(DataValidationError(message: "Unknown objective type \(objectiveDefinition.kind)."))
                continue
            }
            objectives.append(
                Objective(
                    id: objectiveDefinition.id,
                    name: objectiveDefinition.name,
                    coord: HexCoord(q: objectiveDefinition.coord.q, r: objectiveDefinition.coord.r),
                    type: type
                )
            )
        }

        if !errors.isEmpty {
            throw DataLoaderError.validationFailed(errors)
        }

        return MapState(
            width: scenario.map.width,
            height: scenario.map.height,
            tiles: tiles,
            supplySources: supplySources,
            objectives: objectives
        )
    }

    private func apply(_ regionData: RegionDataSet, to map: inout MapState) throws {
        map.regions = regionData.toRegions()
        map.hexToRegion = regionData.toHexToRegion()
        map.regionEdges = regionData.toRegionEdges()

        for (coord, regionId) in map.hexToRegion {
            guard var tile = map.tile(at: coord) else { continue }
            tile.regionId = regionId
            map.setTile(tile)
        }

        let errors = map.validateRegionGraph().map { DataValidationError(message: $0.description) }
        if !errors.isEmpty {
            throw DataLoaderError.validationFailed(errors)
        }
    }

    private func assignGenerals(
        to deploymentState: WarDeploymentState,
        map: MapState,
        regionData: RegionDataSet
    ) -> WarDeploymentState {
        let registry = (try? loadGeneralRegistry()) ?? .empty
        let seedAssignments = Dictionary(uniqueKeysWithValues: regionData.regions.compactMap { definition in
            definition.assignedGeneralId.map { (definition.id, $0) }
        })
        return GeneralDispatcher(registry: registry).assignGenerals(
            to: deploymentState,
            map: map,
            seedAssignments: seedAssignments
        )
    }

    private func makeDivisions(
        from definitions: [InitialUnitDefinition],
        templates: [UnitTemplateDefinition]
    ) throws -> [Division] {
        var errors: [DataValidationError] = []
        let divisions = definitions.compactMap { definition -> Division? in
            guard let faction = Faction(rawValue: definition.faction) else {
                errors.append(DataValidationError(message: "Unknown unit faction \(definition.faction)."))
                return nil
            }

            let components: [DivisionComponent]
            let template = templates.first { $0.id == definition.templateId }
            if let template {
                components = template.components.compactMap { component in
                    guard let type = ComponentType(rawValue: component.type) else { return nil }
                    return DivisionComponent(type: type, weight: component.weight)
                }
            } else {
                components = fallbackComponents(for: definition.templateId)
            }

            guard !components.isEmpty else {
                errors.append(DataValidationError(message: "Unit \(definition.id) references unknown template \(definition.templateId)."))
                return nil
            }

            return Division(
                id: definition.id,
                name: definition.name,
                faction: faction,
                coord: HexCoord(q: definition.coord.q, r: definition.coord.r),
                facing: HexDirection(rawValue: definition.facing) ?? .west,
                hp: definition.hp,
                maxHP: template?.maxHP ?? 10,
                components: components,
                supplyState: SupplyState(rawValue: definition.supplyState) ?? .supplied,
                retreatMode: definition.retreatMode.flatMap(RetreatMode.init(rawValue:)) ?? .retreatable
            )
        }

        if !errors.isEmpty {
            throw DataLoaderError.validationFailed(errors)
        }
        return divisions
    }

    private func fallbackComponents(for templateId: String) -> [DivisionComponent] {
        switch templateId {
        case "tank_division", "panzer_division":
            return [DivisionComponent(type: .tank, weight: 0.7), DivisionComponent(type: .motorizedInfantry, weight: 0.3)]
        case "motorized_division":
            return [DivisionComponent(type: .motorizedInfantry, weight: 1.0)]
        case "artillery_division":
            return [DivisionComponent(type: .artillery, weight: 1.0)]
        default:
            return [DivisionComponent(type: .infantry, weight: 1.0)]
        }
    }

    private func makeTheaterState(
        map: MapState,
        regionData: RegionDataSet,
        divisions: [Division],
        turn: Int
    ) -> TheaterState {
        let assignments = Dictionary(uniqueKeysWithValues: regionData.regions.compactMap { definition in
            definition.theaterId.map { (definition.id, $0) }
        })

        guard !assignments.isEmpty else {
            return TheaterSystem().makeInitialFixedTheaters(map: map, divisions: divisions, turn: turn)
        }

        var groupedRegions: [TheaterId: [RegionId]] = [:]
        for regionId in map.regions.keys {
            let theaterId = assignments[regionId] ?? TheaterId("unassigned")
            groupedRegions[theaterId, default: []].append(regionId)
        }

        let theaters = Dictionary(uniqueKeysWithValues: groupedRegions.map { theaterId, regionIds in
            let sortedRegionIds = regionIds.sorted { $0.rawValue < $1.rawValue }
            let controllingFaction = majorityController(regionIds: sortedRegionIds, map: map)
            return (
                theaterId,
                TheaterNode(
                    id: theaterId,
                    name: theaterId.rawValue,
                    status: .active,
                    regionIds: sortedRegionIds,
                    controllingFaction: controllingFaction
                )
            )
        })

        let regionToTheater = Dictionary(uniqueKeysWithValues: groupedRegions.flatMap { theaterId, regionIds in
            regionIds.map { ($0, theaterId) }
        })
        let state = TheaterState(theaters: theaters, regionToTheater: regionToTheater)
        var updated = TheaterSystem().updateTheaters(state: state, map: map, divisions: divisions, turn: turn)
        updated.initialSnapshot = TheaterInitialSnapshot.capture(from: updated)
        return updated
    }

    private func majorityController(regionIds: [RegionId], map: MapState) -> Faction? {
        let counts = Dictionary(grouping: regionIds.compactMap { map.regions[$0]?.controller }) { $0 }
            .mapValues(\.count)
        return counts.sorted { lhs, rhs in
            lhs.value == rhs.value ? lhs.key.rawValue < rhs.key.rawValue : lhs.value > rhs.value
        }.first?.key
    }

    private func resourceURL(named resourceName: String) throws -> URL {
        if let resourceDirectory {
            return resourceDirectory
                .appendingPathComponent(resourceName)
                .appendingPathExtension("json")
        }

        #if DEBUG
        if let sourceURL = sourceDataURL(named: resourceName) {
            return sourceURL
        }
        #endif

        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw DataLoaderError.missingResource(resourceName)
        }
        return url
    }

    #if DEBUG
    private func sourceDataURL(named resourceName: String) -> URL? {
        let fileURL = URL(fileURLWithPath: #filePath)
        let dataDirectory = fileURL.deletingLastPathComponent()
        let url = dataDirectory
            .appendingPathComponent(resourceName)
            .appendingPathExtension("json")
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
    #endif

    private func appendDuplicateErrors(
        _ values: [String],
        label: String,
        to errors: inout [DataValidationError]
    ) {
        var seen: Set<String> = []
        var duplicates: Set<String> = []

        for value in values where !seen.insert(value).inserted {
            duplicates.insert(value)
        }

        for duplicate in duplicates.sorted() {
            errors.append(DataValidationError(message: "Duplicate \(label): \(duplicate)."))
        }
    }
}
