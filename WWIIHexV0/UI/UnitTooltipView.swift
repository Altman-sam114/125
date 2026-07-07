import SwiftUI

struct UnitTooltipView: View {
    let division: Division?
    var isTangSongScenario = false

    var body: some View {
        if let division {
            VStack(alignment: .leading, spacing: 6) {
                Text(division.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)

                Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 4) {
                    GridRow {
                        label(isTangSongScenario ? "兵种" : "Type")
                        value(division.tooltipTypeCode(isTangSongScenario: isTangSongScenario))
                    }
                    GridRow {
                        label(isTangSongScenario ? "兵力" : "Strength")
                        value(strengthText(for: division))
                    }
                    GridRow {
                        label(isTangSongScenario ? "补给" : "Supply")
                        value(division.supplyState.tooltipDisplayName(isTangSongScenario: isTangSongScenario))
                    }
                    GridRow {
                        label(isTangSongScenario ? "退却" : "Retreat")
                        value(division.retreatMode.tooltipDisplayName(isTangSongScenario: isTangSongScenario))
                    }
                    GridRow {
                        label(isTangSongScenario ? "本回合" : "Acted")
                        value(actedText(for: division))
                    }
                }
            }
            .padding(10)
            .frame(width: 220, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.secondary.opacity(0.35), lineWidth: 1)
            }
            .padding(10)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel(for: division))
            .accessibilityValue(accessibilityValue(for: division))
        }
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private func value(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
    }

    private func actedText(for division: Division) -> String {
        if isTangSongScenario {
            return division.hasActed ? "已行动" : "未行动"
        }
        return division.hasActed ? "Yes" : "No"
    }

    private func strengthText(for division: Division) -> String {
        isTangSongScenario
            ? "\(division.strength)／\(division.maxStrength)"
            : "\(division.strength)/\(division.maxStrength)"
    }

    private func accessibilityLabel(for division: Division) -> String {
        if isTangSongScenario {
            return "\(division.name)，\(division.tooltipTypeCode(isTangSongScenario: true))"
        }
        return "\(division.name), \(division.tooltipTypeCode(isTangSongScenario: false))"
    }

    private func accessibilityValue(for division: Division) -> String {
        if isTangSongScenario {
            return [
                "兵力 \(strengthText(for: division))",
                "补给 \(division.supplyState.tooltipDisplayName(isTangSongScenario: true))",
                "退却 \(division.retreatMode.tooltipDisplayName(isTangSongScenario: true))",
                "本回合 \(actedText(for: division))"
            ].joined(separator: "，")
        }

        return [
            "strength \(division.strength) of \(division.maxStrength)",
            "supply \(division.supplyState.tooltipDisplayName(isTangSongScenario: false))",
            "retreat \(division.retreatMode.tooltipDisplayName(isTangSongScenario: false))",
            "acted \(actedText(for: division))"
        ].joined(separator: ", ")
    }
}

private extension Division {
    func tooltipTypeCode(isTangSongScenario: Bool) -> String {
        if isArtillery {
            return isTangSongScenario ? "器械" : "ART"
        }
        if isArmor {
            return isTangSongScenario ? "禁军" : "ARM"
        }
        if components.contains(where: { $0.type == .motorizedInfantry && $0.weight >= 0.40 }) {
            return isTangSongScenario ? "骑军" : "MOT"
        }
        return isTangSongScenario ? "厢军" : "INF"
    }
}

private extension RetreatMode {
    func tooltipDisplayName(isTangSongScenario: Bool) -> String {
        if isTangSongScenario {
            switch self {
            case .retreatable:
                return "可退"
            case .hold:
                return "固守"
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

private extension SupplyState {
    func tooltipDisplayName(isTangSongScenario: Bool) -> String {
        if isTangSongScenario {
            switch self {
            case .supplied:
                return "有粮"
            case .lowSupply:
                return "缺粮"
            case .encircled:
                return "被围"
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
