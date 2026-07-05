import Foundation

enum MapDisplayLayer: String, Codable, Equatable, CaseIterable, Identifiable {
    case hex
    case province
    case initialTheater
    case dynamicTheater
    case frontLine
    case deployment

    var id: String {
        rawValue
    }

    var displayName: String {
        displayName(isTangSongScenario: false)
    }

    func displayName(isTangSongScenario: Bool) -> String {
        if isTangSongScenario {
            switch self {
            case .hex:
                return "地块"
            case .province:
                return "州府"
            case .initialTheater:
                return "初始方面"
            case .dynamicTheater:
                return "动态方面"
            case .frontLine:
                return "前线"
            case .deployment:
                return "部署"
            }
        }

        switch self {
        case .hex:
            return "Hex"
        case .province:
            return "Province"
        case .initialTheater:
            return "Initial"
        case .dynamicTheater:
            return "Dynamic"
        case .frontLine:
            return "Front"
        case .deployment:
            return "Deploy"
        }
    }
}
