import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "Components"

Item {
    id: root
    focus: true

    signal exitTutorial()
    signal startGame(string difficultyKey)

    // Current lesson index (0 to 4)
    property int currentStep: 0
    property bool stepCompleted: false

    // Lesson model definitions
    readonly property var lessons: [
        {
            title: "Single Closed Loop",
            subtitle: "Rule 1 · Objective",
            rows: 2,
            cols: 2,
            clues: [-1, -1, -1, -1],
            // 2x2 grid has 6 H-edges and 6 V-edges = 12 edges
            // Loop perimeter: h(0,0)=0, h(0,1)=1, v(0,2)=8, v(1,2)=11, h(2,1)=5, h(2,0)=4, v(1,0)=9, v(0,0)=6
            // Pre-draw 7 edges; leaving h(0,0) [edge 0] open
            initialEdges: [0, 1, 0, 0, 1, 1, 1, 0, 1, 1, 0, 1],
            hintEdge: 0,
            hintCell: -1,
            explanation: "Connect dots with line segments to form **one closed loop**.\n\n• No branches or intersections\n• No loose ends\n• Every visited dot connects exactly two lines",
            taskPrompt: "Click the open edge to close the loop.",
            successText: "Loop closed. Every dot on the loop connects exactly two lines."
        },
        {
            title: "The '0' Clue",
            subtitle: "Rule 2 · Clues & Crosses",
            rows: 2,
            cols: 2,
            clues: [0, -1, -1, -1],
            initialEdges: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
            hintEdge: -1,
            hintCell: 0,
            explanation: "Numbers show how many cell edges belong to the loop (0–3).\n\n**0** means none of its edges can be lines.\n\nMark unused edges with **×** (right-click, or click the '0') to rule them out.",
            taskPrompt: "Click the '0' or right-click its four edges to cross them out.",
            successText: "Edges crossed out. Eliminating edges reveals where the loop must go."
        },
        {
            title: "The '3' Clue",
            subtitle: "Rule 3 · Deduction",
            rows: 2,
            cols: 2,
            clues: [3, -1, -1, -1],
            // Cell (0,0) borders: top h(0,0)=0, bottom h(1,0)=2, left v(0,0)=6, right v(0,1)=7
            // Bottom border h(1,0)=2 is pre-crossed with x
            // Pre-drawn loop path: v(1,0)=9, h(2,0)=4, h(2,1)=5, v(1,2)=11, h(1,1)=3
            // Other crossed edges: h(0,1)=1, v(0,2)=8, v(1,1)=10
            initialEdges: [0, 2, 2, 1, 1, 1, 0, 0, 2, 1, 2, 1],
            hintEdge: -1,
            hintCell: 0,
            explanation: "A **3** requires three lines around the cell.\n\nIf one edge is crossed out, the remaining three edges must be lines.",
            taskPrompt: "Click the three open edges around the '3'.",
            successText: "Lines placed. The corner dot connects two edges without branching."
        },
        {
            title: "Dot Continuity",
            subtitle: "Rule 4 · In & Out",
            rows: 3,
            cols: 3,
            clues: [-1, -1, -1, -1, -1, -1, -1, -1, -1],
            // 3x3 grid has 12 H-edges and 12 V-edges = 24 edges
            // Dot at (1, 1):
            // Left incoming: h(1,0)=3 (line)
            // Leading into it: v(1,0)=16 (line)
            // Up leaving dot: v(0,1)=13 (cross 2)
            // Down leaving dot: v(1,1)=17 (cross 2)
            // Right leaving dot: h(1,1)=4 (open 0)
            initialEdges: [
                0, 0, 0,
                1, 0, 0,
                0, 0, 0,
                0, 0, 0,
                // V-edges (12..23)
                0, 2, 0, 0,
                1, 2, 0, 0,
                0, 0, 0, 0
            ],
            hintEdge: 4,
            hintCell: -1,
            explanation: "Every dot touched by the loop must have **exactly two lines**:\n\n• No dead ends (1 line)\n• No forks (3 or 4 lines)\n\nIf a path enters a dot and other directions are blocked, it must exit through the only open edge.",
            taskPrompt: "Click the open edge leaving the dot.",
            successText: "Path continued. A line entering a dot must always leave it."
        },
        {
            title: "Complete Puzzle",
            subtitle: "Rule 5 · Solve 3×3",
            rows: 3,
            cols: 3,
            // 3x3 verified unique puzzle
            clues: [
                2,  3, -1,
                2, -1,  0,
                3, -1,  0
            ],
            initialEdges: [
                0, 0, 0,
                0, 0, 0,
                0, 0, 0,
                0, 0, 0,
                0, 0, 0, 0,
                0, 0, 0, 0,
                0, 0, 0, 0
            ],
            hintEdge: -1,
            hintCell: -1,
            explanation: "Apply the rules to solve the 3×3 grid:\n\n1. Cross out edges around **0**s\n2. Fill lines around **3**s\n3. Extend lines through dots until the loop closes",
            taskPrompt: "Draw lines and mark crosses to complete the loop.",
            successText: "Puzzle solved. You are ready to play."
        }
    ]

    // Active board state for the current lesson
    property int boardRows: 2
    property int boardCols: 2
    property var boardClues: []
    property var boardEdges: [] // 0: empty, 1: line, 2: cross

    function numHEdges(r, c) { return (r + 1) * c; }
    function numVEdges(r, c) { return r * (c + 1); }
    function totalEdges(r, c) { return numHEdges(r, c) + numVEdges(r, c); }

    function loadLesson(index) {
        if (index < 0 || index >= lessons.length) return;
        currentStep = index;
        stepCompleted = false;

        var les = lessons[index];
        boardRows = les.rows;
        boardCols = les.cols;
        boardClues = les.clues.slice();
        boardEdges = les.initialEdges.slice();

        checkCurrentGoal();
    }

    onCurrentStepChanged: {
        loadLesson(currentStep);
    }

    Component.onCompleted: {
        loadLesson(0);
    }

    function checkCurrentGoal() {
        var completed = false;

        if (currentStep === 0) {
            // Target: edge 0 is a line
            completed = (boardEdges[0] === 1);
        } else if (currentStep === 1) {
            // Target: cell (0,0) borders (0, 2, 6, 7) are all crosses (2)
            completed = (boardEdges[0] === 2 && boardEdges[2] === 2 && boardEdges[6] === 2 && boardEdges[7] === 2);
        } else if (currentStep === 2) {
            // Target: cell (0,0) borders: h(0,0)=0, v(0,0)=6, v(0,1)=7 are all lines (1)
            completed = (boardEdges[0] === 1 && boardEdges[6] === 1 && boardEdges[7] === 1);
        } else if (currentStep === 3) {
            // Target: edge 4 is a line
            completed = (boardEdges[4] === 1);
        } else if (currentStep === 4) {
            // Target: 3x3 loop solution: [0, 1, 4, 9, 12, 14, 16, 17, 20, 21] are lines
            var solEdges = [0, 1, 4, 9, 12, 14, 16, 17, 20, 21];
            var match = true;
            for (var i = 0; i < 24; ++i) {
                var isSol = solEdges.indexOf(i) !== -1;
                if (isSol && boardEdges[i] !== 1) { match = false; break; }
                if (!isSol && boardEdges[i] === 1) { match = false; break; }
            }
            completed = match;
        }

        stepCompleted = completed;
    }

    function toggleEdgeState(edgeIdx, desiredState, isToggle) {
        if (edgeIdx < 0 || edgeIdx >= boardEdges.length) return;
        var newEdges = boardEdges.slice();

        if (isToggle) {
            newEdges[edgeIdx] = (newEdges[edgeIdx] === desiredState) ? 0 : desiredState;
        } else {
            newEdges[edgeIdx] = desiredState;
        }

        boardEdges = newEdges;
        checkCurrentGoal();
    }

    function autoCrossCell(cellR, cellC) {
        if (cellR < 0 || cellR >= boardRows || cellC < 0 || cellC >= boardCols) return;
        var top = cellR * boardCols + cellC;
        var bot = (cellR + 1) * boardCols + cellC;
        var vBase = numHEdges(boardRows, boardCols);
        var left = vBase + cellR * (boardCols + 1) + cellC;
        var right = vBase + cellR * (boardCols + 1) + (cellC + 1);

        var newEdges = boardEdges.slice();
        var borders = [top, bot, left, right];
        for (var i = 0; i < borders.length; ++i) {
            if (newEdges[borders[i]] === 0) {
                newEdges[borders[i]] = 2;
            }
        }
        boardEdges = newEdges;
        checkCurrentGoal();
    }

    // Keyboard navigation
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
            root.exitTutorial();
            event.accepted = true;
        } else if (event.key === Qt.Key_Right) {
            if (currentStep < lessons.length - 1) {
                loadLesson(currentStep + 1);
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Left) {
            if (currentStep > 0) {
                loadLesson(currentStep - 1);
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_R) {
            loadLesson(currentStep);
            event.accepted = true;
        }
    }

    // Confetti effect on Lesson 5 completion
    Repeater {
        model: (root.currentStep === 4 && root.stepCompleted) ? 28 : 0
        Rectangle {
            width: index % 2 === 0 ? 8 : 12
            height: index % 2 === 0 ? 12 : 8
            radius: 2
            x: (root.width / 28) * index + (index % 3 * 10)
            y: -20
            color: {
                var colors = [theme.cyan, theme.magenta, theme.yellow, theme.green, theme.orange, theme.accent];
                return colors[index % colors.length];
            }
            opacity: 0.85
            rotation: (index * 45) % 360

            SequentialAnimation on y {
                loops: Animation.Infinite
                NumberAnimation {
                    from: -20
                    to: root.height + 30
                    duration: 2200 + ((index * 139) % 1600)
                    easing.type: Easing.Linear
                }
            }

            SequentialAnimation on rotation {
                loops: Animation.Infinite
                NumberAnimation {
                    from: 0
                    to: 360
                    duration: 1500 + ((index * 113) % 1300)
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // 1. Tutorial Header Bar
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 64
            color: theme.darkerBackground

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: theme.selection
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 12

                CustomButton {
                    text: "← Menu"
                    fontSize: 14
                    implicitHeight: 38
                    implicitWidth: 90
                    radius: 10
                    onClicked: root.exitTutorial()
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "TUTORIAL"
                    font.pixelSize: 15
                    font.bold: true
                    font.letterSpacing: 2
                    color: theme.accent
                }

                Item { Layout.fillWidth: true }

                CustomButton {
                    text: "Reset"
                    fontSize: 13
                    implicitHeight: 38
                    implicitWidth: 72
                    radius: 10
                    onClicked: root.loadLesson(root.currentStep)
                }
            }
        }

        // 2. Step Navigator Tabs
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 48
            color: theme.darkBackground

            RowLayout {
                anchors.centerIn: parent
                spacing: 8

                Repeater {
                    model: root.lessons.length

                    Rectangle {
                        implicitHeight: 32
                        implicitWidth: Math.max(76, tabRow.implicitWidth + 20)
                        radius: 16
                        color: index === root.currentStep ?
                               Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.25) :
                               tabMouse.containsMouse ? theme.lighterBackground : theme.darkerBackground
                        border.color: index === root.currentStep ? theme.accent : theme.selection
                        border.width: index === root.currentStep ? 2 : 1

                        Row {
                            id: tabRow
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: (index + 1).toString()
                                font.pixelSize: 13
                                font.bold: true
                                color: index === root.currentStep ? theme.accent : theme.lightForeground
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: {
                                    var names = ["Loop", "0 Clue", "3 Clue", "Vertices", "Puzzle"];
                                    return names[index];
                                }
                                font.pixelSize: 12
                                font.bold: index === root.currentStep
                                color: index === root.currentStep ? theme.foreground : theme.lightForeground
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: tabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.loadLesson(index)
                        }
                    }
                }
            }
        }

        // 3. Main Split Content (Board on Left/Top, Lesson Instructions on Right/Bottom)
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Flickable {
                anchors.fill: parent
                contentWidth: parent.width
                contentHeight: mainContainer.implicitHeight + 32
                clip: true

                ColumnLayout {
                    id: mainContainer
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(parent.width - 32, 780)
                    spacing: 20

                    Item { height: 8 }

                    // Responsive Row/Column Layout
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 24
                        Layout.alignment: Qt.AlignHCenter

                        // --- LEFT: Interactive Board ---
                        Item {
                            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                            implicitWidth: 320
                            implicitHeight: 320

                            Rectangle {
                                id: boardBg
                                anchors.centerIn: parent
                                width: Math.max(280, boardCols * 80 + 36)
                                height: Math.max(280, boardRows * 80 + 36)
                                radius: 16
                                color: theme.darkerBackground
                                border.color: root.stepCompleted ? theme.green : theme.selection
                                border.width: root.stepCompleted ? 2 : 1

                                Behavior on border.color { ColorAnimation { duration: 200 } }

                                readonly property int cellSize: Math.floor((width - 36) / boardCols)
                                readonly property int pBoardWidth: cellSize * boardCols
                                readonly property int pBoardHeight: cellSize * boardRows
                                readonly property int boardLeft: Math.floor((width - pBoardWidth) / 2)
                                readonly property int boardTop: Math.floor((height - pBoardHeight) / 2)
                                readonly property int visibleLineWidth: 7
                                readonly property int edgeCorridor: 18

                                property int hoveredEdge: -1

                                function findEdgeAt(px, py) {
                                    var bx = px - boardLeft;
                                    var by = py - boardTop;
                                    var margin = 20;
                                    if (bx < -margin || bx > pBoardWidth + margin || by < -margin || by > pBoardHeight + margin)
                                        return -1;

                                    var cpx = Math.max(0, Math.min(pBoardWidth, bx));
                                    var cpy = Math.max(0, Math.min(pBoardHeight, by));

                                    var cellC = Math.min(boardCols - 1, Math.max(0, Math.floor(cpx / cellSize)));
                                    var cellR = Math.min(boardRows - 1, Math.max(0, Math.floor(cpy / cellSize)));

                                    var distTop = cpy - cellR * cellSize;
                                    var distBottom = (cellR + 1) * cellSize - cpy;
                                    var distLeft = cpx - cellC * cellSize;
                                    var distRight = (cellC + 1) * cellSize - cpx;

                                    var minDist = Math.min(distTop, distBottom, distLeft, distRight);
                                    if (minDist > edgeCorridor) return -1;

                                    // Clue 0 check
                                    var clueIdx = cellR * boardCols + cellC;
                                    if (boardClues[clueIdx] === 0) return -1;

                                    var vBase = root.numHEdges(boardRows, boardCols);
                                    if (minDist === distTop) {
                                        if (cellR > 0 && boardClues[(cellR - 1) * boardCols + cellC] === 0) return -1;
                                        return cellR * boardCols + cellC;
                                    } else if (minDist === distBottom) {
                                        if (cellR < boardRows - 1 && boardClues[(cellR + 1) * boardCols + cellC] === 0) return -1;
                                        return (cellR + 1) * boardCols + cellC;
                                    } else if (minDist === distLeft) {
                                        if (cellC > 0 && boardClues[cellR * boardCols + (cellC - 1)] === 0) return -1;
                                        return vBase + cellR * (boardCols + 1) + cellC;
                                    } else {
                                        if (cellC < boardCols - 1 && boardClues[cellR * boardCols + (cellC + 1)] === 0) return -1;
                                        return vBase + cellR * (boardCols + 1) + (cellC + 1);
                                    }
                                }

                                // Cell Clues
                                Repeater {
                                    model: boardRows * boardCols

                                    Rectangle {
                                        property int r: Math.floor(index / boardCols)
                                        property int c: index % boardCols
                                        property int clue: (boardClues && index < boardClues.length) ? boardClues[index] : -1
                                        visible: clue >= 0

                                        x: boardBg.boardLeft + c * boardBg.cellSize + 8
                                        y: boardBg.boardTop + r * boardBg.cellSize + 8
                                        width: boardBg.cellSize - 16
                                        height: boardBg.cellSize - 16
                                        radius: 8
                                        color: {
                                            if (root.lessons[root.currentStep].hintCell === index) {
                                                return Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.2);
                                            }
                                            return "transparent";
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: clue.toString()
                                            font.pixelSize: 26
                                            font.bold: true
                                            color: {
                                                if (clue === 0) return theme.lightForeground;
                                                if (clue === 3) return theme.yellow;
                                                if (clue === 2) return theme.cyan;
                                                return theme.foreground;
                                            }
                                        }

                                        // Click cell 0 to auto-cross
                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: clue === 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                            onClicked: {
                                                if (clue === 0) {
                                                    root.autoCrossCell(r, c);
                                                }
                                            }
                                        }
                                    }
                                }

                                // Interactive Lines Canvas
                                Canvas {
                                    id: edgeCanvas
                                    anchors.fill: parent

                                    Connections {
                                        target: root
                                        function onBoardEdgesChanged() { edgeCanvas.requestPaint(); }
                                    }

                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.clearRect(0, 0, width, height);

                                        var cs = boardBg.cellSize;
                                        var bLeft = boardBg.boardLeft;
                                        var bTop = boardBg.boardTop;
                                        var lw = boardBg.visibleLineWidth;

                                        var numH = root.numHEdges(boardRows, boardCols);
                                        var numV = root.numVEdges(boardRows, boardCols);
                                        var total = numH + numV;

                                        // 1. Draw loop lines (state === 1)
                                        ctx.lineWidth = lw;
                                        ctx.lineCap = "round";
                                        ctx.lineJoin = "round";
                                        ctx.strokeStyle = root.stepCompleted ? theme.green : theme.accent;

                                        for (var e = 0; e < total; ++e) {
                                            if (root.boardEdges[e] === 1) {
                                                var x1, y1, x2, y2;
                                                if (e < numH) {
                                                    var hr = Math.floor(e / boardCols);
                                                    var hc = e % boardCols;
                                                    x1 = bLeft + hc * cs;
                                                    y1 = bTop + hr * cs;
                                                    x2 = x1 + cs;
                                                    y2 = y1;
                                                } else {
                                                    var ve = e - numH;
                                                    var vr = Math.floor(ve / (boardCols + 1));
                                                    var vc = ve % (boardCols + 1);
                                                    x1 = bLeft + vc * cs;
                                                    y1 = bTop + vr * cs;
                                                    x2 = x1;
                                                    y2 = y1 + cs;
                                                }

                                                ctx.beginPath();
                                                ctx.moveTo(x1, y1);
                                                ctx.lineTo(x2, y2);
                                                ctx.stroke();
                                            }
                                        }

                                        // 2. Draw crosses (state === 2)
                                        ctx.font = "bold 16px monospace";
                                        ctx.fillStyle = theme.red;
                                        ctx.textAlign = "center";
                                        ctx.textBaseline = "middle";

                                        for (var e2 = 0; e2 < total; ++e2) {
                                            if (root.boardEdges[e2] === 2) {
                                                var mx, my;
                                                if (e2 < numH) {
                                                    var hr2 = Math.floor(e2 / boardCols);
                                                    var hc2 = e2 % boardCols;
                                                    mx = bLeft + hc2 * cs + cs / 2;
                                                    my = bTop + hr2 * cs;
                                                } else {
                                                    var ve2 = e2 - numH;
                                                    var vr2 = Math.floor(ve2 / (boardCols + 1));
                                                    var vc2 = ve2 % (boardCols + 1);
                                                    mx = bLeft + vc2 * cs;
                                                    my = bTop + vr2 * cs + cs / 2;
                                                }
                                                ctx.fillText("×", mx, my);
                                            }
                                        }
                                    }
                                }

                                // Pulsing hint indicator on target edge
                                Rectangle {
                                    id: hintGlow
                                    visible: root.lessons[root.currentStep].hintEdge >= 0 &&
                                             root.boardEdges[root.lessons[root.currentStep].hintEdge] === 0

                                    property int he: root.lessons[root.currentStep].hintEdge
                                    property int numH: root.numHEdges(boardRows, boardCols)
                                    property bool isH: he < numH

                                    x: {
                                        if (he < 0) return 0;
                                        var cs = boardBg.cellSize;
                                        if (isH) {
                                            return boardBg.boardLeft + (he % boardCols) * cs + 4;
                                        } else {
                                            return boardBg.boardLeft + ((he - numH) % (boardCols + 1)) * cs - 4;
                                        }
                                    }
                                    y: {
                                        if (he < 0) return 0;
                                        var cs = boardBg.cellSize;
                                        if (isH) {
                                            return boardBg.boardTop + Math.floor(he / boardCols) * cs - 4;
                                        } else {
                                            return boardBg.boardTop + Math.floor((he - numH) / (boardCols + 1)) * cs + 4;
                                        }
                                    }
                                    width: isH ? boardBg.cellSize - 8 : 8
                                    height: isH ? 8 : boardBg.cellSize - 8
                                    radius: 4
                                    color: theme.yellow

                                    SequentialAnimation on opacity {
                                        loops: Animation.Infinite
                                        NumberAnimation { from: 0.2; to: 0.9; duration: 600; easing.type: Easing.InOutQuad }
                                        NumberAnimation { from: 0.9; to: 0.2; duration: 600; easing.type: Easing.InOutQuad }
                                    }
                                }

                                // Hover Preview
                                Rectangle {
                                    id: hoverEdgeItem
                                    visible: boardBg.hoveredEdge >= 0 && root.boardEdges[boardBg.hoveredEdge] === 0
                                    property int he: boardBg.hoveredEdge
                                    property int numH: root.numHEdges(boardRows, boardCols)
                                    property bool isH: he < numH

                                    x: {
                                        if (he < 0) return 0;
                                        var cs = boardBg.cellSize;
                                        if (isH) {
                                            return boardBg.boardLeft + (he % boardCols) * cs + 2;
                                        } else {
                                            return boardBg.boardLeft + ((he - numH) % (boardCols + 1)) * cs - 3;
                                        }
                                    }
                                    y: {
                                        if (he < 0) return 0;
                                        var cs = boardBg.cellSize;
                                        if (isH) {
                                            return boardBg.boardTop + Math.floor(he / boardCols) * cs - 3;
                                        } else {
                                            return boardBg.boardTop + Math.floor((he - numH) / (boardCols + 1)) * cs + 2;
                                        }
                                    }
                                    width: isH ? boardBg.cellSize - 4 : 6
                                    height: isH ? 6 : boardBg.cellSize - 4
                                    radius: 3
                                    color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.45)
                                }

                                // Dots at grid vertices
                                Repeater {
                                    model: (boardRows + 1) * (boardCols + 1)

                                    Rectangle {
                                        property int r: Math.floor(index / (boardCols + 1))
                                        property int c: index % (boardCols + 1)

                                        x: boardBg.boardLeft + c * boardBg.cellSize - 4
                                        y: boardBg.boardTop + r * boardBg.cellSize - 4
                                        width: 8
                                        height: 8
                                        radius: 4
                                        color: theme.selection
                                        border.color: theme.lighterBackground
                                        border.width: 1
                                    }
                                }

                                // Mouse handler for drawing and crossing
                                MouseArea {
                                    id: boardMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    cursorShape: boardBg.hoveredEdge >= 0 ? Qt.PointingHandCursor : Qt.ArrowCursor

                                    property int dragMode: 0
                                    property int lastDraggedEdge: -1

                                    onPositionChanged: function(mouse) {
                                        boardBg.hoveredEdge = boardBg.findEdgeAt(mouse.x, mouse.y);
                                        if (boardMouse.pressed && dragMode !== 0) {
                                            var edge = boardBg.findEdgeAt(mouse.x, mouse.y);
                                            if (edge >= 0 && edge !== lastDraggedEdge) {
                                                lastDraggedEdge = edge;
                                                root.toggleEdgeState(edge, dragMode, false);
                                            }
                                        }
                                    }

                                    onReleased: {
                                        dragMode = 0;
                                        lastDraggedEdge = -1;
                                    }

                                    onExited: {
                                        boardBg.hoveredEdge = -1;
                                        dragMode = 0;
                                        lastDraggedEdge = -1;
                                    }

                                    onPressed: function(mouse) {
                                        var edge = boardBg.findEdgeAt(mouse.x, mouse.y);
                                        if (edge >= 0) {
                                            dragMode = (mouse.button === Qt.LeftButton) ? 1 : 2;
                                            lastDraggedEdge = edge;
                                            root.toggleEdgeState(edge, dragMode, true);
                                        } else {
                                            // Click in cell interior
                                            var bx = mouse.x - boardBg.boardLeft;
                                            var by = mouse.y - boardBg.boardTop;
                                            var cellC = Math.floor(bx / boardBg.cellSize);
                                            var cellR = Math.floor(by / boardBg.cellSize);
                                            if (cellR >= 0 && cellR < boardRows && cellC >= 0 && cellC < boardCols) {
                                                if (boardClues[cellR * boardCols + cellC] === 0) {
                                                    root.autoCrossCell(cellR, cellC);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // --- RIGHT: Lesson Card & Guidance ---
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 16

                            // Lesson Banner
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: lessonCol.implicitHeight + 28
                                radius: 14
                                color: theme.darkBackground
                                border.color: theme.selection
                                border.width: 1

                                ColumnLayout {
                                    id: lessonCol
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 10

                                    RowLayout {
                                        spacing: 8
                                        Rectangle {
                                            implicitHeight: 22
                                            implicitWidth: 84
                                            radius: 11
                                            color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.2)
                                            Text {
                                                anchors.centerIn: parent
                                                text: "STEP " + (root.currentStep + 1) + " OF " + root.lessons.length
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: theme.accent
                                            }
                                        }

                                        Text {
                                            text: root.lessons[root.currentStep].subtitle
                                            font.pixelSize: 12
                                            color: theme.lightForeground
                                        }
                                    }

                                    Text {
                                        text: root.lessons[root.currentStep].title
                                        font.pixelSize: 20
                                        font.bold: true
                                        color: theme.foreground
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: root.lessons[root.currentStep].explanation
                                        font.pixelSize: 13
                                        lineHeight: 1.35
                                        color: theme.lightForeground
                                        textFormat: Text.MarkdownText
                                        wrapMode: Text.WordWrap
                                    }
                                }
                            }

                            // Interactive Objective & Feedback
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: objCol.implicitHeight + 24
                                radius: 14
                                color: root.stepCompleted ?
                                       Qt.rgba(theme.green.r, theme.green.g, theme.green.b, 0.15) :
                                       Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.1)
                                border.color: root.stepCompleted ? theme.green : theme.accent
                                border.width: 2

                                Behavior on color { ColorAnimation { duration: 200 } }
                                Behavior on border.color { ColorAnimation { duration: 200 } }

                                ColumnLayout {
                                    id: objCol
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    spacing: 6

                                    RowLayout {
                                        spacing: 8
                                        Text {
                                            text: root.stepCompleted ? "✓ COMPLETE" : "TASK"
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: root.stepCompleted ? theme.green : theme.accent
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: root.stepCompleted ?
                                              root.lessons[root.currentStep].successText :
                                              root.lessons[root.currentStep].taskPrompt
                                        font.pixelSize: 13
                                        font.bold: root.stepCompleted
                                        lineHeight: 1.3
                                        color: root.stepCompleted ? theme.green : theme.foreground
                                        wrapMode: Text.WordWrap
                                    }
                                }
                            }

                            // Action Buttons
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                CustomButton {
                                    text: "← Previous"
                                    fontSize: 13
                                    implicitHeight: 42
                                    Layout.fillWidth: true
                                    radius: 10
                                    enabled: root.currentStep > 0
                                    opacity: enabled ? 1.0 : 0.4
                                    onClicked: root.loadLesson(root.currentStep - 1)
                                }

                                CustomButton {
                                    visible: root.currentStep < root.lessons.length - 1
                                    text: "Next →"
                                    fontSize: 13
                                    implicitHeight: 42
                                    Layout.fillWidth: true
                                    radius: 10
                                    isPrimary: root.stepCompleted
                                    isOutlined: !root.stepCompleted
                                    onClicked: root.loadLesson(root.currentStep + 1)
                                }

                                CustomButton {
                                    visible: root.currentStep === root.lessons.length - 1
                                    text: "Play Easy (7×7)"
                                    fontSize: 14
                                    implicitHeight: 42
                                    Layout.fillWidth: true
                                    radius: 10
                                    isPrimary: true
                                    onClicked: root.startGame("simple")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
