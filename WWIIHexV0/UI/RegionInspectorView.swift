import SwiftUI

struct RegionInspectorView: View {
    let inspectorState: RegionInspectorState?
    let isTangSongScenario: Bool
    let factionDisplayName: (Faction) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(isTangSongScenario ? "州府详情" : "Region")
                .font(.headline)

            if let inspectorState {
                regionDetails(inspectorState)
            } else {
                Text(isTangSongScenario ? "未选择州府。" : "No region selected.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
        .background(PlatformStyles.systemBackground)
        .clipShape(.rect(cornerRadius: 8))
    }

    private func regionDetails(_ state: RegionInspectorState) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(state.region.name)
                .font(.subheadline.weight(.semibold))

            if let selectedHex = state.selectedHex {
                LabeledContent(isTangSongScenario ? "地块" : "Hex") {
                    Text(hexCoordText(selectedHex))
                }

                LabeledContent(isTangSongScenario ? "地块控制" : "Hex Controller") {
                    Text(state.selectedHexController.map(factionDisplayName) ?? noneText)
                }

                LabeledContent(isTangSongScenario ? "动态方面" : "Hex Dynamic Theater") {
                    Text(selectedHexTheaterText(for: state))
                }

                LabeledContent(isTangSongScenario ? "防区" : "Hex Front Zone") {
                    Text(selectedHexFrontZoneText(for: state))
                }
            }

            LabeledContent(isTangSongScenario ? "控制政权" : "Controller") {
                Text(factionDisplayName(state.region.controller))
            }

            LabeledContent(isTangSongScenario ? "地形" : "Terrain") {
                Text(terrainName(state.region.terrain))
            }

            LabeledContent(isTangSongScenario ? "城池" : "City") {
                Text(state.region.city?.name ?? noneText)
            }

            LabeledContent(isTangSongScenario ? "城级" : "City Level") {
                Text(cityLevelName(state.cityLevel))
            }

            LabeledContent(isTangSongScenario ? "关隘" : "Fortress") {
                Text(state.region.terrain == .fortress ? yesText : noText)
            }

            LabeledContent(isTangSongScenario ? "粮草" : "Supply") {
                Text("\(state.region.supplyValue)")
            }

            LabeledContent(isTangSongScenario ? "围城" : "Siege") {
                Text(siegeSummary(state.siegeRecord))
                    .multilineTextAlignment(.trailing)
            }

            LabeledContent(isTangSongScenario ? "工坊" : "Factories") {
                Text("\(state.region.factories)")
            }

            LabeledContent(isTangSongScenario ? "产出" : "Output") {
                Text(economicOutputText(state.economicOutput))
                    .multilineTextAlignment(.trailing)
            }

            LabeledContent(isTangSongScenario ? "方面" : "Theater") {
                Text(theaterText(for: state))
            }

            LabeledContent(isTangSongScenario ? "行营辖区" : "Front Zone") {
                Text(frontZoneText(for: state))
            }

            LabeledContent(isTangSongScenario ? "接触压力" : "Front Pressure") {
                Text(state.frontPressure, format: .number.precision(.fractionLength(2)))
            }

            LabeledContent(isTangSongScenario ? "道路" : "Infrastructure") {
                Text("\(state.region.infrastructure)")
            }

            LabeledContent(isTangSongScenario ? "目标" : "Objectives") {
                Text(state.objectiveNames.isEmpty ? noneText : state.objectiveNames.joined(separator: listSeparator))
                    .multilineTextAlignment(.trailing)
            }

            LabeledContent(isTangSongScenario ? "目标状态" : "Objective Status") {
                Text(state.objectiveStatus)
            }

            LabeledContent(isTangSongScenario ? "己方军队" : "Friendly Units") {
                Text(unitNames(state.friendlyDivisions))
                    .multilineTextAlignment(.trailing)
            }

            LabeledContent(isTangSongScenario ? "可见敌军" : "Visible Enemies") {
                Text(unitNames(state.visibleEnemyDivisions))
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    private func unitNames(_ divisions: [Division]) -> String {
        guard !divisions.isEmpty else {
            return noneText
        }
        return divisions.map(\.name).joined(separator: listSeparator)
    }

    private func hexCoordText(_ coord: HexCoord) -> String {
        isTangSongScenario ? "第 \(coord.q) 列，第 \(coord.r) 行" : "\(coord.q),\(coord.r)"
    }

    private func selectedHexTheaterText(for state: RegionInspectorState) -> String {
        if isTangSongScenario {
            return state.selectedHexDynamicTheaterName
                ?? (state.selectedHexDynamicTheaterId == nil ? noneText : "未命名方面")
        }
        return state.selectedHexDynamicTheaterName ?? state.selectedHexDynamicTheaterId?.rawValue ?? noneText
    }

    private func selectedHexFrontZoneText(for state: RegionInspectorState) -> String {
        if isTangSongScenario {
            return state.selectedHexFrontZoneName
                ?? (state.selectedHexFrontZoneId == nil ? noneText : "未命名防区")
        }
        return state.selectedHexFrontZoneName ?? state.selectedHexFrontZoneId?.rawValue ?? noneText
    }

    private func theaterText(for state: RegionInspectorState) -> String {
        if isTangSongScenario {
            return state.theaterName ?? (state.theaterId == nil ? noneText : "未命名方面")
        }
        return state.theaterName ?? state.theaterId?.rawValue ?? noneText
    }

    private func frontZoneText(for state: RegionInspectorState) -> String {
        if isTangSongScenario {
            return state.frontZoneName ?? (state.frontZoneId == nil ? noneText : "未命名防区")
        }
        return state.frontZoneName ?? state.frontZoneId?.rawValue ?? noneText
    }

    private func siegeSummary(_ record: SiegeRecord?) -> String {
        guard let record else {
            return noneText
        }

        if isTangSongScenario {
            return "攻方 \(factionDisplayName(record.attackerFaction))，守方 \(factionDisplayName(record.defenderFaction))，压力 \(record.pressure)，城防 \(record.fortification)／\(record.maxFortification)，围城军队 \(record.besiegingDivisionIds.count) 支"
        }

        return "Pressure \(record.pressure), fortification \(record.fortification)/\(record.maxFortification), \(factionDisplayName(record.attackerFaction)) -> \(factionDisplayName(record.defenderFaction)), \(record.besiegingDivisionIds.count) unit(s)"
    }

    private func economicOutputText(_ output: EconomyResources) -> String {
        if isTangSongScenario {
            return "丁口 \(output.manpower)，钱帛 \(output.industry)，粮草 \(output.supplies)"
        }
        return "Manpower \(output.manpower), Industry \(output.industry), Supplies \(output.supplies)"
    }

    private func terrainName(_ terrain: BaseTerrain) -> String {
        guard isTangSongScenario else {
            return terrain.displayName
        }

        switch terrain {
        case .plain:
            return "平原"
        case .forest:
            return "山林"
        case .mountain:
            return "山地"
        case .hill:
            return "丘陵"
        case .city:
            return "城池"
        case .fortress:
            return "关隘"
        }
    }

    private func cityLevelName(_ level: CityLevel) -> String {
        guard isTangSongScenario else {
            return level.displayName
        }

        switch level {
        case .none:
            return "无"
        case .village:
            return "县镇"
        case .town:
            return "州府"
        case .metropolis:
            return "都城"
        }
    }

    private var noneText: String {
        isTangSongScenario ? "无" : "None"
    }

    private var yesText: String {
        isTangSongScenario ? "是" : "Yes"
    }

    private var noText: String {
        isTangSongScenario ? "否" : "No"
    }

    private var listSeparator: String {
        isTangSongScenario ? "、" : ", "
    }
}
