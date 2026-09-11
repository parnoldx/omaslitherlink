import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "Components"

Rectangle {
    id: root

    implicitHeight: 68
    height: 68
    color: theme.darkerBackground

    signal goHome()
    signal newGame()

    // Bottom separator line
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: theme.selection
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12

        // 1. Left section: Menu button
        Row {
            id: leftSection
            z: 10
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            visible: game.inGame

            CustomButton {
                id: backBtn
                text: "Menu"
                fontSize: 14
                implicitHeight: 44
                implicitWidth: 80
                radius: 12
                onClicked: root.goHome()
            }
        }

        // 2. Right section: Actions
        Row {
            id: rightSection
            z: 10
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            visible: game.inGame

            // Undo Button
            CustomButton {
                iconName: "undo"
                text: ""
                fontSize: 14
                implicitHeight: 44
                implicitWidth: 44
                radius: 12
                onClicked: game.undo()
            }

            // Pause Button
            CustomButton {
                iconName: game.isPaused ? "play" : "pause"
                text: ""
                fontSize: 14
                implicitHeight: 44
                implicitWidth: 44
                radius: 12
                onClicked: game.togglePause()
            }
        }

        // 3. Center section: Large, bold stat bubbles
        Item {
            id: centerContainer
            anchors.left: leftSection.right
            anchors.right: rightSection.left
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            Row {
                id: centerRow
                anchors.centerIn: parent
                spacing: root.width > 640 ? 8 : 4
                visible: game.inGame

                // Score Badge
                Rectangle {
                    implicitHeight: 44
                    implicitWidth: scoreRow.implicitWidth + 24
                    radius: 22
                    color: Qt.rgba(theme.yellow.r, theme.yellow.g, theme.yellow.b, 0.18)
                    border.color: Qt.rgba(theme.yellow.r, theme.yellow.g, theme.yellow.b, 0.6)
                    border.width: 2

                    Row {
                        id: scoreRow
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: "★"
                            font.pixelSize: 16
                            color: theme.yellow
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: game.points.toLocaleString()
                            font.pixelSize: 17
                            font.bold: true
                            color: theme.yellow
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // Multiplier Badge
                Rectangle {
                    id: factorBadge
                    implicitHeight: 44
                    implicitWidth: factorRow.implicitWidth + 22
                    radius: 22
                    color: Qt.rgba(theme.cyan.r, theme.cyan.g, theme.cyan.b, 0.18)
                    border.color: Qt.rgba(theme.cyan.r, theme.cyan.g, theme.cyan.b, 0.6)
                    border.width: 2

                    Row {
                        id: factorRow
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: "×"
                            font.pixelSize: 16
                            font.bold: true
                            color: theme.cyan
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: game.factor.toString()
                            font.pixelSize: 17
                            font.bold: true
                            color: theme.cyan
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Connections {
                        target: game
                        function onFactorChanged() {
                            factorPulseAnim.restart();
                        }
                    }

                    SequentialAnimation {
                        id: factorPulseAnim
                        PropertyAnimation { target: factorBadge; property: "scale"; to: 1.15; duration: 120 }
                        PropertyAnimation { target: factorBadge; property: "scale"; to: 1.0; duration: 180 }
                    }
                }

                // Fails / Series Badge
                Rectangle {
                    implicitHeight: 44
                    implicitWidth: failsRow.implicitWidth + 24
                    radius: 22
                    color: {
                        if (game.fails > 3) return Qt.rgba(theme.red.r, theme.red.g, theme.red.b, 0.28);
                        if (game.fails > 0) return Qt.rgba(theme.orange.r, theme.orange.g, theme.orange.b, 0.22);
                        return Qt.rgba(theme.green.r, theme.green.g, theme.green.b, 0.2);
                    }
                    border.width: 2
                    border.color: {
                        if (game.fails > 3) return theme.red;
                        if (game.fails > 0) return theme.orange;
                        return theme.green;
                    }

                    Row {
                        id: failsRow
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            text: {
                                var isNarrow = root.width < 660;
                                if (game.fails === 0) return isNarrow ? "✓ 0" : "✓ Perfect";
                                if (game.fails === 1) return isNarrow ? "✗ 1" : "✗ 1 Fail";
                                if (game.fails === 2) return isNarrow ? "✗ 2" : "✗ 2 Fails";
                                if (game.fails === 3) return isNarrow ? "✗ 3" : "✗ 3 Fails";
                                return isNarrow ? "⚡ " + game.fails : "⚡ BROKEN (" + game.fails + ")";
                            }
                            font.pixelSize: 15
                            font.bold: true
                            color: {
                                if (game.fails > 3) return theme.red;
                                if (game.fails > 0) return theme.orange;
                                return theme.green;
                            }
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // Timer Badge
                Rectangle {
                    implicitHeight: 44
                    implicitWidth: timerRow.implicitWidth + 22
                    radius: 22
                    color: Qt.rgba(theme.magenta.r, theme.magenta.g, theme.magenta.b, 0.18)
                    border.color: Qt.rgba(theme.magenta.r, theme.magenta.g, theme.magenta.b, 0.6)
                    border.width: 2

                    Row {
                        id: timerRow
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: "⏱"
                            font.pixelSize: 14
                            color: theme.magenta
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: game.formattedTime
                            font.pixelSize: 16
                            font.bold: true
                            font.family: "Monospace"
                            color: theme.magenta
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }
}
