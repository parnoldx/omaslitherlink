import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root
    focus: true

    signal returnToMenu()

    // Sizing calculations
    readonly property int availableSize: Math.min(root.width - 48, root.height - 48)
    readonly property int maxDim: Math.max(game.rows, game.cols)
    readonly property int cellSize: Math.max(26, Math.floor(availableSize / (maxDim > 0 ? maxDim : 5)))
    readonly property int boardWidth: cellSize * game.cols
    readonly property int boardHeight: cellSize * game.rows
    readonly property int visibleLineWidth: Math.max(6, Math.floor(cellSize * 0.14))
    readonly property int edgeCorridor: Math.max(10, Math.round(visibleLineWidth * 1.2))

    property bool keyboardMode: false
    property int hoveredEdge: -1
    property int dragMode: 0 // 0 none, 1 line, 2 cross
    property int lastDraggedEdge: -1

    function findClosestEdgeAt(px, py) {
        if (game.cols <= 0 || game.rows <= 0) return -1;
        var margin = Math.max(20, cellSize * 0.4);
        if (px < -margin || px > boardWidth + margin || py < -margin || py > boardHeight + margin) {
            return -1;
        }

        var cpx = Math.max(0, Math.min(boardWidth, px));
        var cpy = Math.max(0, Math.min(boardHeight, py));

        var cellC = Math.min(game.cols - 1, Math.max(0, Math.floor(cpx / cellSize)));
        var cellR = Math.min(game.rows - 1, Math.max(0, Math.floor(cpy / cellSize)));

        var distTop = cpy - cellR * cellSize;
        var distBottom = (cellR + 1) * cellSize - cpy;
        var distLeft = cpx - cellC * cellSize;
        var distRight = (cellC + 1) * cellSize - cpx;

        var minDist = Math.min(distTop, distBottom, distLeft, distRight);
        if (minDist === distTop) {
            return cellR * game.cols + cellC; // Top H-edge
        } else if (minDist === distBottom) {
            return (cellR + 1) * game.cols + cellC; // Bottom H-edge
        } else if (minDist === distLeft) {
            return game.numHEdges + cellR * (game.cols + 1) + cellC; // Left V-edge
        } else {
            return game.numHEdges + cellR * (game.cols + 1) + (cellC + 1); // Right V-edge
        }
    }

    function findEdgeAt(px, py) {
        if (game.cols <= 0 || game.rows <= 0) return -1;
        var margin = Math.max(16, cellSize * 0.35);
        if (px < -margin || px > boardWidth + margin || py < -margin || py > boardHeight + margin) {
            return -1;
        }

        var cpx = Math.max(0, Math.min(boardWidth, px));
        var cpy = Math.max(0, Math.min(boardHeight, py));

        var cellC = Math.min(game.cols - 1, Math.max(0, Math.floor(cpx / cellSize)));
        var cellR = Math.min(game.rows - 1, Math.max(0, Math.floor(cpy / cellSize)));

        // If inside the cell bounds, check if this cell has clue 0
        var clueIdx = cellR * game.cols + cellC;
        var clueVal = (game.clues && clueIdx >= 0 && clueIdx < game.clues.length) ? game.clues[clueIdx] : -1;

        var distTop = cpy - cellR * cellSize;
        var distBottom = (cellR + 1) * cellSize - cpy;
        var distLeft = cpx - cellC * cellSize;
        var distRight = (cellC + 1) * cellSize - cpx;

        var minDist = Math.min(distTop, distBottom, distLeft, distRight);
        var edgeCorridor = root.edgeCorridor;

        // Only target a line if within the edge corridor! In cell interior, no line is targeted or highlighted
        if (minDist > edgeCorridor) {
            return -1;
        }

        // If current cell has clue 0, never target or highlight any of its borders as a line!
        if (clueVal === 0) {
            return -1;
        }

        var targetEdge = -1;
        if (minDist === distTop) {
            targetEdge = cellR * game.cols + cellC; // Top H-edge
            if (cellR > 0 && game.clues && game.clues[(cellR - 1) * game.cols + cellC] === 0) return -1;
        } else if (minDist === distBottom) {
            targetEdge = (cellR + 1) * game.cols + cellC; // Bottom H-edge
            if (cellR < game.rows - 1 && game.clues && game.clues[(cellR + 1) * game.cols + cellC] === 0) return -1;
        } else if (minDist === distLeft) {
            targetEdge = game.numHEdges + cellR * (game.cols + 1) + cellC; // Left V-edge
            if (cellC > 0 && game.clues && game.clues[cellR * game.cols + (cellC - 1)] === 0) return -1;
        } else {
            targetEdge = game.numHEdges + cellR * (game.cols + 1) + (cellC + 1); // Right V-edge
            if (cellC < game.cols - 1 && game.clues && game.clues[cellR * game.cols + (cellC + 1)] === 0) return -1;
        }

        return targetEdge;
    }

    // Centered Board Container
    Rectangle {
        id: boardContainer
        anchors.centerIn: parent
        width: root.boardWidth + 32
        height: root.boardHeight + 32
        color: theme.darkerBackground
        radius: 16
        border.color: theme.selection
        border.width: 2

        // Inner play area
        Item {
            id: playArea
            anchors.centerIn: parent
            width: root.boardWidth
            height: root.boardHeight

            // 1. Cell Clues & Background
            Repeater {
                model: game.rows * game.cols

                Item {
                    id: cellItem
                    property int r: Math.floor(index / game.cols)
                    property int c: index % game.cols
                    property int clueVal: {
                        var list = game.clues;
                        return (index >= 0 && index < list.length) ? list[index] : -1;
                    }

                    x: c * root.cellSize
                    y: r * root.cellSize
                    width: root.cellSize
                    height: root.cellSize

                    // Cell completion check
                    property bool isSatisfied: {
                        if (clueVal <= 0) return false;
                        var edgesList = game.edges;
                        var topE = r * game.cols + c;
                        var botE = (r + 1) * game.cols + c;
                        var leftE = game.numHEdges + r * (game.cols + 1) + c;
                        var rightE = game.numHEdges + r * (game.cols + 1) + (c + 1);
                        var count = 0;
                        if (edgesList[topE] === 1) count++;
                        if (edgesList[botE] === 1) count++;
                        if (edgesList[leftE] === 1) count++;
                        if (edgesList[rightE] === 1) count++;
                        return count === clueVal;
                    }

                    // Subtle background highlight if cell clue is satisfied
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: 6
                        color: cellItem.isSatisfied ? Qt.rgba(theme.green.r, theme.green.g, theme.green.b, 0.08) : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    // Clue Number
                    Text {
                        anchors.centerIn: parent
                        visible: cellItem.clueVal >= 0
                        text: cellItem.clueVal >= 0 ? cellItem.clueVal.toString() : ""
                        font.pixelSize: Math.max(14, Math.floor(root.cellSize * 0.42))
                        font.bold: true
                        font.family: "JetBrainsMono Nerd Font, Liberation Sans, monospace"
                        color: {
                            if (cellItem.isSatisfied) return theme.green;
                            return theme.foreground;
                        }
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }
            }

            // 2. Horizontal Edges
            Repeater {
                model: (game.rows + 1) * game.cols

                Item {
                    id: hEdgeItem
                    property int r: Math.floor(index / game.cols)
                    property int c: index % game.cols
                    property int edgeIdx: index
                    property int stateVal: {
                        var list = game.edges;
                        return (edgeIdx >= 0 && edgeIdx < list.length) ? list[edgeIdx] : 0;
                    }
                    property bool isCursor: root.keyboardMode && (game.cursorEdge === edgeIdx)
                    property bool isHovered: root.hoveredEdge === edgeIdx

                    x: c * root.cellSize
                    y: r * root.cellSize - Math.max(16, Math.floor(root.cellSize * 0.3))
                    width: root.cellSize
                    height: Math.max(32, Math.floor(root.cellSize * 0.6))

                    // Line representation
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 2
                        anchors.rightMargin: 2
                        height: hEdgeItem.stateVal === 1 ? root.visibleLineWidth : (hEdgeItem.isCursor ? Math.max(4, Math.floor(root.cellSize * 0.1)) : (hEdgeItem.isHovered ? Math.max(4, Math.floor(root.cellSize * 0.08)) : 1))
                        radius: height / 2
                        color: {
                            if (hEdgeItem.stateVal === 1) return theme.accent;
                            if (hEdgeItem.isCursor) return theme.yellow;
                            if (hEdgeItem.isHovered) return Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.45);
                            return "transparent";
                        }
                        visible: hEdgeItem.stateVal === 1 || hEdgeItem.isCursor || hEdgeItem.isHovered
                    }

                    // Cross (X) representation
                    Text {
                        anchors.centerIn: parent
                        visible: hEdgeItem.stateVal === 2
                        text: "×"
                        font.pixelSize: Math.max(16, Math.floor(root.cellSize * 0.4))
                        font.bold: true
                        color: theme.red
                    }
                }
            }

            // 3. Vertical Edges
            Repeater {
                model: game.rows * (game.cols + 1)

                Item {
                    id: vEdgeItem
                    property int r: Math.floor(index / (game.cols + 1))
                    property int c: index % (game.cols + 1)
                    property int edgeIdx: game.numHEdges + index
                    property int stateVal: {
                        var list = game.edges;
                        return (edgeIdx >= 0 && edgeIdx < list.length) ? list[edgeIdx] : 0;
                    }
                    property bool isCursor: root.keyboardMode && (game.cursorEdge === edgeIdx)
                    property bool isHovered: root.hoveredEdge === edgeIdx

                    x: c * root.cellSize - Math.max(16, Math.floor(root.cellSize * 0.3))
                    y: r * root.cellSize
                    width: Math.max(32, Math.floor(root.cellSize * 0.6))
                    height: root.cellSize

                    // Line representation
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.topMargin: 2
                        anchors.bottomMargin: 2
                        width: vEdgeItem.stateVal === 1 ? root.visibleLineWidth : (vEdgeItem.isCursor ? Math.max(4, Math.floor(root.cellSize * 0.1)) : (vEdgeItem.isHovered ? Math.max(4, Math.floor(root.cellSize * 0.08)) : 1))
                        radius: width / 2
                        color: {
                            if (vEdgeItem.stateVal === 1) return theme.accent;
                            if (vEdgeItem.isCursor) return theme.yellow;
                            if (vEdgeItem.isHovered) return Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.45);
                            return "transparent";
                        }
                        visible: vEdgeItem.stateVal === 1 || vEdgeItem.isCursor || vEdgeItem.isHovered
                    }

                    // Cross (X) representation
                    Text {
                        anchors.centerIn: parent
                        visible: vEdgeItem.stateVal === 2
                        text: "×"
                        font.pixelSize: Math.max(16, Math.floor(root.cellSize * 0.4))
                        font.bold: true
                        color: theme.red
                    }
                }
            }

            // 4. Grid Intersection Dots
            Repeater {
                model: (game.rows + 1) * (game.cols + 1)

                Rectangle {
                    property int vr: Math.floor(index / (game.cols + 1))
                    property int vc: index % (game.cols + 1)

                    x: vc * root.cellSize - width / 2
                    y: vr * root.cellSize - height / 2
                    width: Math.max(8, Math.floor(root.cellSize * 0.16))
                    height: width
                    radius: width / 2
                    color: theme.foreground
                    z: 5
                }
            }

            // 5. Interactive Unified MouseArea (handles click & drag drawing!)
            MouseArea {
                id: boardMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor

                onPositionChanged: function(mouse) {
                    root.keyboardMode = false;
                    var edge = (root.dragMode === 2) ? root.findClosestEdgeAt(mouse.x, mouse.y) : root.findEdgeAt(mouse.x, mouse.y);
                    root.hoveredEdge = edge;

                    // If dragging with button held down:
                    if (root.dragMode > 0 && edge >= 0 && edge !== root.lastDraggedEdge) {
                        root.lastDraggedEdge = edge;
                        game.setEdgeState(edge, root.dragMode);
                    }
                }

                onPressed: function(mouse) {
                    root.forceActiveFocus();
                    root.keyboardMode = false;
                    var cr = Math.floor(mouse.y / root.cellSize);
                    var cc = Math.floor(mouse.x / root.cellSize);
                    var isInsideBoard = cr >= 0 && cr < game.rows && cc >= 0 && cc < game.cols;
                    var clueIdx = isInsideBoard ? (cr * game.cols + cc) : -1;
                    var clueVal = (isInsideBoard && game.clues && clueIdx < game.clues.length) ? game.clues[clueIdx] : -1;

                    // If clicking anywhere inside a 0 cell (left or right click), auto-cross all 4 edges!
                    if (isInsideBoard && clueVal === 0) {
                        game.clickCellClue(cr, cc);
                        return;
                    }

                    if (mouse.button === Qt.RightButton) {
                        // Right-clicks target the closest edge to place/toggle a Cross (pencil mark)
                        var edge = root.findClosestEdgeAt(mouse.x, mouse.y);
                        if (edge >= 0) {
                            root.dragMode = 2;
                            root.lastDraggedEdge = edge;
                            game.toggleEdge(edge, 2);
                        }
                        return;
                    }

                    // Left-click:
                    var edge = root.findEdgeAt(mouse.x, mouse.y);
                    if (edge >= 0) {
                        root.dragMode = 1;
                        root.lastDraggedEdge = edge;
                        game.toggleEdge(edge, 1);
                    } else if (isInsideBoard) {
                        // Click inside cell interior - auto-crosses if satisfied clue, never triggers a fail!
                        game.clickCellClue(cr, cc);
                    }
                }

                onReleased: {
                    root.dragMode = 0;
                    root.lastDraggedEdge = -1;
                }

                onExited: {
                    root.hoveredEdge = -1;
                    root.dragMode = 0;
                    root.lastDraggedEdge = -1;
                }
            }
        }

        // Pause Overlay
        Rectangle {
            anchors.fill: parent
            z: 20
            visible: game.isPaused
            color: Qt.rgba(theme.darkerBackground.r, theme.darkerBackground.g, theme.darkerBackground.b, 0.88)
            radius: 16

            Column {
                anchors.centerIn: parent
                spacing: 16

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "PAUSED"
                    font.pixelSize: 28
                    font.bold: true
                    color: theme.foreground
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Press P or click to continue"
                    font.pixelSize: 14
                    color: theme.muted
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: game.resumeTimer()
            }
        }
    }

    // Keyboard Event Handling
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
            game.returnToMenu();
            root.returnToMenu();
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_P) {
            game.togglePause();
            event.accepted = true;
            return;
        }

        if (game.isPaused) {
            if (event.key === Qt.Key_Space || event.key === Qt.Key_Return) {
                game.resumeTimer();
                event.accepted = true;
            }
            return;
        }

        // Arrow and Vim navigation
        if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
            root.keyboardMode = true;
            game.moveCursor(-1, 0);
            event.accepted = true;
            return;
        }
        if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
            root.keyboardMode = true;
            game.moveCursor(1, 0);
            event.accepted = true;
            return;
        }
        if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
            root.keyboardMode = true;
            game.moveCursor(0, -1);
            event.accepted = true;
            return;
        }
        if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
            root.keyboardMode = true;
            game.moveCursor(0, 1);
            event.accepted = true;
            return;
        }

        // Space / Return: toggle Line
        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return) {
            root.keyboardMode = true;
            game.toggleEdge(game.cursorEdge, 1);
            event.accepted = true;
            return;
        }

        // X / Backspace: toggle Cross
        if (event.key === Qt.Key_X || event.key === Qt.Key_Backspace) {
            root.keyboardMode = true;
            game.toggleEdge(game.cursorEdge, 2);
            event.accepted = true;
            return;
        }

        // C / Delete: clear edge
        if (event.key === Qt.Key_C || event.key === Qt.Key_Delete) {
            root.keyboardMode = true;
            game.toggleEdge(game.cursorEdge, 0);
            event.accepted = true;
            return;
        }
    }
}
