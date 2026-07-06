import Foundation

enum VictoryReason: String, Codable, Equatable {
    case bastogneHeldByGermany
    case bastogneAndStVithControlledByGermany
    case alliedUnitsDestroyed
    case bastogneHeldByAlliesAtFinalTurn
    case germanUnitsDestroyed
    case germanArmorUnsupplied
    case tangSongUnificationByMandate
    case tangSongSeparatistSurvival

    func displayName(isTangSongScenario: Bool) -> String {
        if isTangSongScenario {
            switch self {
            case .tangSongUnificationByMandate:
                return "关键州府与天命达标"
            case .tangSongSeparatistSurvival:
                return "守住核心州府至终局"
            case .bastogneHeldByGermany:
                return "巴斯托涅失守"
            case .bastogneAndStVithControlledByGermany:
                return "要地失守"
            case .alliedUnitsDestroyed:
                return "盟军主力溃灭"
            case .bastogneHeldByAlliesAtFinalTurn:
                return "守住巴斯托涅"
            case .germanUnitsDestroyed:
                return "德军主力溃灭"
            case .germanArmorUnsupplied:
                return "装甲断补"
            }
        }

        switch self {
        case .bastogneHeldByGermany:
            return "Bastogne held by Germany"
        case .bastogneAndStVithControlledByGermany:
            return "Bastogne and St. Vith controlled"
        case .alliedUnitsDestroyed:
            return "Allied units destroyed"
        case .bastogneHeldByAlliesAtFinalTurn:
            return "Bastogne held at final turn"
        case .germanUnitsDestroyed:
            return "German units destroyed"
        case .germanArmorUnsupplied:
            return "German armor unsupplied"
        case .tangSongUnificationByMandate:
            return "Tang Song unification by mandate"
        case .tangSongSeparatistSurvival:
            return "Separatist survival"
        }
    }

    func eventMessage(winnerName: String, isTangSongScenario: Bool) -> String {
        let reason = displayName(isTangSongScenario: isTangSongScenario)
        if isTangSongScenario {
            return "\(winnerName)胜利：\(reason)。"
        }
        return "\(winnerName) victory: \(reason)."
    }
}

struct VictoryState: Codable, Equatable {
    var winner: Faction?
    var reason: VictoryReason?
    var eliminatedGermanDivisions: Int
    var eliminatedAlliedDivisions: Int
    var germanBastogneHeldSinceTurn: Int?
    var germanArmorUnsuppliedSinceTurn: Int?

    static var ongoing: VictoryState {
        VictoryState(
            winner: nil,
            reason: nil,
            eliminatedGermanDivisions: 0,
            eliminatedAlliedDivisions: 0,
            germanBastogneHeldSinceTurn: nil,
            germanArmorUnsuppliedSinceTurn: nil
        )
    }

    mutating func recordEliminatedDivision(faction: Faction) {
        switch faction {
        case .germany:
            eliminatedGermanDivisions += 1
        case .allies:
            eliminatedAlliedDivisions += 1
        }
    }
}
