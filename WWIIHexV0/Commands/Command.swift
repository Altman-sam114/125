import Foundation

enum Command: Codable, Equatable {
    case move(divisionId: String, destination: HexCoord)
    case attack(attackerId: String, targetId: String)
    case besiege(attackerId: String, targetRegionId: RegionId)
    case repairFortification(defenderId: String, targetRegionId: RegionId)
    case relieveSiege(relieverId: String, targetRegionId: RegionId)
    case hold(divisionId: String)
    case allowRetreat(divisionId: String)
    case resupply(divisionId: String)
    case queueProduction(kind: ProductionKind)
    case endTurn

    static func rest(divisionId: String) -> Command {
        .resupply(divisionId: divisionId)
    }

    static func reinforce(divisionId: String) -> Command {
        .resupply(divisionId: divisionId)
    }

    var displayName: String {
        displayName(isTangSongScenario: false)
    }

    func displayName(isTangSongScenario: Bool) -> String {
        if isTangSongScenario {
            switch self {
            case .move(let divisionId, let destination):
                return "行军(\(divisionId) -> \(destination.q),\(destination.r))"
            case .attack(let attackerId, let targetId):
                return "进攻(\(attackerId) -> \(targetId))"
            case .besiege(let attackerId, let targetRegionId):
                return "围城(\(attackerId) -> \(targetRegionId.rawValue))"
            case .repairFortification(let defenderId, let targetRegionId):
                return "修城(\(defenderId) -> \(targetRegionId.rawValue))"
            case .relieveSiege(let relieverId, let targetRegionId):
                return "解围(\(relieverId) -> \(targetRegionId.rawValue))"
            case .hold(let divisionId):
                return "固守(\(divisionId))"
            case .allowRetreat(let divisionId):
                return "准退(\(divisionId))"
            case .resupply(let divisionId):
                return "休整(\(divisionId))"
            case .queueProduction(let kind):
                return "军备(\(kind.displayName(isTangSongScenario: true)))"
            case .endTurn:
                return "结束回合"
            }
        }

        switch self {
        case .move(let divisionId, let destination):
            return "Move(\(divisionId) -> \(destination.q),\(destination.r))"
        case .attack(let attackerId, let targetId):
            return "Attack(\(attackerId) -> \(targetId))"
        case .besiege(let attackerId, let targetRegionId):
            return "Besiege(\(attackerId) -> \(targetRegionId.rawValue))"
        case .repairFortification(let defenderId, let targetRegionId):
            return "RepairFortification(\(defenderId) -> \(targetRegionId.rawValue))"
        case .relieveSiege(let relieverId, let targetRegionId):
            return "RelieveSiege(\(relieverId) -> \(targetRegionId.rawValue))"
        case .hold(let divisionId):
            return "Hold(\(divisionId))"
        case .allowRetreat(let divisionId):
            return "AllowRetreat(\(divisionId))"
        case .resupply(let divisionId):
            return "Resupply(\(divisionId))"
        case .queueProduction(let kind):
            return "QueueProduction(\(kind.displayName))"
        case .endTurn:
            return "End Turn"
        }
    }

    var actingDivisionId: String? {
        switch self {
        case .move(let divisionId, _),
             .besiege(let divisionId, _),
             .repairFortification(let divisionId, _),
             .relieveSiege(let divisionId, _),
             .hold(let divisionId),
             .allowRetreat(let divisionId),
             .resupply(let divisionId):
            return divisionId
        case .attack(let attackerId, _):
            return attackerId
        case .queueProduction:
            return nil
        case .endTurn:
            return nil
        }
    }

    var isRecoveryCommand: Bool {
        switch self {
        case .resupply:
            return true
        case .move,
             .attack,
             .besiege,
             .repairFortification,
             .relieveSiege,
             .hold,
             .allowRetreat,
             .queueProduction,
             .endTurn:
            return false
        }
    }
}
