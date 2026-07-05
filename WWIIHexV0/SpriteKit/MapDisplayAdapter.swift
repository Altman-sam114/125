import SpriteKit

typealias DisplayColor = SKColor

enum VisibilityState: Equatable {
    case unseen
    case explored
    case visible
}

struct HexDisplayState {
    let coord: HexCoord
    let regionId: RegionId?
    let terrain: BaseTerrain
    let controller: Faction?
    let cityName: String?
    let fortressName: String?
    let isRepresentative: Bool
    let visibility: VisibilityState
}

struct UnitDisplayPlacement: Equatable {
    let divisionId: String
    let hex: HexCoord
    let offset: CGPoint
    let stackIndex: Int
    let stackCount: Int
}

struct SiegeOverlayState: Equatable {
    let regionId: RegionId
    let displayHexes: [HexCoord]
    let representativeHex: HexCoord
    let pressure: Int
    let fortification: Int
    let maxFortification: Int
    let attackerFaction: Faction
    let defenderFaction: Faction
    let besiegerCount: Int

    var labelText: String {
        "围\(pressure) 城\(fortification)/\(maxFortification)"
    }

    var fortificationRatio: Double {
        Double(fortification) / Double(max(maxFortification, 1))
    }
}

extension UnitDisplayPlacement {
    static func == (lhs: UnitDisplayPlacement, rhs: UnitDisplayPlacement) -> Bool {
        lhs.divisionId == rhs.divisionId &&
            lhs.hex == rhs.hex &&
            lhs.offset.x == rhs.offset.x &&
            lhs.offset.y == rhs.offset.y &&
            lhs.stackIndex == rhs.stackIndex &&
            lhs.stackCount == rhs.stackCount
    }
}

struct RegionInspectorState: Equatable {
    let region: RegionNode
    let selectedHex: HexCoord?
    let selectedHexController: Faction?
    let selectedHexDynamicTheaterId: TheaterId?
    let selectedHexFrontZoneId: FrontZoneId?
    let theaterId: TheaterId?
    let frontZoneId: FrontZoneId?
    let frontPressure: Double
    let friendlyDivisions: [Division]
    let visibleEnemyDivisions: [Division]
    let objectiveNames: [String]
    let objectiveStatus: String
    let cityLevel: CityLevel
    let economicOutput: EconomyResources
    let siegeRecord: SiegeRecord?
}

struct UnitInspectorStrategicState: Equatable {
    let coord: HexCoord
    let regionId: RegionId?
    let dynamicTheaterId: TheaterId?
    let frontLineIds: [FrontLineId]
    let frontZoneId: FrontZoneId?
    let deploymentRole: UnitDeploymentRole
    let supplyRouteSummary: SupplyRouteSummary
    let isTangSongScenario: Bool
}

struct MapDisplayAdapter {
    let state: GameState
    let revealAll: Bool

    init(state: GameState, revealAll: Bool = false) {
        self.state = state
        self.revealAll = revealAll
    }

    func regionId(for hex: HexCoord) -> RegionId? {
        state.map.region(for: hex)
    }

    func displayHexes(for regionId: RegionId) -> [HexCoord] {
        state.map.region(id: regionId)?.displayHexes ?? []
    }

    func representativeHex(for regionId: RegionId) -> HexCoord? {
        state.map.representativeHex(for: regionId)
    }

    func terrainColor(for hex: HexCoord) -> DisplayColor {
        TerrainStyle.fillColor(for: terrain(for: hex), isTangSongScenario: state.isTangSongScenario)
    }

    func controllerColor(for hex: HexCoord) -> DisplayColor {
        TerrainStyle.controllerColor(for: controller(for: hex), isTangSongScenario: state.isTangSongScenario)
    }

    func unitDisplayHex(for division: Division) -> HexCoord? {
        division.coord
    }

    func visibility(for hex: HexCoord, faction: Faction) -> VisibilityState {
        if revealAll {
            return .visible
        }
        guard !state.map.regions.isEmpty,
              let regionId = regionId(for: hex) else {
            return .visible
        }

        let visibleRegions = RegionVisibilityRules().visibleRegions(for: faction, in: state)
        return visibleRegions.contains(regionId) ? .visible : .unseen
    }

    func hexDisplayState(for hex: HexCoord, viewerFaction: Faction) -> HexDisplayState? {
        guard state.map.contains(hex) else {
            return nil
        }

        let regionId = regionId(for: hex)
        let region = regionId.flatMap { state.map.region(id: $0) }
        let tile = state.map.tile(at: hex)
        let terrain = tile?.baseTerrain ?? region?.terrain ?? .plain
        let cityName = tile?.cityName ?? (hex == region?.representativeHex ? region?.city?.name : nil)
        let fortressName = tile?.fortressName

        return HexDisplayState(
            coord: hex,
            regionId: regionId,
            terrain: terrain,
            controller: tile?.controller ?? region?.controller,
            cityName: cityName,
            fortressName: fortressName,
            isRepresentative: hex == region?.representativeHex,
            visibility: visibility(for: hex, faction: viewerFaction)
        )
    }

    func unitPlacements(viewerFaction: Faction) -> [String: UnitDisplayPlacement] {
        let visibleDivisions = state.divisions.filter { isDivisionVisible($0, viewerFaction: viewerFaction) }
        let grouped = Dictionary(grouping: visibleDivisions) { division in
            unitDisplayHex(for: division) ?? division.coord
        }

        var placements: [String: UnitDisplayPlacement] = [:]
        for (hex, divisions) in grouped {
            let sorted = divisions.sorted { lhs, rhs in
                lhs.id < rhs.id
            }
            for (index, division) in sorted.enumerated() {
                placements[division.id] = UnitDisplayPlacement(
                    divisionId: division.id,
                    hex: hex,
                    offset: stackOffset(index: index, count: sorted.count),
                    stackIndex: index,
                    stackCount: sorted.count
                )
            }
        }
        return placements
    }

    func divisions(displayedAt hex: HexCoord, viewerFaction: Faction) -> [Division] {
        let placements = unitPlacements(viewerFaction: viewerFaction)
        return state.divisions
            .filter { placements[$0.id]?.hex == hex }
            .sorted { lhs, rhs in
                if lhs.faction == viewerFaction, rhs.faction != viewerFaction {
                    return true
                }
                if lhs.faction != viewerFaction, rhs.faction == viewerFaction {
                    return false
                }
                return lhs.id < rhs.id
            }
    }

    func isDivisionVisible(_ division: Division, viewerFaction: Faction) -> Bool {
        if division.faction == viewerFaction {
            return true
        }

        guard let displayHex = unitDisplayHex(for: division) else {
            return false
        }
        return visibility(for: displayHex, faction: viewerFaction) == .visible
    }

    func siegeOverlays(viewerFaction: Faction) -> [SiegeOverlayState] {
        let visibleRegionIds = revealAll ? nil : RegionVisibilityRules().visibleRegions(for: viewerFaction, in: state)
        return state.siegeState.records.compactMap { record in
            guard let region = state.map.region(id: record.targetRegionId) else {
                return nil
            }

            let involvedFaction = record.attackerFaction == viewerFaction || record.defenderFaction == viewerFaction
            guard revealAll || involvedFaction || visibleRegionIds?.contains(region.id) == true else {
                return nil
            }

            return SiegeOverlayState(
                regionId: region.id,
                displayHexes: region.displayHexes,
                representativeHex: state.map.representativeHex(for: region.id) ?? region.representativeHex,
                pressure: record.pressure,
                fortification: record.fortification,
                maxFortification: record.maxFortification,
                attackerFaction: record.attackerFaction,
                defenderFaction: record.defenderFaction,
                besiegerCount: record.besiegingDivisionIds.count
            )
        }
    }

    func inspectorState(for regionId: RegionId, selectedHex: HexCoord? = nil, viewerFaction: Faction) -> RegionInspectorState? {
        guard let region = state.map.region(id: regionId) else {
            return nil
        }

        let divisions = state.divisions.filter { division in
            division.location(in: state.map) == regionId
        }
        let friendly = divisions.filter { $0.faction == viewerFaction }
        let visibleEnemy = divisions.filter { division in
            division.faction != viewerFaction && isDivisionVisible(division, viewerFaction: viewerFaction)
        }
        let objectiveNames = state.map.objectives
            .filter { objective in
                region.displayHexes.contains(objective.coord)
            }
            .map(\.name)
        let objectiveStatus = objectiveNames.isEmpty
            ? "None"
            : "\(region.controller.displayName) controlled"

        let cityLevel = EconomyRules().cityLevel(for: region, map: state.map)
        let economicOutput = regionalEconomicOutput(for: region, cityLevel: cityLevel)

        return RegionInspectorState(
            region: region,
            selectedHex: selectedHex,
            selectedHexController: selectedHex.flatMap { state.map.tile(at: $0)?.controller },
            selectedHexDynamicTheaterId: selectedHex.flatMap { state.theaterState.dynamicTheaterId(for: $0, map: state.map) },
            selectedHexFrontZoneId: selectedHex.flatMap { state.warDeploymentState.zoneId(for: $0, map: state.map) },
            theaterId: state.theaterState.dominantDynamicTheaterId(for: regionId, map: state.map),
            frontZoneId: dominantDynamicFrontZoneId(for: regionId),
            frontPressure: state.frontLineState.regionStates[regionId]?.frontLines
                .flatMap(\.segments)
                .map(\.pressureLevel)
                .max() ?? 0,
            friendlyDivisions: friendly,
            visibleEnemyDivisions: visibleEnemy,
            objectiveNames: objectiveNames,
            objectiveStatus: objectiveStatus,
            cityLevel: cityLevel,
            economicOutput: economicOutput,
            siegeRecord: state.siegeState.record(for: regionId)
        )
    }

    func unitInspectorState(for division: Division) -> UnitInspectorStrategicState {
        let regionId = division.location(in: state.map)
        let frontLineIds = regionId
            .flatMap { state.frontLineState.regionStates[$0]?.frontLines.map(\.id) } ?? []
        return UnitInspectorStrategicState(
            coord: division.coord,
            regionId: regionId,
            dynamicTheaterId: state.theaterState.dynamicTheaterId(for: division.coord, map: state.map),
            frontLineIds: frontLineIds.sorted { $0.rawValue < $1.rawValue },
            frontZoneId: state.warDeploymentState.zoneId(for: division.coord, map: state.map),
            deploymentRole: WarDeploymentManager().deploymentRole(
                for: division,
                in: state.map,
                state: state.warDeploymentState
            ),
            supplyRouteSummary: SupplyRules().supplyRouteSummary(for: division, in: state),
            isTangSongScenario: state.isTangSongScenario
        )
    }

    private func dominantDynamicFrontZoneId(for regionId: RegionId) -> FrontZoneId? {
        guard let region = state.map.region(id: regionId) else {
            return state.warDeploymentState.regionToFrontZone[regionId]
        }
        var counts: [FrontZoneId: Int] = [:]
        for hex in region.displayHexes {
            if let zoneId = state.warDeploymentState.zoneId(for: hex, map: state.map) {
                counts[zoneId, default: 0] += 1
            }
        }
        return counts.max {
            $0.value == $1.value ? $0.key.rawValue > $1.key.rawValue : $0.value < $1.value
        }?.key ?? state.warDeploymentState.regionToFrontZone[regionId]
    }

    private func terrain(for hex: HexCoord) -> BaseTerrain {
        if let regionId = regionId(for: hex),
           let region = state.map.region(id: regionId) {
            return region.terrain
        }
        return state.map.tile(at: hex)?.baseTerrain ?? .plain
    }

    private func controller(for hex: HexCoord) -> Faction? {
        if let regionId = regionId(for: hex),
           let region = state.map.region(id: regionId) {
            return region.controller
        }
        return state.map.tile(at: hex)?.controller
    }

    private func regionalEconomicOutput(for region: RegionNode, cityLevel: CityLevel) -> EconomyResources {
        let coreBonus = region.coreOf.isEmpty || region.coreOf.contains(region.controller) ? 1 : 0
        return EconomyResources(
            manpower: max(1, cityLevel.manpowerGrowth + coreBonus * 4 + region.infrastructure),
            industry: max(0, region.factories + cityLevel.industryValue + region.infrastructure / 3),
            supplies: max(1, region.supplyValue * 3 + region.factories + region.infrastructure / 2)
        )
    }

    private func stackOffset(index: Int, count: Int) -> CGPoint {
        guard count > 1 else {
            return .zero
        }

        let offsets: [CGPoint] = [
            CGPoint(x: -10, y: 8),
            CGPoint(x: 10, y: -8),
            CGPoint(x: -10, y: -8),
            CGPoint(x: 10, y: 8)
        ]
        return offsets[index % offsets.count]
    }
}
