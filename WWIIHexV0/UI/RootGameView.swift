import SwiftUI

struct RootGameView: View {
    @ObservedObject var container: AppContainer
    @State private var selectedCompactPanel: CompactInfoPanel = .unit
    @State private var isInfoExpanded = false
    @State private var isGeneralProfilePresented = false
    @State private var isNewGameConfirmationPresented = false

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
                        playerFaction: container.playerFaction,
                        observerModeEnabled: container.observerModeEnabled,
                        nextActionHint: nextActionHint,
                        onFocusObjective: container.focusObjective(id:),
                        onEndTurn: container.advanceOrRunAI,
                        onNewGame: {
                            if isTangSongScenario {
                                isNewGameConfirmationPresented = true
                            } else {
                                container.resetGame()
                            }
                        }
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

                    if isTangSongScenario {
                        HStack(spacing: 8) {
                            Picker("亲征", selection: Binding(
                                get: { container.playerFaction },
                                set: { container.setPlayerFaction($0) }
                            )) {
                                ForEach(Faction.allCases, id: \.self) { faction in
                                    Text(container.gameState.displayName(for: faction)).tag(faction)
                                }
                            }
                            .pickerStyle(.segmented)
                            .accessibilityValue(container.gameState.displayName(for: container.playerFaction))
                            .accessibilityHint("切换当前亲征政权；切换后会清空当前选中军队和高亮。")

                            Toggle("观战", isOn: Binding(
                                get: { container.observerModeEnabled },
                                set: { container.setObserverModeEnabled($0) }
                            ))
                            .toggleStyle(.button)
                            .accessibilityValue(container.observerModeEnabled ? "已开启" : "已关闭")
                            .accessibilityHint(container.observerModeEnabled ? "当前只能查看战局，不能下令；关闭后恢复亲征指挥。" : "开启后进入只读观战，军令和府库命令会停用。")
                            .font(.caption.weight(.semibold))
                        }
                        .padding(8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal, 8)
                    } else {
                        Toggle("Observer", isOn: Binding(
                            get: { container.observerModeEnabled },
                            set: { container.setObserverModeEnabled($0) }
                        ))
                        .toggleStyle(.button)
                        .accessibilityValue(container.observerModeEnabled ? "Enabled" : "Disabled")
                        .accessibilityHint(container.observerModeEnabled ? "Observer mode is read-only." : "Enable read-only observer mode.")
                        .font(.caption.weight(.semibold))
                        .padding(8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal, 8)
                    }

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
                .accessibilityLabel(isTangSongScenario ? "信息面板" : "Info panel")
                .accessibilityValue(isInfoExpanded ? (isTangSongScenario ? "已展开" : "Expanded") : (isTangSongScenario ? "已收起" : "Collapsed"))
                .accessibilityHint(isTangSongScenario ? "切换军队、州府、将领、战报、府库、外交和军议面板。" : "Toggles the compact info panel.")
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(10)

                UnitTooltipView(
                    division: container.selectedDivision,
                    isTangSongScenario: isTangSongScenario
                )
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
                    isTangSongScenario: container.gameState.isTangSongScenario,
                    factionDisplayName: { container.gameState.displayName(for: $0) },
                    onClose: { isGeneralProfilePresented = false }
                )
            } else {
                Text(container.gameState.isTangSongScenario ? "未选择将领。" : "No general selected.")
                    .font(.headline)
                    .padding()
            }
        }
        .confirmationDialog(
            "重开建隆剧本？",
            isPresented: $isNewGameConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("重开剧本", role: .destructive) {
                container.resetGame()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("将清空当前选中、交互战报和本局进度，重新载入建隆元年剧本。")
        }
    }

    private var boardView: some View {
        BoardSceneView(
            renderState: BoardSceneAdapter.renderState(from: container),
            onHexTapped: container.handleBoardTap
        )
        .accessibilityLabel(boardAccessibilityLabel)
        .accessibilityValue(boardAccessibilityValue)
        .accessibilityHint(boardAccessibilityHint)
    }

    private var nextActionHint: String? {
        guard container.gameState.isTangSongScenario else {
            return nil
        }

        if container.gameState.victoryState.winner != nil {
            return "打开战报查看胜负原因、目标进度和最近战事，再决定是否新开一局。"
        }

        let playerName = container.gameState.displayName(for: container.playerFaction)

        if container.observerModeEnabled {
            return "观战模式下不会下令；可切回指挥后选择\(playerName)军队，或继续结束回合观察各方行动。"
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
            return "先点选一支\(playerName)军队，再用军令面板行军、围城、整补或招抚；也可查看州府与统一进度。"
        }

        guard selectedDivision.faction == container.playerFaction else {
            return "已选中非亲征军队；改选\(playerName)军队下令，或打开州府/战报面板判断下一处目标。"
        }

        if selectedDivision.hasActed {
            return "该军本回合已行动；继续选择其他未行动\(playerName)军队，或结束回合让各方军议推进。"
        }

        if let validatedHint = container.selectedValidatedCommandHint {
            return "\(validatedHint) 可通过地图或军令入口执行；提示只读校验，不会提前下令。"
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

        let attackCount = container.attackHighlights.count
        let movementCount = container.movementHighlights.count
        if attackCount > 0 && movementCount > 0 {
            return "该军可行动；当前有 \(attackCount) 个可攻击目标、\(movementCount) 处可行军格，优先处理红色目标或沿高亮格推进。"
        }
        if attackCount > 0 {
            return "该军可行动；当前有 \(attackCount) 个可攻击目标，可先打击红色目标，也可固守等待战线变化。"
        }
        if movementCount > 0 {
            return "该军可行动；当前有 \(movementCount) 处可行军格，可沿高亮格靠近待取州府、粮道或围城目标。"
        }
        return "该军暂无可攻击目标或可行军格；可先固守、整补，或改选其他未行动\(playerName)军队。"
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
                        isTangSongScenario: container.gameState.isTangSongScenario,
                        factionDisplayName: { container.gameState.displayName(for: $0) },
                        strategicState: container.selectedUnitInspectorStrategicState
                    )
                    RegionInspectorView(
                        inspectorState: container.selectedRegionInspectorState,
                        isTangSongScenario: container.gameState.isTangSongScenario,
                        factionDisplayName: { container.gameState.displayName(for: $0) }
                    )
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
                        isTangSongScenario: container.gameState.isTangSongScenario,
                        regionDisplayName: { regionId in
                            container.gameState.map.regions[regionId]?.name ?? "未命名州府"
                        },
                        zoneDisplayName: { zoneId in
                            container.gameState.warDeploymentState.frontZones[zoneId]?.name ?? "未命名方面"
                        },
                        canHoldLine: container.canOrderSelectedGeneralHoldLine,
                        canAttackRegion: container.canOrderSelectedGeneralAttackRegion,
                        onShowProfile: { isGeneralProfilePresented = true },
                        onHoldLine: container.orderSelectedGeneralHoldLine,
                        onAttackRegion: container.orderSelectedGeneralAttackRegion
                    )
                case .region:
                    RegionInspectorView(
                        inspectorState: container.selectedRegionInspectorState,
                        isTangSongScenario: container.gameState.isTangSongScenario,
                        factionDisplayName: { container.gameState.displayName(for: $0) }
                    )
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
                        isTangSongScenario: container.gameState.isTangSongScenario,
                        regionDisplayName: { regionId in
                            container.gameState.map.regions[regionId]?.name ?? "未命名州府"
                        },
                        zoneDisplayName: { zoneId in
                            container.gameState.warDeploymentState.frontZones[zoneId]?.name ?? "未命名方面"
                        },
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
                        factionDisplayName: { container.gameState.displayName(for: $0) },
                        regionDisplayName: { regionId in
                            container.gameState.map.regions[regionId]?.name ?? regionId.rawValue
                        },
                        zoneDisplayName: { zoneId in
                            container.gameState.warDeploymentState.frontZones[zoneId]?.name ?? zoneId.rawValue
                        }
                    )
                case .agent:
                    AgentPanelView(
                        record: container.lastAgentDecisionRecord,
                        rulerRecord: container.gameState.diplomacyState.latestRulerRecord,
                        directiveRecords: container.lastWarDirectiveRecords,
                        isTangSongScenario: container.gameState.isTangSongScenario,
                        regionDisplayName: { regionId in
                            container.gameState.map.regions[regionId]?.name ?? regionId.rawValue
                        },
                        zoneDisplayName: { zoneId in
                            container.gameState.warDeploymentState.frontZones[zoneId]?.name ?? zoneId.rawValue
                        }
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

    private var boardAccessibilityValue: String {
        guard let selectedHex = container.selectedHex else {
            return container.gameState.isTangSongScenario ? "尚未选中地块" : "No hex selected"
        }

        if container.gameState.isTangSongScenario {
            let coordText = "第 \(selectedHex.q) 列，第 \(selectedHex.r) 行"
            let regionName = container.selectedRegionId.flatMap { container.gameState.map.regions[$0]?.name }
            if let regionName {
                return "已选中\(coordText)，\(regionName)"
            }
            return "已选中\(coordText)"
        }

        return "Selected hex \(selectedHex.q), \(selectedHex.r)"
    }

    private var boardAccessibilityHint: String {
        if container.gameState.isTangSongScenario {
            return "点按地图选择地块、军队或可行军目标；打开信息面板查看当前州府与军令。"
        }
        return "Tap the board to select hexes, units, or available targets."
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
