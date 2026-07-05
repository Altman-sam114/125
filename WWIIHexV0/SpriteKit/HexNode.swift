import SpriteKit

final class HexNode: SKNode {
    let coord: HexCoord

    init(
        displayState: HexDisplayState,
        layout: HexLayout,
        supplySourceFaction: Faction?,
        isSelected: Bool,
        isMoveHighlighted: Bool,
        isAttackHighlighted: Bool,
        isTangSongScenario: Bool = false
    ) {
        self.coord = displayState.coord
        super.init()

        position = layout.hexToPixel(displayState.coord)
        zPosition = 0

        let path = Self.hexPath(layout: layout)
        let base = SKShapeNode(path: path)
        base.fillColor = TerrainStyle.fillColor(for: displayState.terrain, isTangSongScenario: isTangSongScenario)
        base.strokeColor = TerrainStyle.strokeColor(for: displayState.terrain, isTangSongScenario: isTangSongScenario)
        base.lineWidth = displayState.terrain == .fortress ? max(2, layout.hexSize * 0.08) : 1
        base.zPosition = 0
        addChild(base)

        if let controller = displayState.controller {
            addControllerOverlay(
                path: path,
                controller: controller,
                layout: layout,
                isTangSongScenario: isTangSongScenario
            )
        }

        if isMoveHighlighted {
            addHighlight(
                path: path,
                color: TerrainStyle.movementFillColor(isTangSongScenario: isTangSongScenario),
                zPosition: 2
            )
        }

        if isAttackHighlighted {
            addHighlight(
                path: path,
                color: TerrainStyle.attackFillColor(isTangSongScenario: isTangSongScenario),
                zPosition: 3
            )
        }

        if isSelected {
            let selected = SKShapeNode(path: path)
            selected.fillColor = .clear
            selected.strokeColor = TerrainStyle.selectedStrokeColor(isTangSongScenario: isTangSongScenario)
            selected.lineWidth = max(3, layout.hexSize * 0.09)
            selected.zPosition = 5
            addChild(selected)
        }

        addObjectiveLabels(
            displayState: displayState,
            supplySourceFaction: supplySourceFaction,
            layout: layout,
            isTangSongScenario: isTangSongScenario
        )
        addFog(for: displayState.visibility, path: path)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addHighlight(path: CGPath, color: SKColor, zPosition: CGFloat) {
        let highlight = SKShapeNode(path: path)
        highlight.fillColor = color
        highlight.strokeColor = .clear
        highlight.zPosition = zPosition
        addChild(highlight)
    }

    private func addControllerOverlay(
        path: CGPath,
        controller: Faction,
        layout: HexLayout,
        isTangSongScenario: Bool
    ) {
        let overlay = SKShapeNode(path: path)
        let controllerColor = TerrainStyle.controllerColor(for: controller, isTangSongScenario: isTangSongScenario)
        overlay.fillColor = controllerColor.withAlphaComponent(0.16)
        overlay.strokeColor = controllerColor.withAlphaComponent(0.82)
        overlay.lineWidth = max(1.5, layout.hexSize * 0.04)
        overlay.zPosition = 1
        addChild(overlay)
    }

    private func addObjectiveLabels(
        displayState: HexDisplayState,
        supplySourceFaction: Faction?,
        layout: HexLayout,
        isTangSongScenario: Bool
    ) {
        let textColor = TerrainStyle.textColor(for: displayState.terrain, isTangSongScenario: isTangSongScenario)
        if let cityName = displayState.cityName {
            addLabel(
                text: cityName,
                y: layout.hexSize * 0.04,
                fontSize: max(7, layout.hexSize * 0.18),
                color: textColor,
                zPosition: 6
            )
        }

        if let fortressName = displayState.fortressName {
            addLabel(
                text: fortressName,
                y: layout.hexSize * 0.03,
                fontSize: max(7, layout.hexSize * 0.16),
                color: textColor,
                zPosition: 6
            )
            addLabel(
                text: isTangSongScenario ? "关" : "FORT",
                y: -layout.hexSize * 0.22,
                fontSize: max(7, layout.hexSize * 0.14),
                color: textColor,
                zPosition: 6
            )
        }

        if displayState.controller != nil || supplySourceFaction != nil {
            let owner = displayState.controller ?? supplySourceFaction
            let dot = SKShapeNode(circleOfRadius: max(3, layout.hexSize * 0.10))
            dot.fillColor = TerrainStyle.controllerColor(for: owner, isTangSongScenario: isTangSongScenario)
            dot.strokeColor = SKColor(white: 1, alpha: 0.70)
            dot.lineWidth = 1
            dot.position = CGPoint(x: -layout.hexSize * 0.42, y: -layout.hexSize * 0.48)
            dot.zPosition = 7
            addChild(dot)
        }

        if let supplySourceFaction {
            addLabel(
                text: supplyLabel(for: supplySourceFaction, isTangSongScenario: isTangSongScenario),
                y: layout.hexSize * 0.36,
                fontSize: max(6, layout.hexSize * 0.13),
                color: textColor,
                zPosition: 7
            )
        }
    }

    private func supplyLabel(for faction: Faction, isTangSongScenario: Bool) -> String {
        if isTangSongScenario {
            return faction == .allies ? "粮宋" : "粮割"
        }
        return faction == .allies ? "SUP A" : "SUP G"
    }

    private func addFog(for visibility: VisibilityState, path: CGPath) {
        let alpha: CGFloat
        switch visibility {
        case .visible:
            return
        case .explored:
            alpha = 0.34
        case .unseen:
            alpha = 0.72
        }

        let fog = SKShapeNode(path: path)
        fog.fillColor = SKColor(white: 0.04, alpha: alpha)
        fog.strokeColor = .clear
        fog.zPosition = 20
        addChild(fog)
    }

    private func addLabel(text: String, y: CGFloat, fontSize: CGFloat, color: SKColor, zPosition: CGFloat) {
        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-DemiBold"
        label.fontSize = fontSize
        label.fontColor = color
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: y)
        label.zPosition = zPosition
        addChild(label)
    }

    private static func hexPath(layout: HexLayout) -> CGPath {
        let points = layout.polygonPoints(center: .zero)
        let path = CGMutablePath()
        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
}
