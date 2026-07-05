import SwiftUI

struct EventLogView: View {
    let entries: [GameLogEntry]
    var isTangSongScenario = false
    var factionDisplayName: ((Faction) -> String)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isTangSongScenario ? "战报" : "Event Log")
                .font(.headline)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    if recentEntries.isEmpty {
                        Text(isTangSongScenario ? "暂无战报。" : "No events yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(recentEntries) { item in
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(item.category.displayName(isTangSongScenario: isTangSongScenario))
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(item.category.foregroundStyle)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(item.category.backgroundStyle)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))

                                    Text(metadata(for: item.entry))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Text(item.entry.message)
                                    .font(.body)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .frame(minHeight: 120)
        }
        .padding(12)
        .background(PlatformStyles.systemBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var recentEntries: [LogDisplayEntry] {
        entries
            .suffix(60)
            .reversed()
            .map { LogDisplayEntry(entry: $0, category: LogDisplayCategory(entry: $0)) }
    }

    private func metadata(for entry: GameLogEntry) -> String {
        let faction = entry.faction.map { factionDisplayName?($0) ?? $0.displayName } ??
            (isTangSongScenario ? "系统" : "System")
        let phase = entry.phase?.displayName(isTangSongScenario: isTangSongScenario) ??
            (isTangSongScenario ? "开局" : "Setup")
        let turnLabel = isTangSongScenario ? "回合" : "Turn"
        if let relatedRecordId = entry.relatedRecordId {
            return "\(turnLabel) \(entry.turn) - \(faction) - \(phase) - \(relatedRecordId)"
        }
        return "\(turnLabel) \(entry.turn) - \(faction) - \(phase)"
    }
}

private struct LogDisplayEntry: Identifiable {
    let entry: GameLogEntry
    let category: LogDisplayCategory

    var id: UUID {
        entry.id
    }
}

private enum LogDisplayCategory {
    case combat
    case retreat
    case reinforcement
    case encirclement
    case siege
    case supply
    case frontChange
    case theaterChange
    case regionOwnerChange
    case diplomacy
    case event

    init(entry: GameLogEntry) {
        switch entry.category {
        case .combat:
            self = .combat
            return
        case .retreat:
            self = .retreat
            return
        case .reinforce:
            self = .reinforcement
            return
        case .encircle:
            self = .encirclement
            return
        case .siege:
            self = .siege
            return
        case .supply:
            self = .supply
            return
        case .frontChange:
            self = .frontChange
            return
        case .theaterChange:
            self = .theaterChange
            return
        case .regionOwnerChange:
            self = .regionOwnerChange
            return
        case .diplomacy:
            self = .diplomacy
            return
        case .event:
            break
        }

        let message = entry.message
        let text = message.lowercased()

        if text.contains("retreat") || text.contains("routed") || text.contains("routing") ||
            message.contains("退却") || message.contains("撤退") {
            self = .retreat
        } else if text.contains("reinforce") || text.contains("replacement") || text.contains("replenish") ||
            message.contains("整补") || message.contains("补员") {
            self = .reinforcement
        } else if text.contains("siege") || text.contains("besiege") ||
            message.contains("围城") || message.contains("解围") || message.contains("招降") {
            self = .siege
        } else if text.contains("encircle") || text.contains("encircled") || message.contains("合围") {
            self = .encirclement
        } else if text.contains("attack") || text.contains("damage") || text.contains("combat") ||
            text.contains("hit") || message.contains("进攻") || message.contains("攻击") || message.contains("战斗") {
            self = .combat
        } else if text.contains("supply") || text.contains("supplied") ||
            message.contains("粮道") || message.contains("粮草") || message.contains("补给") {
            self = .supply
        } else {
            self = .event
        }
    }

    func displayName(isTangSongScenario: Bool) -> String {
        if isTangSongScenario {
            switch self {
            case .combat:
                return "战斗"
            case .retreat:
                return "退却"
            case .reinforcement:
                return "整补"
            case .encirclement:
                return "合围"
            case .siege:
                return "围城"
            case .supply:
                return "粮道"
            case .frontChange:
                return "前线"
            case .theaterChange:
                return "方面"
            case .regionOwnerChange:
                return "州府"
            case .diplomacy:
                return "外交"
            case .event:
                return "事件"
            }
        }

        switch self {
        case .combat:
            return "Combat"
        case .retreat:
            return "Retreat"
        case .reinforcement:
            return "Reinforce"
        case .encirclement:
            return "Encircle"
        case .siege:
            return "Siege"
        case .supply:
            return "Supply"
        case .frontChange:
            return "Front"
        case .theaterChange:
            return "Theater"
        case .regionOwnerChange:
            return "Region"
        case .diplomacy:
            return "Diplomacy"
        case .event:
            return "Event"
        }
    }

    var foregroundStyle: Color {
        switch self {
        case .combat:
            return .red
        case .retreat:
            return .orange
        case .reinforcement:
            return .green
        case .encirclement:
            return .purple
        case .siege:
            return .brown
        case .supply:
            return .teal
        case .frontChange:
            return .blue
        case .theaterChange:
            return .indigo
        case .regionOwnerChange:
            return .mint
        case .diplomacy:
            return .cyan
        case .event:
            return .secondary
        }
    }

    var backgroundStyle: Color {
        foregroundStyle.opacity(0.12)
    }
}
