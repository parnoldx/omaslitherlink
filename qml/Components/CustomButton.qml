import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property string text: ""
    property string iconName: ""
    property string iconText: ""
    property int iconSize: 18
    property bool isPrimary: false
    property bool isOutlined: false
    property bool isActive: false
    property string customColor: ""
    property string customTextColor: ""
    property int radius: 10
    property int fontSize: 14

    signal clicked()

    readonly property color contentColor: {
        if (root.isPrimary) return theme.background;
        if (root.customTextColor.length > 0) return root.customTextColor;
        if (root.isActive) return theme.accent;
        if (mouseArea.containsMouse) return theme.foreground;
        return theme.lightForeground;
    }

    readonly property string resolvedIconText: {
        if (root.iconText.length > 0) return root.iconText;
        switch (root.iconName) {
            case "undo": return "\uf0e2";
            case "pause": return "\uf04c";
            case "play": return "\uf04b";
            case "pencil": return "\uf040";
            case "clear": return "\uf00d";
            case "back": return "\uf060";
            case "check": return "\uf00c";
            default: return "";
        }
    }

    implicitWidth: {
        var hasIcon = root.resolvedIconText.length > 0;
        if (root.text.length > 0 && hasIcon) {
            return contentRow.implicitWidth + 24;
        } else if (root.text.length > 0) {
            return contentRow.implicitWidth + 24;
        } else {
            return implicitHeight;
        }
    }
    implicitHeight: 42

    Layout.preferredWidth: implicitWidth
    Layout.minimumWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    Layout.minimumHeight: implicitHeight

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: root.radius
        border.width: root.isOutlined || root.isActive ? 2 : 1

        border.color: {
            if (root.isActive) return theme.accent;
            if (root.isOutlined) return theme.accent;
            if (mouseArea.containsMouse) return theme.accent;
            return theme.selection;
        }

        color: {
            if (root.customColor.length > 0) {
                return mouseArea.pressed ? Qt.darker(root.customColor, 1.2) : root.customColor;
            }
            if (root.isPrimary) {
                return mouseArea.pressed ? Qt.darker(theme.accent, 1.2) :
                       mouseArea.containsMouse ? Qt.lighter(theme.accent, 1.1) : theme.accent;
            }
            if (root.isActive) {
                return Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.25);
            }
            if (mouseArea.pressed) {
                return theme.selection;
            }
            if (mouseArea.containsMouse) {
                return theme.lighterBackground;
            }
            return theme.darkBackground;
        }

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        Row {
            id: contentRow
            anchors.centerIn: parent
            spacing: root.resolvedIconText.length > 0 && root.text.length > 0 ? 8 : 0

            Text {
                id: iconGlyph
                textFormat: Text.PlainText
                text: root.resolvedIconText
                visible: root.resolvedIconText.length > 0
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: root.iconSize
                font.weight: 900
                font.family: "Font Awesome 7 Free, JetBrainsMono Nerd Font, sans-serif"
                color: root.contentColor
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                textFormat: Text.PlainText
                text: root.text
                visible: root.text.length > 0
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: root.fontSize
                font.bold: root.isPrimary || root.isActive
                font.family: "JetBrainsMono Nerd Font, Liberation Sans, monospace"
                color: root.contentColor
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
