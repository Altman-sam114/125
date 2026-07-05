import Foundation

struct CommandResultSummary: Identifiable, Codable, Equatable {
    let id: String
    let orderIndex: Int?
    let divisionId: String?
    let orderType: AgentOrderType?
    let commandDisplayName: String?
    let mappingSucceeded: Bool
    let validationSucceeded: Bool?
    let executed: Bool
    let message: String
    let errors: [String]

    static func mapped(
        orderIndex: Int,
        order: AgentOrder,
        command: Command,
        result: CommandResult
    ) -> CommandResultSummary {
        CommandResultSummary(
            id: "order_\(orderIndex)_\(order.divisionId)_\(order.type.rawValue)",
            orderIndex: orderIndex,
            divisionId: order.divisionId,
            orderType: order.type,
            commandDisplayName: command.displayName,
            mappingSucceeded: true,
            validationSucceeded: result.validation.isValid,
            executed: result.succeeded,
            message: result.message,
            errors: result.validation.errors.map(\.rawValue)
        )
    }

    static func mappingFailed(
        orderIndex: Int,
        order: AgentOrder,
        error: Error
    ) -> CommandResultSummary {
        CommandResultSummary(
            id: "order_\(orderIndex)_\(order.divisionId)_mapping_failed",
            orderIndex: orderIndex,
            divisionId: order.divisionId,
            orderType: order.type,
            commandDisplayName: nil,
            mappingSucceeded: false,
            validationSucceeded: nil,
            executed: false,
            message: "Mapping failed.",
            errors: [error.localizedDescription]
        )
    }

    static func endTurn(result: CommandResult) -> CommandResultSummary {
        CommandResultSummary(
            id: "end_turn",
            orderIndex: nil,
            divisionId: nil,
            orderType: nil,
            commandDisplayName: Command.endTurn.displayName,
            mappingSucceeded: true,
            validationSucceeded: result.validation.isValid,
            executed: result.succeeded,
            message: result.message,
            errors: result.validation.errors.map(\.rawValue)
        )
    }

    static func directiveCommand(
        directiveIndex: Int,
        commandIndex: Int,
        directive: ZoneDirective,
        command: Command,
        result: CommandResult,
        isTangSongScenario: Bool = false
    ) -> CommandResultSummary {
        CommandResultSummary(
            id: "directive_\(directiveIndex)_command_\(commandIndex)_\(directive.type.rawValue)",
            orderIndex: commandIndex,
            divisionId: command.actingDivisionId,
            orderType: nil,
            commandDisplayName: command.displayName(isTangSongScenario: isTangSongScenario),
            mappingSucceeded: true,
            validationSucceeded: result.validation.isValid,
            executed: result.succeeded,
            message: result.message,
            errors: result.validation.errors.map(\.rawValue)
        )
    }

    static func aiAuxiliaryCommand(
        commandIndex: Int,
        source: String,
        command: Command,
        result: CommandResult,
        isTangSongScenario: Bool = false
    ) -> CommandResultSummary {
        let divisionId = command.actingDivisionId
        let sourceKey = source.replacingOccurrences(of: " ", with: "_")
        return CommandResultSummary(
            id: "ai_\(sourceKey)_command_\(commandIndex)_\(divisionId ?? "none")",
            orderIndex: commandIndex,
            divisionId: divisionId,
            orderType: nil,
            commandDisplayName: command.displayName(isTangSongScenario: isTangSongScenario),
            mappingSucceeded: true,
            validationSucceeded: result.validation.isValid,
            executed: result.succeeded,
            message: result.message,
            errors: result.validation.errors.map(\.rawValue)
        )
    }

    static func aiAuxiliarySkipped(
        commandIndex: Int,
        source: String,
        targetRegionId: RegionId,
        message: String,
        isTangSongScenario: Bool = false
    ) -> CommandResultSummary {
        let sourceKey = source.replacingOccurrences(of: " ", with: "_")
        return CommandResultSummary(
            id: "ai_\(sourceKey)_skipped_\(commandIndex)_\(targetRegionId.rawValue)",
            orderIndex: commandIndex,
            divisionId: nil,
            orderType: nil,
            commandDisplayName: isTangSongScenario
                ? "招抚候选(\(targetRegionId.rawValue))"
                : "PacificationCandidate(\(targetRegionId.rawValue))",
            mappingSucceeded: true,
            validationSucceeded: nil,
            executed: false,
            message: message,
            errors: []
        )
    }
}

struct TheaterDirectiveExplanationSummary: Codable, Equatable {
    let strategicIntent: String?
    let mandateIntent: String?
    let courtPolicy: String?
    let pacificationTargets: [RegionId]
    let supplyPriorities: [RegionId]
    let summary: String?

    init(
        strategicIntent: String? = nil,
        mandateIntent: String? = nil,
        courtPolicy: String? = nil,
        pacificationTargets: [RegionId] = [],
        supplyPriorities: [RegionId] = [],
        summary: String? = nil
    ) {
        self.strategicIntent = strategicIntent
        self.mandateIntent = mandateIntent
        self.courtPolicy = courtPolicy
        self.pacificationTargets = Self.uniqueRegionIds(pacificationTargets)
        self.supplyPriorities = Self.uniqueRegionIds(supplyPriorities)
        self.summary = summary
    }

    var hasDisplayableContent: Bool {
        Self.hasText(mandateIntent)
            || Self.hasText(courtPolicy)
            || !pacificationTargets.isEmpty
            || !supplyPriorities.isEmpty
            || Self.hasText(summary)
    }

    private static func hasText(_ value: String?) -> Bool {
        guard let value else { return false }
        return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private static func uniqueRegionIds(_ regionIds: [RegionId]) -> [RegionId] {
        var seen: Set<RegionId> = []
        var result: [RegionId] = []
        for regionId in regionIds.sorted(by: { $0.rawValue < $1.rawValue }) where !seen.contains(regionId) {
            seen.insert(regionId)
            result.append(regionId)
        }
        return result
    }
}

struct AgentDecisionRecord: Identifiable, Codable, Equatable {
    let id: String
    let turn: Int
    let agentId: String
    let provider: String
    let contextSummary: String
    let rawJSON: String?
    let parsedIntent: String?
    let commandResults: [CommandResultSummary]
    let errors: [String]
    let theaterDirectiveSummary: TheaterDirectiveExplanationSummary?

    init(
        id: String,
        turn: Int,
        agentId: String,
        provider: String,
        contextSummary: String,
        rawJSON: String?,
        parsedIntent: String?,
        commandResults: [CommandResultSummary],
        errors: [String],
        theaterDirectiveSummary: TheaterDirectiveExplanationSummary? = nil
    ) {
        self.id = id
        self.turn = turn
        self.agentId = agentId
        self.provider = provider
        self.contextSummary = contextSummary
        self.rawJSON = rawJSON
        self.parsedIntent = parsedIntent
        self.commandResults = commandResults
        self.errors = errors
        self.theaterDirectiveSummary = theaterDirectiveSummary
    }
}
