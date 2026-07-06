import Foundation

enum CommandValidationError: String, Codable, Equatable {
    case wrongPhase
    case wrongFaction
    case divisionNotFound
    case targetNotFound
    case countryNotFound
    case alreadyActed
    case destinationOutOfBounds
    case destinationOccupied
    case noPath
    case insufficientMovement
    case targetOutOfRange
    case invalidTargetFaction
    case regionNotFound
    case invalidRegionForHex
    case invalidSiegeTarget
    case noActiveSiege
    case fortificationAlreadyFull
    case capitulationNotReady
    case invalidDiplomaticRelation
    case submissionNotReady
    case mandateTooLow
    case insufficientResources
}

extension CommandValidationError {
    func displayName(isTangSongScenario: Bool) -> String {
        guard isTangSongScenario else {
            return rawValue
        }

        switch self {
        case .wrongPhase:
            return "当前阶段不可下令"
        case .wrongFaction:
            return "不可指挥该政权军队"
        case .divisionNotFound:
            return "未找到军队"
        case .targetNotFound:
            return "未找到目标"
        case .countryNotFound:
            return "未找到政权"
        case .alreadyActed:
            return "本回合已行动"
        case .destinationOutOfBounds:
            return "目标地块越界"
        case .destinationOccupied:
            return "目标地块已有军队"
        case .noPath:
            return "粮道或道路不通"
        case .insufficientMovement:
            return "行动力不足"
        case .targetOutOfRange:
            return "目标超出范围"
        case .invalidTargetFaction:
            return "目标政权不可攻击"
        case .regionNotFound:
            return "未找到州府"
        case .invalidRegionForHex:
            return "地块不属于有效州府"
        case .invalidSiegeTarget:
            return "不可围城"
        case .noActiveSiege:
            return "没有正在进行的围城"
        case .fortificationAlreadyFull:
            return "城防已满"
        case .capitulationNotReady:
            return "尚未达到招降条件"
        case .invalidDiplomaticRelation:
            return "外交关系不允许"
        case .submissionNotReady:
            return "尚未达到招抚条件"
        case .mandateTooLow:
            return "天命不足"
        case .insufficientResources:
            return "府库资源不足"
        }
    }
}

struct CommandValidation: Codable, Equatable {
    var errors: [CommandValidationError]

    var isValid: Bool {
        errors.isEmpty
    }

    static let valid = CommandValidation(errors: [])

    static func invalid(_ error: CommandValidationError) -> CommandValidation {
        CommandValidation(errors: [error])
    }
}
