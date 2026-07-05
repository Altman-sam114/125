import Foundation

enum GamePhase: String, Codable, Equatable, CaseIterable {
    case germanAI
    case alliedPlayer
    case resolution

    var displayName: String {
        displayName(isTangSongScenario: false)
    }

    func displayName(isTangSongScenario: Bool) -> String {
        if isTangSongScenario {
            switch self {
            case .germanAI:
                return "割据军议"
            case .alliedPlayer:
                return "宋军行动"
            case .resolution:
                return "结算"
            }
        }

        switch self {
        case .germanAI:
            return "German AI"
        case .alliedPlayer:
            return "Allied Player"
        case .resolution:
            return "Resolution"
        }
    }
}
