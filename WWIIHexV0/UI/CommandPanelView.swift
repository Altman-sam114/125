import SwiftUI

struct CommandPanelView: View {
    let selectedDivision: Division?
    let activeFaction: Faction
    let phase: GamePhase
    let playerFaction: Faction
    let observerModeEnabled: Bool
    let commandsAllowed: Bool
    let phaseDisplayName: String
    let lastCommandMessage: String?
    let isTangSongScenario: Bool
    let besiegeTargetName: String?
    let repairFortificationTargetName: String?
    let relieveSiegeTargetName: String?
    let demandSurrenderTargetName: String?
    let submissionTargetName: String?
    let onHold: () -> Void
    let onAllowRetreat: () -> Void
    let onResupply: () -> Void
    let onBesiege: () -> Void
    let onRepairFortification: () -> Void
    let onRelieveSiege: () -> Void
    let onDemandSurrender: () -> Void
    let onProposeSubmission: () -> Void
    let onEndTurn: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(isTangSongScenario ? "军令" : "Commands")
                .font(.headline)

            Text(statusText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel(commandStatusAccessibilityLabel)
                .accessibilityValue(statusText)

            HStack(spacing: 8) {
                Button(action: onHold) {
                    Label(isTangSongScenario ? "固守" : "Hold", systemImage: "shield.fill")
                }
                .disabled(!canSetHold)
                .accessibilityValue(commandAccessibilityValue(isEnabled: canSetHold))
                .accessibilityHint(holdAccessibilityHint)

                Button(action: onAllowRetreat) {
                    Label(isTangSongScenario ? "可退" : "Retreat OK", systemImage: "arrow.uturn.backward.circle")
                }
                .disabled(!canSetRetreatable)
                .accessibilityValue(commandAccessibilityValue(isEnabled: canSetRetreatable))
                .accessibilityHint(retreatAccessibilityHint)

                Button(action: onResupply) {
                    Label(isTangSongScenario ? "整补" : "Reinforce", systemImage: "cross.circle")
                }
                .disabled(!canCommandSelectedUnit)
                .accessibilityValue(commandAccessibilityValue(isEnabled: canCommandSelectedUnit))
                .accessibilityHint(resupplyAccessibilityHint)
            }
            .buttonStyle(.bordered)

            Button(action: onBesiege) {
                Label(besiegeButtonTitle, systemImage: "scope")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(!canBesiege)
            .accessibilityValue(commandAccessibilityValue(isEnabled: canBesiege))
            .accessibilityHint(targetCommandAccessibilityHint(
                isEnabled: canBesiege,
                ready: isTangSongScenario ? "对当前选中的敌方城池、关隘或粮仓登记围城压力。" : "Besiege the selected enemy city, pass, or granary.",
                missingTarget: isTangSongScenario ? "需先在地图选择相邻敌方城池、关隘或粮仓。" : "Select an adjacent enemy city, pass, or granary first."
            ))

            Button(action: onRepairFortification) {
                Label(repairFortificationButtonTitle, systemImage: "hammer")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(!canRepairFortification)
            .accessibilityValue(commandAccessibilityValue(isEnabled: canRepairFortification))
            .accessibilityHint(targetCommandAccessibilityHint(
                isEnabled: canRepairFortification,
                ready: isTangSongScenario ? "让当前军队修补所选受围州府的城防。" : "Repair fortifications in the selected besieged friendly region.",
                missingTarget: isTangSongScenario ? "需先选择己方受围且城防受损的州府。" : "Select a damaged friendly besieged region first."
            ))

            Button(action: onRelieveSiege) {
                Label(relieveSiegeButtonTitle, systemImage: "flag.checkered")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(!canRelieveSiege)
            .accessibilityValue(commandAccessibilityValue(isEnabled: canRelieveSiege))
            .accessibilityHint(targetCommandAccessibilityHint(
                isEnabled: canRelieveSiege,
                ready: isTangSongScenario ? "让当前军队驰援射程内的己方受围州府。" : "Relieve a friendly besieged region in range.",
                missingTarget: isTangSongScenario ? "需先选择或靠近己方受围州府。" : "Select or move near a friendly besieged region first."
            ))

            Button(action: onDemandSurrender) {
                Label(demandSurrenderButtonTitle, systemImage: "checkmark.seal")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(!canDemandSurrender)
            .accessibilityValue(commandAccessibilityValue(isEnabled: canDemandSurrender))
            .accessibilityHint(targetCommandAccessibilityHint(
                isEnabled: canDemandSurrender,
                ready: isTangSongScenario ? "对城防已破且断粮的围城目标发起招降。" : "Demand surrender from a broken siege target.",
                missingTarget: isTangSongScenario ? "需先选中城防已破且断粮的敌方围城目标。" : "Select a broken enemy siege target first."
            ))

            Button(action: onProposeSubmission) {
                Label(submissionButtonTitle, systemImage: "seal")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(!canProposeSubmission)
            .accessibilityValue(commandAccessibilityValue(isEnabled: canProposeSubmission))
            .accessibilityHint(targetCommandAccessibilityHint(
                isEnabled: canProposeSubmission,
                ready: isTangSongScenario ? "向当前可招抚的外方国都提出归附。" : "Propose submission to the eligible foreign capital.",
                missingTarget: isTangSongScenario ? "需先选择可招抚的外方国都，或等待外交条件成熟。" : "Select an eligible foreign capital first."
            ))

            Button(action: onEndTurn) {
                Label(isTangSongScenario ? "结束回合" : "End Turn", systemImage: "forward.end")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityValue(commandAccessibilityValue(isEnabled: true))
            .accessibilityHint(isTangSongScenario ? "结束当前军令阶段，推进各方军议和下一回合。" : "End the current turn and advance the game.")

            if let lastCommandMessage {
                Text(commandMessageText(lastCommandMessage))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityLabel(commandFeedbackAccessibilityLabel)
                    .accessibilityValue(commandMessageText(lastCommandMessage))
            }
        }
        .padding(12)
        .background(PlatformStyles.systemBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var canCommandSelectedUnit: Bool {
        guard !observerModeEnabled else {
            return false
        }

        guard let selectedDivision else {
            return false
        }

        return selectedDivision.faction == playerFaction &&
            commandsAllowed &&
            !selectedDivision.hasActed
    }

    private var canSetHold: Bool {
        canCommandSelectedUnit && selectedDivision?.retreatMode != .hold
    }

    private var canSetRetreatable: Bool {
        canCommandSelectedUnit && selectedDivision?.retreatMode != .retreatable
    }

    private var canBesiege: Bool {
        canCommandSelectedUnit && besiegeTargetName != nil
    }

    private var canRepairFortification: Bool {
        canCommandSelectedUnit && repairFortificationTargetName != nil
    }

    private var canRelieveSiege: Bool {
        canCommandSelectedUnit && relieveSiegeTargetName != nil
    }

    private var canDemandSurrender: Bool {
        canCommandSelectedUnit && demandSurrenderTargetName != nil
    }

    private var canProposeSubmission: Bool {
        canCommandSelectedUnit && submissionTargetName != nil
    }

    private var besiegeButtonTitle: String {
        guard let besiegeTargetName else {
            return isTangSongScenario ? "围城" : "Besiege"
        }
        return isTangSongScenario ? "围城 \(besiegeTargetName)" : "Besiege \(besiegeTargetName)"
    }

    private var repairFortificationButtonTitle: String {
        guard let repairFortificationTargetName else {
            return isTangSongScenario ? "修城" : "Repair Wall"
        }
        return isTangSongScenario
            ? "修城 \(repairFortificationTargetName)"
            : "Repair \(repairFortificationTargetName)"
    }

    private var relieveSiegeButtonTitle: String {
        guard let relieveSiegeTargetName else {
            return isTangSongScenario ? "解围" : "Relieve Siege"
        }
        return isTangSongScenario
            ? "解围 \(relieveSiegeTargetName)"
            : "Relieve \(relieveSiegeTargetName)"
    }

    private var demandSurrenderButtonTitle: String {
        guard let demandSurrenderTargetName else {
            return isTangSongScenario ? "招降" : "Demand Surrender"
        }
        return isTangSongScenario
            ? "招降 \(demandSurrenderTargetName)"
            : "Demand \(demandSurrenderTargetName)"
    }

    private var submissionButtonTitle: String {
        guard let submissionTargetName else {
            return isTangSongScenario ? "招抚" : "Propose Submission"
        }
        return isTangSongScenario
            ? "招抚 \(submissionTargetName)"
            : "Propose \(submissionTargetName)"
    }

    private var statusText: String {
        if observerModeEnabled {
            return isTangSongScenario ? "观战模式：军令停用。" : "Observer mode: commands disabled."
        }

        guard let selectedDivision else {
            return isTangSongScenario ? "未选择可行动军队。" : "No active unit selected."
        }

        guard selectedDivision.faction == playerFaction else {
            return isTangSongScenario ? "已选择非亲征军队，军令停用。" : "Enemy unit selected. Commands disabled."
        }

        guard activeFaction == playerFaction, commandsAllowed else {
            return isTangSongScenario ? "\(phaseDisplayName)不可下令。" : "Commands unavailable during \(phaseDisplayName)."
        }

        guard !selectedDivision.hasActed else {
            return isTangSongScenario ? "该军队本回合已行动。" : "Selected unit has acted."
        }

        return isTangSongScenario ? "可行军或进攻。" : "Move/Attack ready."
    }

    private func commandAccessibilityValue(isEnabled: Bool) -> String {
        if isTangSongScenario {
            return isEnabled ? "可用" : "停用"
        }
        return isEnabled ? "Available" : "Unavailable"
    }

    private var commandStatusAccessibilityLabel: String {
        isTangSongScenario ? "军令状态" : "Command status"
    }

    private var commandFeedbackAccessibilityLabel: String {
        isTangSongScenario ? "军令反馈" : "Command feedback"
    }

    private var holdAccessibilityHint: String {
        if canSetHold {
            return isTangSongScenario ? "命当前军队固守阵地，不主动退却。" : "Order the selected unit to hold position."
        }
        if canCommandSelectedUnit {
            return isTangSongScenario ? "当前军队已经按固守口径行动。" : "The selected unit is already set to hold."
        }
        return statusText
    }

    private var retreatAccessibilityHint: String {
        if canSetRetreatable {
            return isTangSongScenario ? "准许当前军队在不利战斗后退却。" : "Allow the selected unit to retreat after combat."
        }
        if canCommandSelectedUnit {
            return isTangSongScenario ? "当前军队已经按可退口径行动。" : "The selected unit is already allowed to retreat."
        }
        return statusText
    }

    private var resupplyAccessibilityHint: String {
        if canCommandSelectedUnit {
            return isTangSongScenario ? "消耗当前军队行动机会进行整补。" : "Spend the selected unit's action to reinforce."
        }
        return statusText
    }

    private func targetCommandAccessibilityHint(isEnabled: Bool, ready: String, missingTarget: String) -> String {
        if isEnabled {
            return ready
        }
        if canCommandSelectedUnit {
            return missingTarget
        }
        return statusText
    }

    private func commandMessageText(_ message: String) -> String {
        guard isTangSongScenario else {
            return message
        }

        if message == "AI turn completed." {
            return "军议回合已完成。"
        }
        if message.hasPrefix("AI turn completed with") {
            return "军议回合已完成，仍有问题待查。"
        }
        if message.hasPrefix("General order produced no commands") {
            return "方面军令未生成可执行命令。"
        }
        if message.hasPrefix("General order executed") {
            let numbers = message.split { !$0.isNumber }.compactMap { Int($0) }
            if numbers.count >= 2 {
                let accepted = numbers[0]
                let total = numbers[1]
                return "方面军令已执行 \(accepted) 道，未执行 \(max(0, total - accepted)) 道。"
            }
            if let accepted = numbers.first {
                return "方面军令已执行 \(accepted) 道命令。"
            }
            return "方面军令已执行。"
        }
        if message.contains("wrongPhase") {
            return "军令被拒：当前阶段不可下令。"
        }
        if message.contains("wrongFaction") {
            return "军令被拒：不可指挥该政权军队。"
        }
        return TangSongEventLogMessage.display(message)
    }
}
