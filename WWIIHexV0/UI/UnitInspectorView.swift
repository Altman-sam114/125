import SwiftUI

struct UnitInspectorView: View {
    let division: Division?
    let playerFaction: Faction
    let isTangSongScenario: Bool
    let factionDisplayName: (Faction) -> String
    let strategicState: UnitInspectorStrategicState?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(isTangSongScenario ? "军队详情" : "Unit Details")
                .font(.headline)

            if let division {
                unitDetails(division)
            } else {
                Text(isTangSongScenario ? "未选择军队。" : "No unit selected.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
        .background(PlatformStyles.systemBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func unitDetails(_ division: Division) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(division.name)
                .font(.subheadline.weight(.semibold))

            LabeledContent(isTangSongScenario ? "政权" : "Faction") {
                Text(factionDisplayName(division.faction))
            }

            LabeledContent(isTangSongScenario ? "指挥" : "Mode") {
                Text(commandModeText(for: division))
            }

            if let strategicState {
                LabeledContent(isTangSongScenario ? "地块" : "Hex") {
                    Text(hexCoordText(strategicState.coord))
                }

                LabeledContent(isTangSongScenario ? "州府" : "Region") {
                    Text(regionText(for: strategicState))
                }

                LabeledContent(isTangSongScenario ? "动态方面" : "Dynamic Theater") {
                    Text(theaterText(for: strategicState))
                }

                LabeledContent(isTangSongScenario ? "行营辖区" : "Front Zone") {
                    Text(frontZoneText(for: strategicState))
                }

                LabeledContent(isTangSongScenario ? "军位" : "Deployment") {
                    Text(strategicState.deploymentRole.displayName(isTangSongScenario: isTangSongScenario))
                }

                LabeledContent(isTangSongScenario ? "敌我接触" : "Front Lines") {
                    Text(frontLineSummary(strategicState.frontLineIds))
                        .multilineTextAlignment(.trailing)
                }

                LabeledContent(strategicState.isTangSongScenario ? "粮道" : "Supply Line") {
                    Text(
                        supplyRouteSummary(
                            strategicState.supplyRouteSummary,
                            sourceName: strategicState.supplySourceName,
                            isTangSongScenario: strategicState.isTangSongScenario
                        )
                    )
                        .multilineTextAlignment(.trailing)
                }
            }

            LabeledContent(isTangSongScenario ? "兵力" : "Strength") {
                Text(division.inspectorStrengthText(isTangSongScenario: isTangSongScenario))
            }

            LabeledContent(isTangSongScenario ? "退却口径" : "Retreat Mode") {
                Text(division.retreatMode.displayName(isTangSongScenario: isTangSongScenario))
            }

            LabeledContent(isTangSongScenario ? "补给" : "Supply") {
                Text(division.supplyState.displayName(isTangSongScenario: isTangSongScenario))
            }

            LabeledContent(isTangSongScenario ? "本回合" : "Has Acted") {
                Text(division.hasActed ? actedYesText : actedNoText)
            }

            LabeledContent(isTangSongScenario ? "状态" : "Status") {
                Text(division.inspectorStatusText(isTangSongScenario: isTangSongScenario))
            }

            LabeledContent(isTangSongScenario ? "编成" : "Components") {
                Text(componentSummary(for: division))
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    private func componentSummary(for division: Division) -> String {
        division.components
            .map { componentText(type: $0.type, weight: $0.weight) }
            .joined(separator: isTangSongScenario ? "、" : " / ")
    }

    private func componentText(type: ComponentType, weight: Double) -> String {
        let percentage = Int((weight * 100).rounded())
        if isTangSongScenario {
            return "\(type.displayCode(isTangSongScenario: true))占 \(percentage)／100"
        }
        return "\(type.displayCode(isTangSongScenario: false)) \(percentage)%"
    }

    private func frontLineSummary(_ ids: [FrontLineId]) -> String {
        if isTangSongScenario {
            return ids.isEmpty ? noneText : "接触州府 \(ids.count) 处"
        }
        return ids.isEmpty ? noneText : ids.map(\.rawValue).joined(separator: ", ")
    }

    private func regionText(for state: UnitInspectorStrategicState) -> String {
        if isTangSongScenario {
            return state.regionName ?? (state.regionId == nil ? noneText : "未知州府")
        }
        return state.regionName ?? state.regionId?.rawValue ?? noneText
    }

    private func theaterText(for state: UnitInspectorStrategicState) -> String {
        if isTangSongScenario {
            return state.dynamicTheaterName ?? (state.dynamicTheaterId == nil ? noneText : "未命名方面")
        }
        return state.dynamicTheaterName ?? state.dynamicTheaterId?.rawValue ?? noneText
    }

    private func frontZoneText(for state: UnitInspectorStrategicState) -> String {
        if isTangSongScenario {
            return state.frontZoneName ?? (state.frontZoneId == nil ? noneText : "未命名防区")
        }
        return state.frontZoneName ?? state.frontZoneId?.rawValue ?? noneText
    }

    private func supplyRouteSummary(
        _ summary: SupplyRouteSummary,
        sourceName: String?,
        isTangSongScenario: Bool
    ) -> String {
        let sourceName = sourceName
            ?? summary.nearestSourceId.map { isTangSongScenario ? "补给源" : $0 }
            ?? noneText
        let sourceCoord = summary.nearestSourceCoord.map {
            isTangSongScenario ? "第 \($0.q) 列，第 \($0.r) 行" : "(\($0.q),\($0.r))"
        } ?? ""

        if isTangSongScenario {
            if let pathCost = summary.pathCost {
                return "通 \(pathCost)／\(summary.maxPathCost) 至 \(sourceName) \(sourceCoord)"
            }
            return "断；近源 \(sourceName) \(sourceCoord)，退路 \(summary.safeRetreatExitCount)"
        }

        if let pathCost = summary.pathCost {
            return "Open \(pathCost)/\(summary.maxPathCost) to \(sourceName) \(sourceCoord)"
        }
        return "Cut; nearest \(sourceName) \(sourceCoord), exits \(summary.safeRetreatExitCount)"
    }

    private func commandModeText(for division: Division) -> String {
        if isTangSongScenario {
            return division.faction == playerFaction ? "玩家亲征" : "只读查看"
        }
        return division.faction == playerFaction ? "Player" : "Read-only"
    }

    private func hexCoordText(_ coord: HexCoord) -> String {
        isTangSongScenario ? "第 \(coord.q) 列，第 \(coord.r) 行" : "\(coord.q),\(coord.r)"
    }

    private var noneText: String {
        isTangSongScenario ? "无" : "None"
    }

    private var actedYesText: String {
        isTangSongScenario ? "已行动" : "Yes"
    }

    private var actedNoText: String {
        isTangSongScenario ? "未行动" : "No"
    }
}

private extension Division {
    func inspectorStrengthText(isTangSongScenario: Bool) -> String {
        isTangSongScenario ? "\(strength)／\(maxStrength)" : "\(strength) / \(maxStrength)"
    }

    func inspectorStatusText(isTangSongScenario: Bool) -> String {
        var statuses: [String] = []

        if isRetreating {
            statuses.append(isTangSongScenario ? "退却中" : "Retreating")
        }

        if isDestroyed {
            statuses.append(isTangSongScenario ? "溃散" : "Destroyed")
        }

        let separator = isTangSongScenario ? "、" : ", "
        return statuses.isEmpty ? (isTangSongScenario ? "可行动" : "Ready") : statuses.joined(separator: separator)
    }
}

private extension RetreatMode {
    func displayName(isTangSongScenario: Bool) -> String {
        if isTangSongScenario {
            switch self {
            case .retreatable:
                return "准许退却"
            case .hold:
                return "死守"
            }
        }

        switch self {
        case .retreatable:
            return "Retreatable"
        case .hold:
            return "Hold"
        }
    }
}

private extension ComponentType {
    func displayCode(isTangSongScenario: Bool) -> String {
        if isTangSongScenario {
            switch self {
            case .tank:
                return "禁军"
            case .motorizedInfantry:
                return "骑军"
            case .infantry:
                return "厢军"
            case .artillery:
                return "器械"
            }
        }

        switch self {
        case .tank:
            return "ARM"
        case .motorizedInfantry:
            return "MOT"
        case .infantry:
            return "INF"
        case .artillery:
            return "ART"
        }
    }
}

private extension SupplyState {
    func displayName(isTangSongScenario: Bool) -> String {
        if isTangSongScenario {
            switch self {
            case .supplied:
                return "粮道通"
            case .lowSupply:
                return "粮草紧"
            case .encircled:
                return "断粮被围"
            }
        }

        switch self {
        case .supplied:
            return "Supplied"
        case .lowSupply:
            return "Low Supply"
        case .encircled:
            return "Encircled"
        }
    }
}

private extension UnitDeploymentRole {
    func displayName(isTangSongScenario: Bool) -> String {
        if isTangSongScenario {
            switch self {
            case .frontUnit:
                return "前锋"
            case .depthUnit:
                return "行营后备"
            case .garrisonUnit:
                return "州府守备"
            }
        }

        switch self {
        case .frontUnit:
            return "Front"
        case .depthUnit:
            return "Depth"
        case .garrisonUnit:
            return "Garrison"
        }
    }
}


private extension Set where Element == HexDirection {
    var displaySummary: String {
        HexDirection.ordered
            .filter { contains($0) }
            .map(\.displayCode)
            .joined(separator: ", ")
    }
}

private extension HexDirection {
    var displayCode: String {
        switch self {
        case .east:
            return "E"
        case .northEast:
            return "NE"
        case .northWest:
            return "NW"
        case .west:
            return "W"
        case .southWest:
            return "SW"
        case .southEast:
            return "SE"
        }
    }
}
