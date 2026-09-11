import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "Components"

Item {
    id: root

    signal startGame(string difficultyKey)
    signal resumeGame()
    signal openTutorial()

    property int scoresTick: 0

    onVisibleChanged: {
        if (visible)
            scoresTick++
    }

    Connections {
        target: game
        function onGameWon(points, fails, highscore, isNewRecord) {
            root.scoresTick++
        }
        function onGameStateChanged() {
            if (root.visible)
                root.scoresTick++
        }
    }

    // Help / Interactive Tutorial Button (top-left)
    Rectangle {
        id: helpBtn
        z: 50
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 18
        width: 42
        height: 42
        radius: 21
        color: helpMouseArea.pressed ? theme.selection :
               helpMouseArea.containsMouse ? theme.lighterBackground : theme.darkBackground
        border.color: helpMouseArea.containsMouse ? theme.accent : theme.selection
        border.width: helpMouseArea.containsMouse ? 2 : 1

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        Text {
            anchors.centerIn: parent
            text: "?"
            font.pixelSize: 20
            font.bold: true
            font.family: "JetBrainsMono Nerd Font, Liberation Sans, monospace"
            color: helpMouseArea.containsMouse ? theme.accent : theme.lightForeground
        }

        MouseArea {
            id: helpMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.openTutorial()
        }

        ToolTip.visible: helpMouseArea.containsMouse
        ToolTip.delay: 350
        ToolTip.text: "How to Play • Interactive Tutorial"
    }

    Flickable {
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: contentCol.implicitHeight + 48
        clip: true

        ColumnLayout {
            id: contentCol
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width - 48, 640)
            spacing: 24

            Item { height: 16 }

            // Hero Header
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8

                // Slitherlink Loop Badge (Jeweled with Omarchy theme colors)
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 72
                    height: 72
                    radius: 16
                    color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.15)
                    border.color: theme.accent
                    border.width: 2

                    Canvas {
                        id: logoCanvas
                        anchors.fill: parent
                        anchors.margins: 12
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            var w = width;
                            var h = height;

                            // Draw a clean closed loop connecting dots
                            ctx.lineWidth = 4;
                            ctx.lineCap = "round";
                            ctx.lineJoin = "round";
                            ctx.strokeStyle = theme.accent;

                            ctx.beginPath();
                            ctx.moveTo(w * 0.2, h * 0.2);
                            ctx.lineTo(w * 0.8, h * 0.2);
                            ctx.lineTo(w * 0.8, h * 0.5);
                            ctx.lineTo(w * 0.5, h * 0.5);
                            ctx.lineTo(w * 0.5, h * 0.8);
                            ctx.lineTo(w * 0.2, h * 0.8);
                            ctx.closePath();
                            ctx.fillStyle = Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.12);
                            ctx.fill();
                            ctx.stroke();

                            // Corner dots
                            var dots = [
                                [w * 0.2, h * 0.2, theme.green],
                                [w * 0.5, h * 0.2, theme.selection],
                                [w * 0.8, h * 0.2, theme.cyan],
                                [w * 0.2, h * 0.5, theme.selection],
                                [w * 0.5, h * 0.5, theme.yellow],
                                [w * 0.8, h * 0.5, theme.orange],
                                [w * 0.2, h * 0.8, theme.magenta],
                                [w * 0.5, h * 0.8, theme.green],
                                [w * 0.8, h * 0.8, theme.selection]
                            ];

                            for (var i = 0; i < dots.length; ++i) {
                                ctx.fillStyle = dots[i][2];
                                ctx.beginPath();
                                ctx.arc(dots[i][0], dots[i][1], 3.5, 0, Math.PI * 2);
                                ctx.fill();
                            }
                        }

                        Connections {
                            target: theme
                            function onThemeChanged() { logoCanvas.requestPaint(); }
                        }
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "SLITHERLINK"
                    font.pixelSize: 30
                    font.bold: true
                    font.letterSpacing: 4
                    color: theme.foreground
                }
            }

            // Resume Game Card (if saved game exists)
            Rectangle {
                visible: game.canResume
                Layout.fillWidth: true
                implicitHeight: 64
                radius: 12
                color: Qt.rgba(theme.green.r, theme.green.g, theme.green.b, 0.15)
                border.color: theme.green
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    spacing: 12

                    Text {
                        text: "▶"
                        font.pixelSize: 20
                        color: theme.green
                    }

                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "Resume Unfinished Game"
                            font.pixelSize: 15
                            font.bold: true
                            color: theme.foreground
                        }
                        Text {
                            text: "Pick up right where you left off"
                            font.pixelSize: 12
                            color: theme.muted
                        }
                    }

                    Item { Layout.fillWidth: true }

                    CustomButton {
                        text: "Resume"
                        isPrimary: true
                        customColor: theme.green
                        customTextColor: theme.darkerBackground
                        fontSize: 13
                        implicitHeight: 36
                        implicitWidth: 100
                        onClicked: root.resumeGame()
                    }
                }
            }

            Text {
                text: "CHOOSE DIFFICULTY"
                font.pixelSize: 12
                font.bold: true
                font.letterSpacing: 1.5
                color: theme.muted
                Layout.leftMargin: 4
            }

            // 4 Difficulty Cards Grid
            GridLayout {
                Layout.fillWidth: true
                columns: parent.width > 500 ? 2 : 1
                rowSpacing: 12
                columnSpacing: 12

                Repeater {
                    model: [
                        { key: "simple", name: "Easy", size: "7×7", clues: "~22 clues", badge: "Par 03:00", color: theme.green, desc: "Relaxed 7×7 grid, accessible deductions" },
                        { key: "medium", name: "Medium", size: "10×10", clues: "~45 clues", badge: "Par 07:00", color: theme.cyan, desc: "Balanced 10×10 challenge with intricate patterns" },
                        { key: "hard", name: "Hard", size: "15×15", clues: "~95 clues", badge: "Par 15:00", color: theme.orange, desc: "Expansive 15×15 grid demanding loop analysis" },
                        { key: "master", name: "Master", size: "20×20", clues: "~160 clues", badge: "Par 25:00", color: theme.magenta, desc: "Epic 20×20 grid for grandmasters; really hard" }
                    ]

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 110
                        radius: 12
                        color: cardMouse.containsMouse ? Qt.rgba(modelData.color.r, modelData.color.g, modelData.color.b, 0.12) : theme.darkBackground
                        border.color: cardMouse.containsMouse ? modelData.color : Qt.rgba(modelData.color.r, modelData.color.g, modelData.color.b, 0.3)
                        border.width: cardMouse.containsMouse ? 2 : 1
                        clip: true

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        // Left vertical accent stripe
                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 4
                            color: modelData.color
                            opacity: cardMouse.containsMouse ? 1.0 : 0.7
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 18
                            anchors.rightMargin: 14
                            anchors.topMargin: 14
                            anchors.bottomMargin: 14
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: modelData.name + " (" + modelData.size + ")"
                                    font.pixelSize: 17
                                    font.bold: true
                                    color: modelData.color
                                }

                                Item { Layout.fillWidth: true }

                                // Par badge
                                Rectangle {
                                    implicitHeight: 22
                                    implicitWidth: badgeTxt.implicitWidth + 12
                                    radius: 11
                                    color: Qt.rgba(modelData.color.r, modelData.color.g, modelData.color.b, 0.2)
                                    Text {
                                        id: badgeTxt
                                        anchors.centerIn: parent
                                        text: modelData.badge
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: modelData.color
                                    }
                                }
                            }

                            Text {
                                text: modelData.desc
                                font.pixelSize: 12
                                color: theme.muted
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Item { Layout.fillHeight: true }

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: modelData.clues
                                    font.pixelSize: 11
                                    color: theme.muted
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    property int hs: {
                                        var _tick = root.scoresTick
                                        return game.getHighscoreFor(modelData.key)
                                    }
                                    text: hs > 0 ? ("Best: " + hs.toLocaleString()) : "No record"
                                    font.pixelSize: 11
                                    font.bold: hs > 0
                                    color: hs > 0 ? theme.yellow : theme.muted
                                }
                            }
                        }

                        MouseArea {
                            id: cardMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.startGame(modelData.key)
                        }
                    }
                }
            }

            // Controls Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 90
                radius: 12
                color: theme.darkerBackground
                border.color: theme.selection
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Text {
                        text: "HOW TO PLAY & CONTROLS"
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 1
                        color: theme.muted
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        ColumnLayout {
                            spacing: 2
                            Text { text: "Mouse / Drag"; font.pixelSize: 11; font.bold: true; color: theme.accent }
                            Text { text: "Left click/drag: Line • Right click/drag: Cross"; font.pixelSize: 11; color: theme.muted }
                        }

                        Rectangle { width: 1; height: 28; color: theme.selection }

                        ColumnLayout {
                            spacing: 2
                            Text { text: "Keyboard Edge Cursor"; font.pixelSize: 11; font.bold: true; color: theme.foreground }
                            Text { text: "Arrows / HJKL • Space: Line • X: Cross"; font.pixelSize: 11; color: theme.muted }
                        }

                        Rectangle { width: 1; height: 28; color: theme.selection }

                        ColumnLayout {
                            spacing: 2
                            Text { text: "Shortcuts & Menu"; font.pixelSize: 11; font.bold: true; color: theme.foreground }
                            Text { text: "P: Pause • Esc: Menu"; font.pixelSize: 11; color: theme.muted }
                        }
                    }
                }
            }

            Item { height: 16 }
        }
    }
}
