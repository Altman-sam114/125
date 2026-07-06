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

            HStack(spacing: 8) {
                Button(action: onHold) {
                    Label(isTangSongScenario ? "固守" : "Hold", systemImage: "shield.fill")
                }
                .disabled(!canSetHold)

                Button(action: onAllowRetreat) {
                    Label(isTangSongScenario ? "可退" : "Retreat OK", systemImage: "arrow.uturn.backward.circle")
                }
                .disabled(!canSetRetreatable)

                Button(action: onResupply) {
                    Label(isTangSongScenario ? "整补" : "Reinforce", systemImage: "cross.circle")
                }
                .disabled(!canCommandSelectedUnit)
            }
            .buttonStyle(.bordered)

            Button(action: onBesiege) {
                Label(besiegeButtonTitle, systemImage: "scope")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(!canBesiege)

            Button(action: onRepairFortification) {
                Label(repairFortificationButtonTitle, systemImage: "hammer")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(!canRepairFortification)

            Button(action: onRelieveSiege) {
                Label(relieveSiegeButtonTitle, systemImage: "flag.checkered")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(!canRelieveSiege)

            Button(action: onDemandSurrender) {
                Label(demandSurrenderButtonTitle, systemImage: "checkmark.seal")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(!canDemandSurrender)

            Button(action: onProposeSubmission) {
                Label(submissionButtonTitle, systemImage: "seal")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(!canProposeSubmission)

            Button(action: onEndTurn) {
                Label(isTangSongScenario ? "结束回合" : "End Turn", systemImage: "forward.end")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            if let lastCommandMessage {
                Text(commandMessageText(lastCommandMessage))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
            return message
                .replacingOccurrences(of: "General order executed", with: "方面军令已执行")
                .replacingOccurrences(of: "command(s).", with: "道命令。")
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
