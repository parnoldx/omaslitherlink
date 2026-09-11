import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "Components"

Item {
    id: root

    property int finalPoints: 0
    property int finalFails: 0
    property int currentHighscore: 0
    property bool isRecord: false
    property string finalTime: "00:00"

    signal playAgain()
    signal returnToMenu()

    // Multi-colored victory confetti in Omarchy theme colors
    Repeater {
        model: 24
        Rectangle {
            width: index % 2 === 0 ? 7 : 11
            height: index % 2 === 0 ? 11 : 7
            radius: 2
            x: (root.width / 24) * index + (index % 3 * 8)
            y: -20
            color: {
                var colors = [theme.cyan, theme.magenta, theme.yellow, theme.green, theme.orange, theme.accent];
                return colors[index % colors.length];
            }
            opacity: 0.8
            rotation: (index * 45) % 360

            SequentialAnimation on y {
                loops: Animation.Infinite
                NumberAnimation {
                    from: -20
                    to: root.height + 20
                    duration: 2200 + ((index * 173) % 1500)
                    easing.type: Easing.Linear
                }
            }

            SequentialAnimation on rotation {
                loops: Animation.Infinite
                NumberAnimation {
                    from: 0
                    to: 360
                    duration: 1600 + ((index * 127) % 1200)
                }
            }
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(parent.width - 48, 480)
        implicitHeight: winCol.implicitHeight + 48
        radius: 16
        color: theme.darkBackground
        border.color: root.isRecord ? theme.yellow : theme.selection
        border.width: root.isRecord ? 2 : 1

        ColumnLayout {
            id: winCol
            anchors.centerIn: parent
            width: parent.width - 48
            spacing: 20

            // Trophy / Star
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 72
                height: 72
                radius: 36
                color: Qt.rgba(theme.yellow.r, theme.yellow.g, theme.yellow.b, 0.15)
                border.color: theme.yellow
                border.width: 2

                Text {
                    anchors.centerIn: parent
                    text: root.finalFails === 0 ? "🏆" : "★"
                    font.pixelSize: 36
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 4

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.finalFails === 0 ? "PERFECT LOOP!" : "PUZZLE SOLVED!"
                    font.pixelSize: 22
                    font.bold: true
                    font.letterSpacing: 2
                    color: root.finalFails === 0 ? theme.green : theme.foreground
                }

                Text {
                    visible: root.isRecord
                    Layout.alignment: Qt.AlignHCenter
                    text: "✨ NEW HIGH SCORE RECORD! ✨"
                    font.pixelSize: 13
                    font.bold: true
                    color: theme.yellow
                }
            }

            // Stats Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: statsGrid.implicitHeight + 24
                radius: 10
                color: theme.darkerBackground
                border.color: theme.selection
                border.width: 1

                GridLayout {
                    id: statsGrid
                    anchors.fill: parent
                    anchors.margins: 14
                    columns: 2
                    rowSpacing: 10

                    Text { text: "Difficulty:"; color: theme.muted; font.pixelSize: 13 }
                    Text { text: game.difficultyLabel; color: theme.foreground; font.bold: true; font.pixelSize: 13; Layout.alignment: Qt.AlignRight }

                    Text { text: "Time:"; color: theme.muted; font.pixelSize: 13 }
                    Text { text: root.finalTime; color: theme.foreground; font.bold: true; font.family: "Monospace"; font.pixelSize: 13; Layout.alignment: Qt.AlignRight }

                    Text { text: "Errors:"; color: theme.muted; font.pixelSize: 13 }
                    Text {
                        text: {
                            if (root.finalFails === 0) return "None! Perfect!";
                            if (root.finalFails <= 3) {
                                var s = "";
                                for (var i = 0; i < root.finalFails; i++) s += "X ";
                                return s.trim();
                            }
                            return "Broken series (" + root.finalFails + ")";
                        }
                        color: root.finalFails === 0 ? theme.green : (root.finalFails <= 3 ? theme.orange : theme.red)
                        font.bold: true
                        font.pixelSize: 13
                        Layout.alignment: Qt.AlignRight
                    }

                    Text { text: "Score:"; color: theme.muted; font.pixelSize: 13 }
                    Text {
                        text: root.finalPoints.toLocaleString();
                        color: theme.yellow;
                        font.bold: true;
                        font.pixelSize: 16;
                        Layout.alignment: Qt.AlignRight
                    }

                    Text { text: "High Score:"; color: theme.muted; font.pixelSize: 13 }
                    Text {
                        text: root.currentHighscore.toLocaleString();
                        color: theme.accent;
                        font.bold: true;
                        font.pixelSize: 14;
                        Layout.alignment: Qt.AlignRight
                    }
                }
            }

            // Action Buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                CustomButton {
                    Layout.fillWidth: true
                    text: "Menu"
                    fontSize: 14
                    implicitHeight: 42
                    onClicked: root.returnToMenu()
                }

                CustomButton {
                    Layout.fillWidth: true
                    text: "Play Again"
                    isPrimary: true
                    fontSize: 14
                    implicitHeight: 42
                    onClicked: root.playAgain()
                }
            }
        }
    }
}
