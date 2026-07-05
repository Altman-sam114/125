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
    let onHold: () -> Void
    let onAllowRetreat: () -> Void
    let onResupply: () -> Void
    let onBesiege: () -> Void
    let onRepairFortification: () -> Void
    let onRelieveSiege: () -> Void
    let onEndTurn: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Commands")
                .font(.headline)

            Text(statusText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                Button(action: onHold) {
                    Label("Hold", systemImage: "shield.fill")
                }
                .disabled(!canSetHold)

                Button(action: onAllowRetreat) {
                    Label("Retreat OK", systemImage: "arrow.uturn.backward.circle")
                }
                .disabled(!canSetRetreatable)

                Button(action: onResupply) {
                    Label("Reinforce", systemImage: "cross.circle")
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

            Button(action: onEndTurn) {
                Label("End Turn", systemImage: "forward.end")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            if let lastCommandMessage {
                Text(lastCommandMessage)
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

    private var statusText: String {
        if observerModeEnabled {
            return "Observer mode: commands disabled."
        }

        guard let selectedDivision else {
            return "No active unit selected."
        }

        guard selectedDivision.faction == playerFaction else {
            return "Enemy unit selected. Commands disabled."
        }

        guard activeFaction == playerFaction, commandsAllowed else {
            return "Commands unavailable during \(phaseDisplayName)."
        }

        guard !selectedDivision.hasActed else {
            return "Selected unit has acted."
        }

        return "Move/Attack ready."
    }
}
