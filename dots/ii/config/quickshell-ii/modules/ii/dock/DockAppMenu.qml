pragma ComponentBehavior: Bound
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

/**
 * Right-click context menu for a dock app button:
 * New Window, Pin/Unpin, Quit all windows.
 */
PopupWindow {
    id: root

    required property var appListRoot
    property var appToplevel
    property var desktopEntry
    property bool show: false
    property real cachedCenterX: 0

    readonly property real rowHeight: 36
    readonly property real menuWidth: 200
    readonly property real margin: Appearance.sizes.elevationMargin
    readonly property real padding: 5

    function close() {
        root.show = false;
    }

    // Keep the dock revealed while the menu is open even if the cursor wanders off,
    // but auto-close when neither the menu nor the dock buttons are hovered.
    Timer {
        id: autoCloseTimer
        interval: 1000
        repeat: false
        onTriggered: {
            if (!menuMouseArea.containsMouse && !root.appListRoot.buttonHovered)
                root.close();
            else
                autoCloseTimer.restart();
        }
    }
    onShowChanged: {
        if (show)
            autoCloseTimer.restart();
    }

    anchor {
        window: root.QsWindow.window
        adjustment: PopupAdjustment.None
        gravity: Edges.Top | Edges.Right
        edges: Edges.Top | Edges.Left
    }

    visible: menuBackground.opacity > 0
    color: "transparent"
    implicitWidth: root.QsWindow.window?.width ?? 1
    implicitHeight: menuColumn.implicitHeight + root.padding * 2 + root.margin * 2

    MouseArea {
        id: menuMouseArea
        anchors.bottom: parent.bottom
        hoverEnabled: true
        implicitWidth: menuBackground.implicitWidth + root.margin * 2
        implicitHeight: menuColumn.implicitHeight + root.padding * 2 + root.margin
        x: root.cachedCenterX - width / 2

        StyledRectangularShadow {
            target: menuBackground
            opacity: menuBackground.opacity
            visible: menuBackground.opacity > 0
        }

        Rectangle {
            id: menuBackground
            readonly property real padding: 4
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            opacity: root.show ? 1 : 0
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }

            implicitWidth: menuColumn.implicitWidth + menuBackground.padding * 2
            implicitHeight: menuColumn.implicitHeight + menuBackground.padding * 2
            color: Appearance.colors.colLayer0
            radius: Appearance.rounding.normal
            border.width: 1
            border.color: Appearance.colors.colLayer0Border

            ColumnLayout {
                id: menuColumn
                anchors.centerIn: parent
                spacing: 0

                component MenuEntry: RippleButton {
                    id: entryButton
                    required property string iconText
                    required property string labelText
                    property var triggerAction
                    buttonRadius: Appearance.rounding.small
                    horizontalPadding: 12
                    implicitWidth: root.menuWidth - menuBackground.padding * 2
                    implicitHeight: root.rowHeight
                    Layout.fillWidth: true
                    releaseAction: () => {
                        if (triggerAction)
                            triggerAction();
                        root.close();
                    }
                    contentItem: RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: entryButton.horizontalPadding
                        anchors.rightMargin: entryButton.horizontalPadding
                        spacing: 10
                        MaterialSymbol {
                            iconSize: 18
                            text: entryButton.iconText
                            color: Appearance.colors.colOnLayer0
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: entryButton.labelText
                            color: Appearance.colors.colOnLayer0
                        }
                    }
                }

                MenuEntry {
                    iconText: "add_circle"
                    labelText: Translation.tr("New Window")
                    triggerAction: () => {
                        root.desktopEntry?.execute();
                    }
                }
                MenuEntry {
                    iconText: TaskbarApps.isPinned(root.appToplevel?.appId ?? "") ? "keep_off" : "keep"
                    labelText: TaskbarApps.isPinned(root.appToplevel?.appId ?? "") ? Translation.tr("Unpin from Dock") : Translation.tr("Pin to Dock")
                    triggerAction: () => {
                        if (root.appToplevel)
                            TaskbarApps.togglePin(root.appToplevel.appId);
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Appearance.colors.colSubtext
                    Layout.topMargin: 4
                    Layout.bottomMargin: 4
                }
                MenuEntry {
                    iconText: "close"
                    labelText: Translation.tr("Quit")
                    enabled: (root.appToplevel?.toplevels.length ?? 0) > 0
                    triggerAction: () => {
                        for (const toplevel of root.appToplevel?.toplevels ?? [])
                            toplevel.close();
                    }
                }
            }
        }
    }
}
