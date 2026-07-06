import SwiftUI

struct RootGameView: View {
    @ObservedObject var container: AppContainer
    @State private var selectedCompactPanel: CompactInfoPanel = .unit
    @State private var isInfoExpanded = false
    @State private var isGeneralProfilePresented = false

    var body: some View {
        GeometryReader { proxy in
            let isLandscape = proxy.size.width > proxy.size.height
            let isTangSongScenario = container.gameState.isTangSongScenario

            ZStack(alignment: .bottomTrailing) {
                boardView
                    .ignoresSafeArea()

                VStack {
                    HUDView(
                        gameState: container.gameState,
                        nextActionHint: nextActionHint,
                        onFocusObjective: container.focusObjective(id:),
                        onEndTurn: container.advanceOrRunAI,
                        onNewGame: container.resetGame
                    )
                    .padding(8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .padding(.top, 8)
                    .padding(.horizontal, 8)

                    Picker(isTangSongScenario ? "图层" : "Map Layer", selection: Binding(
                        get: { container.mapDisplayLayer },
                        set: { container.setMapDisplayLayer($0) }
                    )) {
                        ForEach(MapDisplayLayer.allCases) { layer in
                            Text(layer.displayName(isTangSongScenario: isTangSongScenario)).tag(layer)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal, 8)

                    Toggle(isTangSongScenario ? "观战" : "Observer", isOn: Binding(
                        get: { container.observerModeEnabled },
                        set: { container.setObserverModeEnabled($0) }
                    ))
                    .toggleStyle(.button)
                    .font(.caption.weight(.semibold))
                    .padding(8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal, 8)

                    Spacer()
                }

                if isInfoExpanded {
                    infoOverlay(isLandscape: isLandscape, size: proxy.size)
                        .transition(.opacity)
                }

                Button {
                    isInfoExpanded.toggle()
                } label: {
                    Label(isTangSongScenario ? "面板" : "Info", systemImage: "sidebar.left")
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(10)

                UnitTooltipView(division: container.selectedDivision)
                    .allowsHitTesting(false)
            }
        }
        .background(PlatformStyles.systemBackground)
        .sheet(isPresented: $isGeneralProfilePresented) {
            if let general = container.selectedGeneral {
                GeneralProfileView(
                    general: general,
                    assignment: container.selectedGeneralAssignment,
                    zone: container.selectedGeneralCommandZone,
                    assignedDivisions: container.selectedGeneralAssignedDivisions,
                    hqUnderAttack: container.selectedGeneralHQUnderAttack,
                    onClose: { isGeneralProfilePresented = false }
                )
            } else {
                Text(container.gameState.isTangSongScenario ? "未选择将领。" : "No general selected.")
                    .font(.headline)
                    .padding()
            }
        }
    }

    private var boardView: some View {
        BoardSceneView(
            renderState: BoardSceneAdapter.renderState(from: container),
            onHexTapped: container.handleBoardTap
        )
        .accessibilityLabel(boardAccessibilityLabel)
    }

    private var nextActionHint: String? {
        guard container.gameState.isTangSongScenario else {
            return nil
        }

        if container.gameState.victoryState.winner != nil {
            return "打开战报查看胜负原因、目标进度和最近战事，再决定是否新开一局。"
        }

        if container.observerModeEnabled {
            return "观战模式下不会下令；可切回指挥后选择宋军，或继续结束回合观察各方行动。"
        }

        let commandsAllowed = container.gameState.effectiveTurnOrderState.allowsCommands(
            activeFaction: container.playerFaction,
            phase: container.gameState.phase
        )

        guard commandsAllowed,
              container.gameState.activeFaction == container.playerFaction else {
            return "当前是\(container.gameState.phaseDisplayName)，可点结束回合推进到可下令阶段。"
        }

        guard let selectedDivision = container.selectedDivision else {
            return "先点选一支宋军，再用军令面板行军、围城、整补或招抚；也可查看州府与统一进度。"
        }

        guard selectedDivision.faction == container.playerFaction else {
            return "已选中敌军；改选宋军下令，或打开州府/战报面板判断下一处目标。"
        }

        if selectedDivision.hasActed {
            return "该军本回合已行动；继续选择其他未行动宋军，或结束回合让 AI 推进。"
        }

        if let targetName = container.selectedDemandSurrenderTargetName {
            return "可对\(targetName)招降，优先把已破城防且断粮的围城结果落地。"
        }

        if let targetName = container.selectedBesiegeTargetName {
            return "可围城\(targetName)，持续压低城防与粮道，为后续招降或占领创造条件。"
        }

        if let targetName = container.selectedSubmissionTargetName {
            return "可尝试招抚\(targetName)，以天命和外交推进统一，不必只靠攻城。"
        }

        if let targetName = container.selectedRelieveSiegeTargetName {
            return "可驰援\(targetName)解围，先保住己方州府和粮道。"
        }

        if let targetName = container.selectedRepairFortificationTargetName {
            return "可在\(targetName)修城，提升城防后再安排其他军队反击或整补。"
        }

        return "该军可行动；点击相邻敌军或敌控州府寻找进攻目标，或先固守、整补稳定粮道。"
    }

    private func infoOverlay(isLandscape: Bool, size: CGSize) -> some View {
        let width = isLandscape ? min(max(size.width * 0.32, 260), 360) : size.width
        let height = isLandscape ? size.height : min(max(size.height * 0.44, 320), 460)

        return VStack(spacing: 0) {
            compactPanelWithTabs
        }
        .frame(width: width, height: height)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.secondary.opacity(0.35), lineWidth: 1)
        }
        .padding(isLandscape ? 10 : 0)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: isLandscape ? .trailing : .bottom
        )
    }

    private var compactPanelWithTabs: some View {
        VStack(spacing: 0) {
            Picker(container.gameState.isTangSongScenario ? "面板" : "Panel", selection: $selectedCompactPanel) {
                ForEach(CompactInfoPanel.allCases) { panel in
                    Text(panel.displayName(isTangSongScenario: container.gameState.isTangSongScenario)).tag(panel)
                }
            }
            .pickerStyle(.segmented)
            .padding(8)

            compactPanel
        }
    }

    @ViewBuilder
    private var compactPanel: some View {
        ScrollView {
            VStack(spacing: 10) {
                switch selectedCompactPanel {
                case .unit:
                    UnitInspectorView(
                        division: container.selectedDivision,
                        playerFaction: container.playerFaction,
                        strategicState: container.selectedUnitInspectorStrategicState
                    )
                    RegionInspectorView(inspectorState: container.selectedRegionInspectorState)
                    CommandPanelView(
                        selectedDivision: container.selectedDivision,
                        activeFaction: container.gameState.activeFaction,
                        phase: container.gameState.phase,
                        playerFaction: container.playerFaction,
                        observerModeEnabled: container.observerModeEnabled,
                        commandsAllowed: container.gameState.effectiveTurnOrderState.allowsCommands(
                            activeFaction: container.playerFaction,
                            phase: container.gameState.phase
                        ),
                        phaseDisplayName: container.gameState.phaseDisplayName,
                        lastCommandMessage: container.lastCommandMessage,
                        isTangSongScenario: container.gameState.isTangSongScenario,
                        besiegeTargetName: container.selectedBesiegeTargetName,
                        repairFortificationTargetName: container.selectedRepairFortificationTargetName,
                        relieveSiegeTargetName: container.selectedRelieveSiegeTargetName,
                        demandSurrenderTargetName: container.selectedDemandSurrenderTargetName,
                        submissionTargetName: container.selectedSubmissionTargetName,
                        onHold: container.holdSelected,
                        onAllowRetreat: container.allowRetreatSelected,
                        onResupply: container.resupplySelected,
                        onBesiege: container.besiegeSelected,
                        onRepairFortification: container.repairFortificationSelected,
                        onRelieveSiege: container.relieveSiegeSelected,
                        onDemandSurrender: container.demandSurrenderSelected,
                        onProposeSubmission: container.proposeSubmissionSelected,
                        onEndTurn: container.advanceOrRunAI
                    )
                    GeneralCommandPanelView(
                        zone: container.selectedGeneralCommandZone,
                        general: container.selectedGeneral,
                        assignment: container.selectedGeneralAssignment,
                        assignedDivisions: container.selectedGeneralAssignedDivisions,
                        targetRegion: container.selectedGeneralTargetRegion,
                        targetZone: container.selectedGeneralTargetZone,
                        hqUnderAttack: container.selectedGeneralHQUnderAttack,
                        plannedOperations: container.selectedGeneralPlannedOperations,
                        canHoldLine: container.canOrderSelectedGeneralHoldLine,
                        canAttackRegion: container.canOrderSelectedGeneralAttackRegion,
                        onShowProfile: { isGeneralProfilePresented = true },
                        onHoldLine: container.orderSelectedGeneralHoldLine,
                        onAttackRegion: container.orderSelectedGeneralAttackRegion
                    )
                case .region:
                    RegionInspectorView(inspectorState: container.selectedRegionInspectorState)
                case .general:
                    GeneralCommandPanelView(
                        zone: container.selectedGeneralCommandZone,
                        general: container.selectedGeneral,
                        assignment: container.selectedGeneralAssignment,
                        assignedDivisions: container.selectedGeneralAssignedDivisions,
                        targetRegion: container.selectedGeneralTargetRegion,
                        targetZone: container.selectedGeneralTargetZone,
                        hqUnderAttack: container.selectedGeneralHQUnderAttack,
                        plannedOperations: container.selectedGeneralPlannedOperations,
                        canHoldLine: container.canOrderSelectedGeneralHoldLine,
                        canAttackRegion: container.canOrderSelectedGeneralAttackRegion,
                        onShowProfile: { isGeneralProfilePresented = true },
                        onHoldLine: container.orderSelectedGeneralHoldLine,
                        onAttackRegion: container.orderSelectedGeneralAttackRegion
                    )
                case .log:
                    EventLogView(
                        entries: container.displayEventLog,
                        summaryEntries: container.gameState.eventLog,
                        agentDecisionRecord: container.lastAgentDecisionRecord,
                        directiveRecords: container.gameState.warDirectiveRecords,
                        victoryState: container.gameState.victoryState,
                        objectiveProgress: VictoryRules().objectiveProgress(in: container.gameState),
                        currentTurn: container.gameState.turn,
                        isTangSongScenario: container.gameState.isTangSongScenario,
                        factionDisplayName: { container.gameState.displayName(for: $0) }
                    )
                case .economy:
                    EconomyPanelView(
                        gameState: container.gameState,
                        playerFaction: container.playerFaction,
                        observerModeEnabled: container.observerModeEnabled,
                        onQueueProduction: container.queueProduction
                    )
                case .diplomacy:
                    DiplomacyPanelView(
                        diplomacyState: container.gameState.diplomacyState,
                        activeFaction: container.gameState.activeFaction,
                        mandateState: container.gameState.mandateState,
                        isTangSongScenario: container.gameState.isTangSongScenario,
                        factionDisplayName: { container.gameState.displayName(for: $0) }
                    )
                case .agent:
                    AgentPanelView(
                        record: container.lastAgentDecisionRecord,
                        rulerRecord: container.gameState.diplomacyState.latestRulerRecord,
                        directiveRecords: container.lastWarDirectiveRecords,
                        isTangSongScenario: container.gameState.isTangSongScenario
                    )
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 10)
        }
    }

    private var boardAccessibilityLabel: String {
        if container.gameState.isTangSongScenario {
            return "\(container.gameState.scenarioDisplayName) 六角地图"
        }
        return "\(container.gameState.scenarioDisplayName) hex board"
    }
}

private enum CompactInfoPanel: String, CaseIterable, Identifiable {
    case unit = "Unit"
    case region = "Region"
    case general = "General"
    case log = "Log"
    case economy = "Economy"
    case diplomacy = "Diplomacy"
    case agent = "AI"

    var id: String {
        rawValue
    }

    func displayName(isTangSongScenario: Bool) -> String {
        if isTangSongScenario {
            switch self {
            case .unit:
                return "军队"
            case .region:
                return "州府"
            case .general:
                return "将领"
            case .log:
                return "战报"
            case .economy:
                return "府库"
            case .diplomacy:
                return "外交"
            case .agent:
                return "军议"
            }
        }
        return rawValue
    }
}
