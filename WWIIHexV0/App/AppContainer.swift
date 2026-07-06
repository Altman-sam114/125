import Combine
import Foundation

final class AppContainer: ObservableObject {
    @Published private(set) var gameState: GameState
    @Published private(set) var selectedUnitId: String?
    @Published private(set) var selectedHex: HexCoord?
    @Published private(set) var selectedRegionId: RegionId?
    @Published private(set) var focusedObjectiveId: String?
    @Published private(set) var movementHighlights: Set<HexCoord>
    @Published private(set) var attackHighlights: Set<HexCoord>
    @Published private(set) var interactionLog: [GameLogEntry]
    @Published private(set) var lastCommandMessage: String?
    @Published private(set) var lastAgentDecisionRecord: AgentDecisionRecord?
    @Published private(set) var lastWarDirectiveRecords: [WarDirectiveRecord]
    @Published private(set) var observerModeEnabled: Bool
    @Published private(set) var playerFaction: Faction
    @Published private(set) var mapDisplayLayer: MapDisplayLayer

    let commandHandler: GameCommandHandling
    let dataLoader: DataLoader
    let generalRegistry: GeneralRegistry
    let warPipelineMode: WarPipelineMode
    let turnManager: TurnManager?
    private var isRunningAI = false
    private let warRelationRules = WarRelationRules()

    init(
        gameState: GameState,
        commandHandler: GameCommandHandling,
        dataLoader: DataLoader,
        generalRegistry: GeneralRegistry = .empty,
        playerFaction: Faction? = nil,
        turnManager: TurnManager? = nil,
        warPipelineMode: WarPipelineMode = .marshalDirective,
        observerModeEnabled: Bool = false,
        mapDisplayLayer: MapDisplayLayer = .hex
    ) {
        let bootstrappedState = StrategicStateBootstrapper().bootstrapIfNeeded(gameState)
        let configuredPlayerFaction = playerFaction ?? Self.playerFaction(from: bootstrappedState)
        self.gameState = Self.configuredState(
            Self.refreshGeneralAssignments(in: bootstrappedState, registry: generalRegistry),
            playerFaction: configuredPlayerFaction
        )
        self.commandHandler = commandHandler
        self.dataLoader = dataLoader
        self.generalRegistry = generalRegistry
        self.playerFaction = configuredPlayerFaction
        self.warPipelineMode = warPipelineMode
        self.turnManager = turnManager
        self.selectedUnitId = nil
        self.selectedHex = nil
        self.selectedRegionId = nil
        self.focusedObjectiveId = nil
        self.movementHighlights = []
        self.attackHighlights = []
        self.interactionLog = []
        self.lastCommandMessage = nil
        self.lastAgentDecisionRecord = nil
        self.lastWarDirectiveRecords = []
        self.observerModeEnabled = observerModeEnabled
        self.mapDisplayLayer = mapDisplayLayer
    }

    static func bootstrap() -> AppContainer {
        let dataLoader = DataLoader()
        let gameState = dataLoader.loadInitialGameState()
        let commandHandler = RuleEngine()
        let generalRegistry = (try? dataLoader.loadGeneralRegistry(for: gameState.scenarioId)) ?? .empty
        let bootstrappedState = Self.refreshGeneralAssignments(
            in: StrategicStateBootstrapper().bootstrapIfNeeded(gameState),
            registry: generalRegistry
        )
        let aiAgent = GameAgent.defaultCommander(for: .germany, from: dataLoader, state: bootstrappedState)
        let turnManager = TurnManager(
            agent: aiAgent,
            provider: MockAIClient(),
            providerName: "MockAI",
            commandHandler: commandHandler,
            commanderPool: Self.buildCommanderPool(state: bootstrappedState, registry: generalRegistry),
            marshalAgent: Self.buildMarshalAgent(faction: .germany, state: bootstrappedState)
        )
        return AppContainer(
            gameState: bootstrappedState,
            commandHandler: commandHandler,
            dataLoader: dataLoader,
            generalRegistry: generalRegistry,
            turnManager: turnManager,
            warPipelineMode: .marshalDirective
        )
    }

    func submit(_ command: Command) {
        let stateBeforeCommand = gameState
        let result = commandHandler.execute(command, in: gameState)
        var nextState = StrategicStateBootstrapper().bootstrapIfNeeded(result.state)
        if result.succeeded {
            nextState = applyPlayerCommandBookkeeping(
                command,
                to: nextState,
                previousState: stateBeforeCommand
            )
        }
        gameState = refreshGeneralAssignments(in: nextState)
        lastCommandMessage = result.message

        let commandName = command.displayName(isTangSongScenario: gameState.isTangSongScenario)
        let status = result.succeeded ? "accepted" : "rejected"
        let statusText = gameState.isTangSongScenario
            ? (result.succeeded ? "军令接受" : "军令驳回")
            : "Command \(status)"
        appendInteractionEvent("\(statusText): \(commandName). \(result.message)")
        refreshSelectionAfterStateChange()
        runAIIfNeeded()
    }

    func runAIIfNeeded() {
        guard !isRunningAI else {
            return
        }

        gameState = refreshedRuntimeState(gameState)
        guard shouldRunAI(for: gameState.activeFaction, phase: gameState.phase) else {
            return
        }

        isRunningAI = true
        let stateSnapshot = gameState
        let pipelineMode = warPipelineMode
        let observerEnabled = observerModeEnabled

        Task {
            let outcome = await self.runAISequence(
                from: stateSnapshot,
                pipelineMode: pipelineMode,
                observerEnabled: observerEnabled
            )
            await MainActor.run {
                self.gameState = self.refreshedRuntimeState(outcome.state)
                self.lastAgentDecisionRecord = outcome.record
                self.lastWarDirectiveRecords = outcome.directiveRecords
                self.lastCommandMessage = outcome.record.errors.isEmpty
                    ? "AI turn completed."
                    : "AI turn completed with \(outcome.record.errors.count) issue(s)."
                self.appendInteractionEvent("AI \(outcome.record.provider) resolved \(outcome.record.commandResults.count) command result(s).")
                self.isRunningAI = false
                self.refreshSelectionAfterStateChange()
            }
        }
    }

    func handleBoardTap(_ coord: HexCoord) {
        guard gameState.map.contains(coord) else {
            return
        }

        selectedHex = coord
        selectedRegionId = mapDisplayAdapter.regionId(for: coord)
        appendInteractionEvent(selectionMessage(for: coord))

        let displayedDivisions = mapDisplayAdapter.divisions(displayedAt: coord, viewerFaction: playerFaction)
        if let attacker = selectedActionDivision,
           let enemy = displayedDivisions.first(where: {
               warRelationRules.canTarget(attacker: attacker.faction, target: $0.faction, in: gameState)
           }) {
            submit(.attack(attackerId: attacker.id, targetId: enemy.id))
            return
        }

        if let tappedDivision = displayedDivisions.first {
            handleDivisionTap(tappedDivision)
            return
        }

        if let division = selectedActionDivision {
            submitMove(division: division, tappedHex: coord)
        } else {
            selectedUnitId = nil
            clearHighlights()
        }
    }

    func focusObjective(id objectiveId: String) {
        guard let objective = gameState.map.objective(id: objectiveId),
              gameState.map.contains(objective.coord) else {
            return
        }

        selectedHex = objective.coord
        selectedRegionId = mapDisplayAdapter.regionId(for: objective.coord)
        focusedObjectiveId = objective.id
        appendInteractionEvent(
            gameState.isTangSongScenario
                ? "已定位目标州府：\(objective.name)。"
                : "Focused objective: \(objective.name)."
        )
    }

    func holdSelected() {
        guard let division = selectedActionDivision else {
            appendInteractionEvent("Hold rejected: no active allied unit selected.")
            return
        }

        submit(.hold(divisionId: division.id))
    }

    func allowRetreatSelected() {
        guard let division = selectedActionDivision else {
            appendInteractionEvent("Allow retreat rejected: no active allied unit selected.")
            return
        }

        submit(.allowRetreat(divisionId: division.id))
    }

    func resupplySelected() {
        guard let division = selectedActionDivision else {
            appendInteractionEvent("Resupply rejected: no active allied unit selected.")
            return
        }

        submit(.resupply(divisionId: division.id))
    }

    func besiegeSelected() {
        guard let division = selectedActionDivision else {
            appendInteractionEvent("Besiege rejected: no active allied unit selected.")
            return
        }

        guard let target = selectedBesiegeTarget else {
            appendInteractionEvent("Besiege rejected: no adjacent enemy city, pass, or granary selected.")
            return
        }

        submit(.besiege(attackerId: division.id, targetRegionId: target.id))
    }

    func repairFortificationSelected() {
        guard let division = selectedActionDivision else {
            appendInteractionEvent("Repair fortification rejected: no active allied unit selected.")
            return
        }

        guard let target = selectedRepairFortificationTarget else {
            appendInteractionEvent("Repair fortification rejected: no damaged friendly besieged city selected.")
            return
        }

        submit(.repairFortification(defenderId: division.id, targetRegionId: target.id))
    }

    func relieveSiegeSelected() {
        guard let division = selectedActionDivision else {
            appendInteractionEvent("Relieve siege rejected: no active allied unit selected.")
            return
        }

        guard let target = selectedRelieveSiegeTarget else {
            appendInteractionEvent("Relieve siege rejected: no friendly besieged city in range.")
            return
        }

        submit(.relieveSiege(relieverId: division.id, targetRegionId: target.id))
    }

    func demandSurrenderSelected() {
        guard let division = selectedActionDivision else {
            appendInteractionEvent("Demand surrender rejected: no active allied unit selected.")
            return
        }

        guard let target = selectedDemandSurrenderTarget else {
            appendInteractionEvent("Demand surrender rejected: no broken enemy siege target in range.")
            return
        }

        submit(.demandSurrender(negotiatorId: division.id, targetRegionId: target.id))
    }

    func proposeSubmissionSelected() {
        guard let division = selectedActionDivision else {
            appendInteractionEvent("Submission rejected: no active allied unit selected.")
            return
        }

        guard let target = selectedSubmissionTarget else {
            appendInteractionEvent("Submission rejected: no eligible foreign capital selected.")
            return
        }

        submit(
            .proposeSubmission(
                negotiatorId: division.id,
                targetCountryId: target.country.id,
                targetRegionIds: [target.region.id]
            )
        )
    }

    func orderSelectedGeneralHoldLine() {
        guard let zone = selectedGeneralCommandZone else {
            appendInteractionEvent("General order rejected: no allied front zone selected.")
            return
        }

        let directive = ZoneDirective(
            zoneId: zone.id,
            defense: DefenseParameters(
                targetReserves: max(1, min(2, zone.unitsDepth.count)),
                stance: .holdLine
            ),
            category: .defense,
            tactic: .holdPosition
        )
        submitPlayerDirective(
            directive,
            sourceRegionId: sourceRegionId(for: zone, targetZoneId: nil),
            targetRegionId: nil
        )
    }

    func orderSelectedGeneralAttackRegion() {
        guard let target = selectedAttackTarget else {
            appendInteractionEvent("General order rejected: select an enemy front region to attack.")
            return
        }
        guard let zone = selectedGeneralCommandZone else {
            appendInteractionEvent("General order rejected: no allied source front zone available.")
            return
        }

        let directive = ZoneDirective(
            zoneId: zone.id,
            attack: AttackParameters(
                targetTheaterId: TheaterId(target.zone.id.rawValue),
                weightedRegions: [target.region.id],
                intensity: .limitedCounter,
                focusRegionId: target.region.id,
                maxCommittedUnits: max(1, min(3, zone.unitsFront.count + zone.unitsDepth.count))
            ),
            category: .offense,
            tactic: .standardAttack,
            commandTarget: .region(target.region.id)
        )
        submitPlayerDirective(
            directive,
            sourceRegionId: sourceRegionId(for: zone, targetZoneId: target.zone.id),
            targetRegionId: target.region.id
        )
    }

    func queueProduction(_ kind: ProductionKind) {
        guard !observerModeEnabled else {
            appendInteractionEvent("Production rejected: observer mode is read-only.")
            return
        }

        submit(.queueProduction(kind: kind))
    }

    func endTurn() {
        submit(.endTurn)
    }

    func advanceOrRunAI() {
        if shouldRunAI(for: gameState.activeFaction, phase: gameState.phase) {
            runAIIfNeeded()
        } else {
            endTurn()
        }
    }

    func setObserverModeEnabled(_ enabled: Bool) {
        observerModeEnabled = enabled
        if enabled {
            refreshSelectionAfterStateChange()
            runAIIfNeeded()
        }
    }

    func setPlayerFaction(_ faction: Faction) {
        guard playerFaction != faction else {
            return
        }

        playerFaction = faction
        gameState = Self.configuredState(gameState, playerFaction: faction)
        selectedUnitId = nil
        movementHighlights = []
        attackHighlights = []
        let factionName = gameState.displayName(for: faction)
        appendInteractionEvent(
            gameState.isTangSongScenario
                ? "已切换亲征势力：\(factionName)。"
                : "Player faction changed: \(factionName)."
        )
        refreshSelectionAfterStateChange()
        runAIIfNeeded()
    }

    func setMapDisplayLayer(_ layer: MapDisplayLayer) {
        mapDisplayLayer = layer
    }

    func resetGame() {
        isRunningAI = false
        gameState = Self.configuredState(
            refreshGeneralAssignments(
                in: StrategicStateBootstrapper().bootstrapIfNeeded(dataLoader.loadInitialGameState())
            ),
            playerFaction: playerFaction
        )
        selectedUnitId = nil
        selectedHex = nil
        selectedRegionId = nil
        focusedObjectiveId = nil
        movementHighlights = []
        attackHighlights = []
        interactionLog = []
        lastCommandMessage = nil
        lastAgentDecisionRecord = nil
        lastWarDirectiveRecords = []
    }

    var selectedDivision: Division? {
        guard let selectedUnitId else {
            return nil
        }
        return gameState.division(id: selectedUnitId)
    }

    var selectedRegionInspectorState: RegionInspectorState? {
        guard let selectedRegionId else {
            return nil
        }
        return mapDisplayAdapter.inspectorState(for: selectedRegionId, selectedHex: selectedHex, viewerFaction: playerFaction)
    }

    var selectedUnitInspectorStrategicState: UnitInspectorStrategicState? {
        guard let selectedDivision else {
            return nil
        }
        return mapDisplayAdapter.unitInspectorState(for: selectedDivision)
    }

    var selectedGeneralCommandZone: FrontZone? {
        inferredPlayerCommandZone()
    }

    var selectedGeneral: GeneralData? {
        generalRegistry.general(id: selectedGeneralAssignment?.generalId)
    }

    var selectedGeneralAssignment: GeneralAssignment? {
        selectedGeneralCommandZone?.generalAssignment
    }

    var selectedGeneralAssignedDivisions: [Division] {
        guard let assignment = selectedGeneralAssignment else {
            return []
        }
        let assignedIds = Set(assignment.assignedDivisionIds)
        return gameState.divisions
            .filter { assignedIds.contains($0.id) }
            .sorted { $0.id < $1.id }
    }

    var selectedGeneralHQUnderAttack: Bool {
        guard let zone = selectedGeneralCommandZone else {
            return false
        }
        return GeneralDispatcher(registry: generalRegistry).isHQUnderAttack(
            zone: zone,
            map: gameState.map
        )
    }

    var selectedGeneralTargetRegion: RegionNode? {
        selectedRegionId.flatMap { gameState.map.region(id: $0) }
    }

    var selectedGeneralTargetZone: FrontZone? {
        guard let selectedRegionId else {
            return nil
        }
        return gameState.warDeploymentState.zone(for: selectedRegionId)
    }

    var selectedGeneralPlannedOperations: [PlayerPlannedOperation] {
        let zoneId = selectedGeneralCommandZone?.id
        return Array(gameState.playerCommandState.plannedOperations
            .filter { operation in
                operation.turn == gameState.turn &&
                    (zoneId == nil || operation.zoneId == zoneId)
            }
            .suffix(5))
    }

    var canOrderSelectedGeneralHoldLine: Bool {
        canIssuePlayerDirective && selectedGeneralCommandZone != nil
    }

    var canOrderSelectedGeneralAttackRegion: Bool {
        canIssuePlayerDirective && selectedAttackTarget != nil && selectedGeneralCommandZone != nil
    }

    var displayEventLog: [GameLogEntry] {
        Array((gameState.eventLog + interactionLog).suffix(80))
    }

    var selectedUnitCanAct: Bool {
        selectedActionDivision != nil
    }

    var selectedBesiegeTargetName: String? {
        selectedBesiegeTarget.map(siegeTargetName)
    }

    var selectedRepairFortificationTargetName: String? {
        selectedRepairFortificationTarget.map(siegeTargetName)
    }

    var selectedRelieveSiegeTargetName: String? {
        selectedRelieveSiegeTarget.map(siegeTargetName)
    }

    var selectedDemandSurrenderTargetName: String? {
        selectedDemandSurrenderTarget.map(siegeTargetName)
    }

    var selectedSubmissionTargetName: String? {
        guard let target = selectedSubmissionTarget else {
            return nil
        }
        return target.country.name
    }

    var selectedValidatedCommandHint: String? {
        guard gameState.isTangSongScenario,
              let division = selectedActionDivision else {
            return nil
        }

        if let target = selectedDemandSurrenderTarget {
            return "规则确认可招降 \(siegeTargetName(target))。"
        }

        if let target = selectedBesiegeTarget {
            return "规则确认可围城 \(siegeTargetName(target))。"
        }

        if let target = selectedSubmissionTarget {
            return "规则确认可招抚 \(target.country.name)。"
        }

        if let target = selectedRelieveSiegeTarget {
            return "规则确认可解围 \(siegeTargetName(target))。"
        }

        if let target = selectedRepairFortificationTarget {
            return "规则确认可修城 \(siegeTargetName(target))。"
        }

        let attackCount = validAttackCount(for: division)
        let movementCount = validMovementCount(for: division)
        if attackCount > 0 && movementCount > 0 {
            return "规则确认该军有 \(attackCount) 个可攻击目标、\(movementCount) 处可行军格。"
        }
        if attackCount > 0 {
            return "规则确认该军有 \(attackCount) 个可攻击目标。"
        }
        if movementCount > 0 {
            return "规则确认该军有 \(movementCount) 处可行军格。"
        }

        if isValid(.hold(divisionId: division.id)) {
            return "规则确认该军可固守；若粮道紧张，也可考虑整补。"
        }

        return nil
    }

    private var selectedActionDivision: Division? {
        guard !observerModeEnabled else {
            return nil
        }
        guard let division = selectedDivision,
              division.faction == playerFaction,
              gameState.effectiveTurnOrderState.allowsCommands(activeFaction: playerFaction, phase: gameState.phase),
              !division.hasActed else {
            return nil
        }

        return division
    }

    private var selectedBesiegeTarget: RegionNode? {
        guard let division = selectedActionDivision else {
            return nil
        }

        if let selectedRegionId,
           let selectedRegion = gameState.map.region(id: selectedRegionId),
           canBesiege(division: division, targetRegion: selectedRegion) {
            return selectedRegion
        }

        return gameState.map.regions.values
            .filter { canBesiege(division: division, targetRegion: $0) }
            .sorted { lhs, rhs in
                let lhsDistance = siegeDistance(from: division, to: lhs)
                let rhsDistance = siegeDistance(from: division, to: rhs)
                if lhsDistance != rhsDistance {
                    return lhsDistance < rhsDistance
                }
                return lhs.id.rawValue < rhs.id.rawValue
            }
            .first
    }

    private var selectedRepairFortificationTarget: RegionNode? {
        guard let division = selectedActionDivision,
              let divisionRegionId = division.location(in: gameState.map) else {
            return nil
        }

        if let selectedRegionId,
           selectedRegionId == divisionRegionId,
           let selectedRegion = gameState.map.region(id: selectedRegionId),
           canRepairFortification(division: division, targetRegion: selectedRegion) {
            return selectedRegion
        }

        guard let currentRegion = gameState.map.region(id: divisionRegionId),
              canRepairFortification(division: division, targetRegion: currentRegion) else {
            return nil
        }
        return currentRegion
    }

    private var selectedRelieveSiegeTarget: RegionNode? {
        guard let division = selectedActionDivision else {
            return nil
        }

        if let selectedRegionId,
           let selectedRegion = gameState.map.region(id: selectedRegionId),
           canRelieveSiege(division: division, targetRegion: selectedRegion) {
            return selectedRegion
        }

        return gameState.siegeState.records
            .compactMap { gameState.map.region(id: $0.targetRegionId) }
            .filter { canRelieveSiege(division: division, targetRegion: $0) }
            .sorted { lhs, rhs in
                let lhsDistance = siegeDistance(from: division, to: lhs)
                let rhsDistance = siegeDistance(from: division, to: rhs)
                if lhsDistance != rhsDistance {
                    return lhsDistance < rhsDistance
                }
                return lhs.id.rawValue < rhs.id.rawValue
            }
            .first
    }

    private var selectedDemandSurrenderTarget: RegionNode? {
        guard let division = selectedActionDivision else {
            return nil
        }

        if let selectedRegionId,
           let selectedRegion = gameState.map.region(id: selectedRegionId),
           canDemandSurrender(division: division, targetRegion: selectedRegion) {
            return selectedRegion
        }

        return gameState.siegeState.records
            .compactMap { gameState.map.region(id: $0.targetRegionId) }
            .filter { canDemandSurrender(division: division, targetRegion: $0) }
            .sorted { lhs, rhs in
                let lhsDistance = siegeDistance(from: division, to: lhs)
                let rhsDistance = siegeDistance(from: division, to: rhs)
                if lhsDistance != rhsDistance {
                    return lhsDistance < rhsDistance
                }
                return lhs.id.rawValue < rhs.id.rawValue
            }
            .first
    }

    private var selectedSubmissionTarget: (country: CountryProfile, region: RegionNode)? {
        guard let division = selectedActionDivision else {
            return nil
        }

        if let selectedRegionId,
           let selectedRegion = gameState.map.region(id: selectedRegionId),
           let target = submissionTarget(for: division, region: selectedRegion) {
            return target
        }

        return gameState.diplomacyState.countries
            .filter { $0.faction != division.faction }
            .compactMap { country -> (country: CountryProfile, region: RegionNode)? in
                guard let capitalRegionId = country.capitalRegionId,
                      let region = gameState.map.region(id: capitalRegionId) else {
                    return nil
                }
                return submissionTarget(for: division, country: country, region: region)
            }
            .sorted {
                if $0.country.warSupport != $1.country.warSupport {
                    return $0.country.warSupport < $1.country.warSupport
                }
                return $0.country.id.rawValue < $1.country.id.rawValue
            }
            .first
    }

    private func submissionTarget(
        for division: Division,
        region: RegionNode
    ) -> (country: CountryProfile, region: RegionNode)? {
        guard let targetCountry = gameState.diplomacyState.countries.first(where: {
            $0.faction != division.faction && $0.capitalRegionId == region.id
        }) else {
            return nil
        }

        return submissionTarget(for: division, country: targetCountry, region: region)
    }

    private func submissionTarget(
        for division: Division,
        country: CountryProfile,
        region: RegionNode
    ) -> (country: CountryProfile, region: RegionNode)? {
        let command = Command.proposeSubmission(
            negotiatorId: division.id,
            targetCountryId: country.id,
            targetRegionIds: [region.id]
        )
        guard isValid(command) else {
            return nil
        }

        return (country, region)
    }

    private var canIssuePlayerDirective: Bool {
        !observerModeEnabled &&
            gameState.effectiveTurnOrderState.allowsCommands(activeFaction: playerFaction, phase: gameState.phase)
    }

    private var selectedAttackTarget: (region: RegionNode, zone: FrontZone)? {
        guard let selectedRegionId,
              let region = gameState.map.region(id: selectedRegionId),
              let targetZone = gameState.warDeploymentState.zone(for: selectedRegionId),
              warRelationRules.canTarget(attacker: playerFaction, target: targetZone.faction, in: gameState) else {
            return nil
        }
        return (region, targetZone)
    }

    private func canBesiege(division: Division, targetRegion region: RegionNode) -> Bool {
        isValid(.besiege(attackerId: division.id, targetRegionId: region.id))
    }

    private func canRepairFortification(division: Division, targetRegion region: RegionNode) -> Bool {
        isValid(.repairFortification(defenderId: division.id, targetRegionId: region.id))
    }

    private func canRelieveSiege(division: Division, targetRegion region: RegionNode) -> Bool {
        isValid(.relieveSiege(relieverId: division.id, targetRegionId: region.id))
    }

    private func canDemandSurrender(division: Division, targetRegion region: RegionNode) -> Bool {
        isValid(.demandSurrender(negotiatorId: division.id, targetRegionId: region.id))
    }

    private func siegeDistance(from division: Division, to region: RegionNode) -> Int {
        region.displayHexes
            .map { division.coord.distance(to: $0) }
            .min() ?? Int.max
    }

    private func siegeTargetName(_ region: RegionNode) -> String {
        region.city?.name ?? region.name
    }

    private func validAttackCount(for division: Division) -> Int {
        gameState.divisions.filter { target in
            attackHighlights.contains(target.coord) &&
            isValid(.attack(attackerId: division.id, targetId: target.id))
        }.count
    }

    private func validMovementCount(for division: Division) -> Int {
        movementHighlights.filter { destination in
            isValid(.move(divisionId: division.id, destination: destination))
        }.count
    }

    private func isValid(_ command: Command) -> Bool {
        CommandValidator().validate(command, in: gameState).isValid
    }

    private var mapDisplayAdapter: MapDisplayAdapter {
        MapDisplayAdapter(state: gameState, revealAll: observerModeEnabled)
    }

    private func refreshedRuntimeState(_ state: GameState) -> GameState {
        refreshGeneralAssignments(
            in: StrategicStateBootstrapper().refreshRuntimeState(state)
        )
    }

    private func refreshGeneralAssignments(in state: GameState) -> GameState {
        Self.refreshGeneralAssignments(in: state, registry: generalRegistry)
    }

    private static func refreshGeneralAssignments(
        in state: GameState,
        registry: GeneralRegistry
    ) -> GameState {
        guard !registry.allGenerals.isEmpty else {
            return state
        }
        var next = state
        next.warDeploymentState = GeneralDispatcher(registry: registry).assignGenerals(
            to: state.warDeploymentState,
            map: state.map
        )
        return next
    }

    private func applyPlayerCommandBookkeeping(
        _ command: Command,
        to state: GameState,
        previousState: GameState
    ) -> GameState {
        var next = state
        if command == .endTurn || next.activeFaction != previousState.activeFaction || next.turn != previousState.turn {
            next.playerCommandState.clearTurnLocks()
            return next
        }

        guard let divisionId = command.actingDivisionId,
              previousState.effectiveTurnOrderState.allowsCommands(activeFaction: playerFaction, phase: previousState.phase),
              previousState.division(id: divisionId)?.faction == playerFaction else {
            return next
        }

        next.playerCommandState.lockDivision(divisionId)
        return registerPlayerIntervention(for: divisionId, in: next)
    }

    private func registerPlayerIntervention(for divisionId: String, in state: GameState) -> GameState {
        guard let zoneId = logicalZoneId(for: divisionId, in: state.warDeploymentState),
              var zone = state.warDeploymentState.frontZones[zoneId],
              let assignment = zone.generalAssignment else {
            return state
        }

        var next = state
        zone.generalAssignment = assignment.registeringPlayerIntervention(cost: 2)
        next.warDeploymentState.frontZones[zoneId] = zone
        return next
    }

    private static func configuredState(_ state: GameState, playerFaction: Faction) -> GameState {
        var next = state
        let playerPowerId = playerFaction.powerId
        next.turnOrderState.playerControlledPowerIds = [playerPowerId]
        next.turnOrderState.profiles = next.turnOrderState.profiles.map { profile in
            var updated = profile
            if profile.id == playerPowerId {
                updated.controlMode = .human
            } else if profile.legacyFactionBridge != nil {
                updated.controlMode = .ai
            }
            return updated
        }
        return next
    }

    private static func playerFaction(from state: GameState) -> Faction {
        let turnOrder = state.effectiveTurnOrderState
        if let playerPowerId = turnOrder.playerControlledPowerIds.first,
           let faction = turnOrder.legacyFaction(for: playerPowerId) {
            return faction
        }
        return .allies
    }

    private func inferredPlayerCommandZone() -> FrontZone? {
        if let division = selectedDivision,
           division.faction == playerFaction,
           let zoneId = gameState.warDeploymentState.zoneId(for: division.coord, map: gameState.map),
           let zone = gameState.warDeploymentState.frontZones[zoneId],
           zone.faction == playerFaction {
            return zone
        }

        if let selectedRegionId,
           let zone = gameState.warDeploymentState.zone(for: selectedRegionId),
           zone.faction == playerFaction {
            return zone
        }

        guard let targetZone = selectedGeneralTargetZone,
              warRelationRules.canTarget(attacker: playerFaction, target: targetZone.faction, in: gameState) else {
            return nil
        }

        return playerZonesAdjacent(to: targetZone.id).first
    }

    private func playerZonesAdjacent(to targetZoneId: FrontZoneId) -> [FrontZone] {
        gameState.warDeploymentState.frontZones.values
            .filter { zone in
                zone.faction == playerFaction &&
                    zone.frontSegments.contains { $0.neighborEnemyZone == targetZoneId }
            }
            .sorted { $0.id.rawValue < $1.id.rawValue }
    }

    private func sourceRegionId(for zone: FrontZone, targetZoneId: FrontZoneId?) -> RegionId? {
        if let selectedDivision,
           selectedDivision.faction == zone.faction,
           let regionId = selectedDivision.location(in: gameState.map),
           zone.regionIds.contains(regionId) {
            return regionId
        }

        if let selectedRegionId,
           zone.regionIds.contains(selectedRegionId) {
            return selectedRegionId
        }

        if let targetZoneId,
           let segment = zone.frontSegments
            .filter({ $0.neighborEnemyZone == targetZoneId })
            .sorted(by: { $0.regionId.rawValue < $1.regionId.rawValue })
            .first {
            return segment.regionId
        }

        return zone.generalAssignment?.hqRegionId ?? zone.regionIds.first
    }

    private func logicalZoneId(for divisionId: String, in deploymentState: WarDeploymentState) -> FrontZoneId? {
        deploymentState.frontZones.values
            .sorted { $0.id.rawValue < $1.id.rawValue }
            .first {
                $0.unitsFront.contains(divisionId)
                    || $0.unitsDepth.contains(divisionId)
                    || $0.unitsGarrison.contains(divisionId)
            }?
            .id
    }

    private func submitPlayerDirective(
        _ directive: ZoneDirective,
        sourceRegionId: RegionId?,
        targetRegionId: RegionId?
    ) {
        guard canIssuePlayerDirective else {
            appendInteractionEvent("General order rejected: not in the player command phase.")
            return
        }
        guard gameState.warDeploymentState.frontZones[directive.zoneId]?.faction == playerFaction else {
            appendInteractionEvent("General order rejected: source zone is not controlled by the player.")
            return
        }

        let startState = refreshedRuntimeState(gameState)
        guard let refreshedZone = startState.warDeploymentState.frontZones[directive.zoneId],
              refreshedZone.faction == playerFaction else {
            appendInteractionEvent("General order rejected: source zone changed during refresh.")
            return
        }
        let lockedIds = startState.playerCommandState.micromanagedDivisionIds
        let execution = WarCommandExecutor(commandHandler: commandHandler).execute(
            directive,
            in: startState,
            excluding: lockedIds
        )

        var nextState = refreshGeneralAssignments(in: execution.finalState)
        let commandSummaries = execution.commandResults.enumerated().map { index, result in
            CommandResultSummary.directiveCommand(
                directiveIndex: 0,
                commandIndex: index,
                directive: directive,
                command: execution.generatedCommands[index],
                result: result,
                isTangSongScenario: startState.isTangSongScenario
            )
        }
        var diagnostics: [String] = []
        if execution.generatedCommands.isEmpty {
            diagnostics.append("Player directive generated no executable commands.")
        }
        let rejected = commandSummaries.filter { !$0.executed }
        if !rejected.isEmpty {
            diagnostics.append("\(rejected.count) command(s) were rejected by rules.")
        }
        if !lockedIds.isEmpty {
            diagnostics.append("\(lockedIds.count) micromanaged division(s) excluded.")
        }

        let record = WarDirectiveRecord(
            id: "player_directive_turn_\(startState.turn)_\(directive.zoneId.rawValue)_\(directive.type.rawValue)_\(targetRegionId?.rawValue ?? "hold")",
            issuerId: "player",
            turn: startState.turn,
            faction: playerFaction,
            zoneId: directive.zoneId,
            directiveType: directive.type,
            targetRegionIds: targetRegionId.map { [$0] } ?? directive.targetRegionIds,
            commandResults: commandSummaries,
            diagnostics: diagnostics,
            category: directive.category,
            tactic: directive.tactic,
            commanderAgentId: refreshedZone.generalAssignment?.generalId,
            commandTarget: directive.commandTarget
        )

        nextState.warDirectiveRecords.append(record)
        nextState.playerCommandState.recordOperation(
            PlayerPlannedOperation(
                id: "player_operation_turn_\(startState.turn)_\(directive.zoneId.rawValue)_\(directive.type.rawValue)_\(targetRegionId?.rawValue ?? "hold")",
                turn: startState.turn,
                zoneId: directive.zoneId,
                faction: playerFaction,
                directiveType: directive.type,
                sourceRegionId: sourceRegionId,
                targetRegionId: targetRegionId,
                createdByGeneralId: refreshedZone.generalAssignment?.generalId
            )
        )

        gameState = nextState
        lastWarDirectiveRecords = Array((lastWarDirectiveRecords + [record]).suffix(12))
        lastCommandMessage = playerDirectiveMessage(for: execution, diagnostics: diagnostics)
        appendInteractionEvent("General order submitted: \(directive.type.rawValue) \(directive.zoneId.rawValue).")
        refreshSelectionAfterStateChange()
    }

    private func playerDirectiveMessage(
        for execution: WarCommandExecutionResult,
        diagnostics: [String]
    ) -> String {
        let acceptedCount = execution.commandResults.filter(\.succeeded).count
        let totalCount = execution.generatedCommands.count
        if totalCount == 0 {
            return diagnostics.first ?? "General order produced no commands."
        }
        if acceptedCount == totalCount {
            return "General order executed \(acceptedCount) command(s)."
        }
        return "General order executed \(acceptedCount)/\(totalCount) command(s)."
    }

    private func shouldRunAI(for faction: Faction, phase: GamePhase) -> Bool {
        gameState.effectiveTurnOrderState.shouldRunAI(
            activeFaction: faction,
            phase: phase,
            observerModeEnabled: observerModeEnabled
        )
    }

    private func runAISequence(
        from state: GameState,
        pipelineMode: WarPipelineMode,
        observerEnabled: Bool
    ) async -> AgentTurnOutcome {
        var currentState = refreshedRuntimeState(state)
        var lastOutcome: AgentTurnOutcome?
        let maxSteps = observerEnabled ? 2 : 1

        for _ in 0..<maxSteps {
            currentState = refreshedRuntimeState(currentState)
            guard shouldRunAIInSnapshot(state: currentState, observerEnabled: observerEnabled) else {
                break
            }

            let manager = turnManager(for: currentState.activeFaction, state: currentState)
            let outcome = await manager.runAITurn(
                state: currentState,
                faction: currentState.activeFaction,
                pipelineMode: pipelineMode
            )
            currentState = refreshedRuntimeState(outcome.state)
            lastOutcome = AgentTurnOutcome(
                state: currentState,
                record: outcome.record,
                directiveRecords: (lastOutcome?.directiveRecords ?? []) + outcome.directiveRecords
            )
        }

        return lastOutcome ?? AgentTurnOutcome(
            state: currentState,
            record: AgentDecisionRecord(
                id: "agent_noop_turn_\(currentState.turn)",
                turn: currentState.turn,
                agentId: "system",
                provider: "System",
                contextSummary: "No AI faction was active.",
                rawJSON: nil,
                parsedIntent: nil,
                commandResults: [],
                errors: []
            )
        )
    }

    private func shouldRunAIInSnapshot(state: GameState, observerEnabled: Bool) -> Bool {
        state.effectiveTurnOrderState.shouldRunAI(
            activeFaction: state.activeFaction,
            phase: state.phase,
            observerModeEnabled: observerEnabled
        )
    }

    private func turnManager(for faction: Faction, state: GameState) -> TurnManager {
        if faction == .germany, let turnManager, generalRegistry.allGenerals.isEmpty {
            return turnManager
        }

        let agent = GameAgent.defaultCommander(for: faction, from: dataLoader, state: state)

        return TurnManager(
            agent: agent,
            provider: MockAIClient(),
            providerName: "MockAI",
            commandHandler: commandHandler,
            commanderPool: Self.buildCommanderPool(state: state, registry: generalRegistry),
            marshalAgent: Self.buildMarshalAgent(faction: faction, state: state)
        )
    }

    private static func buildCommanderPool(
        state: GameState,
        registry: GeneralRegistry = .empty
    ) -> TheaterCommanderPool {
        if !registry.allGenerals.isEmpty {
            return GeneralDispatcher(registry: registry).commanderPool(for: state)
        }

        return TheaterCommanderPool.automatic(for: state)
    }

    private static func buildMarshalAgent(faction: Faction, state: GameState) -> MarshalAgent {
        MarshalAgent(config: MarshalAgentConfig.automatic(for: faction, state: state))
    }

    private func handleDivisionTap(_ division: Division) {
        if observerModeEnabled {
            selectDivision(division)
            appendInteractionEvent("Inspecting unit: \(division.name).")
            return
        }

        if division.faction == playerFaction {
            selectDivision(division)
            appendInteractionEvent("Selected unit: \(division.name).")
            return
        }

        if let attacker = selectedActionDivision,
           warRelationRules.canTarget(attacker: attacker.faction, target: division.faction, in: gameState) {
            submit(.attack(attackerId: attacker.id, targetId: division.id))
        } else {
            selectDivision(division)
            let relationLabel = warRelationRules.canTarget(attacker: playerFaction, target: division.faction, in: gameState)
                ? "enemy"
                : "non-hostile"
            appendInteractionEvent("Selected \(relationLabel) unit: \(division.name).")
        }
    }

    private func selectDivision(_ division: Division) {
        selectedUnitId = division.id
        selectedHex = mapDisplayAdapter.unitDisplayHex(for: division) ?? division.coord
        selectedRegionId = division.location(in: gameState.map)
        refreshHighlights()
    }

    private func refreshSelectionAfterStateChange() {
        if let selectedUnitId,
           gameState.division(id: selectedUnitId) == nil {
            self.selectedUnitId = nil
        }

        if let selectedDivision {
            selectedHex = mapDisplayAdapter.unitDisplayHex(for: selectedDivision) ?? selectedDivision.coord
            selectedRegionId = selectedDivision.location(in: gameState.map)
        }

        refreshHighlights()
    }

    private func refreshHighlights() {
        guard let division = selectedActionDivision else {
            clearHighlights()
            return
        }

        movementHighlights = MovementRules().movementRange(for: division, in: gameState)
        attackHighlights = Set(
            gameState.divisions
                .filter {
                    warRelationRules.canTarget(attacker: division.faction, target: $0.faction, in: gameState) &&
                        division.coord.distance(to: $0.coord) <= division.range
                }
                .map(\.coord)
        )
    }

    private func clearHighlights() {
        movementHighlights = []
        attackHighlights = []
    }

    private func submitMove(division: Division, tappedHex: HexCoord) {
        submit(.move(divisionId: division.id, destination: tappedHex))
    }

    private func selectionMessage(for coord: HexCoord) -> String {
        guard let selectedRegionId,
              let region = gameState.map.region(id: selectedRegionId) else {
            return "Selected hex \(coord.q),\(coord.r)."
        }
        return "Selected region: \(region.name) (\(selectedRegionId.rawValue))."
    }

    private func appendInteractionEvent(_ message: String) {
        interactionLog.append(
            GameLogEntry(
                turn: gameState.turn,
                faction: gameState.activeFaction,
                phase: gameState.phase,
                message: message,
                createdAt: Date()
            )
        )

        if interactionLog.count > 80 {
            interactionLog.removeFirst(interactionLog.count - 80)
        }
    }

}
