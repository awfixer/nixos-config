pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland // GlobalShortcut lives here on the pinned 0.2.x engine (core-level in 0.3+)

/**
 * Full-screen app launcher grid, opened GNOME-Shell style:
 * dimmed backdrop fades in while the grid scales up and its icons
 * stagger-pop into place. Closing reverses the effect quickly.
 */
Scope {
    id: root

    PanelWindow {
        id: panelWindow

        // While exiting, stay visible until the fade-out finished
        visible: GlobalStates.appGridOpen || content.opacity > 0.001
        WlrLayershell.namespace: "quickshell:appgrid"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: GlobalStates.appGridOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        readonly property int gridColumns: 6
        readonly property real cellWidth: 108
        readonly property real cellHeight: 130
        readonly property real iconSize: 58

        // Populated instantly on open, cleared on close so the stagger replays
        property bool contentShown: false

        Timer {
            id: contentShowDelay
            interval: 40
            onTriggered: {
                panelWindow.contentShown = true;
                searchInput.forceActiveFocus();
            }
        }

        Connections {
            target: GlobalStates
            function onAppGridOpenChanged() {
                if (GlobalStates.appGridOpen) {
                    searchInput.text = "";
                    contentShowDelay.restart();
                    GlobalFocusGrab.addDismissable(panelWindow);
                } else {
                    panelWindow.contentShown = false;
                }
            }
        }

        Connections {
            target: GlobalFocusGrab
            function onDismissed() {
                GlobalStates.appGridOpen = false;
            }
        }

        function close() {
            GlobalStates.appGridOpen = false;
        }

        // Dimmed backdrop, GNOME style
        Rectangle {
            id: scrim
            anchors.fill: parent
            color: ColorUtils.transparentize(Appearance.m3colors.m3scrim, 0.42)
            opacity: GlobalStates.appGridOpen ? 1 : 0
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }

        // Closes on any click that lands on the backdrop
        MouseArea {
            anchors.fill: parent
            onClicked: panelWindow.close()
        }

        Item {
            id: content
            anchors.fill: parent

            opacity: GlobalStates.appGridOpen ? 1 : 0
            scale: GlobalStates.appGridOpen ? 1 : 0.94
            Behavior on opacity {
                animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
            }
            Behavior on scale {
                animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
            }

            Keys.onEscapePressed: panelWindow.close()

            ColumnLayout {
                id: contentColumn
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                    topMargin: parent.height * 0.09
                }
                spacing: 24

                // ------------------------------------------------ search --
                Rectangle {
                    id: searchPill
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: Appearance.sizes.searchWidth
                    implicitHeight: 46
                    radius: Appearance.rounding.full
                    color: Appearance.colors.colLayer1
                    border.width: 1
                    border.color: searchInput.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border
                    Behavior on border.color {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 18
                        spacing: 10

                        MaterialSymbol {
                            text: "search"
                            iconSize: 20
                            color: Appearance.colors.colSubtext
                        }
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            TextInput {
                                id: searchInput
                                anchors.fill: parent
                                verticalAlignment: TextInput.AlignVCenter
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.family: Appearance.font.family.main
                                color: Appearance.colors.colOnLayer0
                                clip: true

                                Keys.onEscapePressed: panelWindow.close()
                                Keys.onReturnPressed: {
                                    const apps = grid.displayedApps;
                                    if (apps.length > 0) {
                                        apps[0].execute();
                                        panelWindow.close();
                                    }
                                }
                            }
                            StyledText {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                visible: searchInput.text === ""
                                text: Translation.tr("Type to search…")
                                color: Appearance.colors.colSubtext
                                font.pixelSize: Appearance.font.pixelSize.normal
                            }
                        }
                    }
                }

                // -------------------------------------------------- grid --
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    visible: grid.count === 0
                    text: Translation.tr("No results")
                    color: Appearance.colors.colSubtext
                }

                GridView {
                    id: grid
                    readonly property var displayedApps: searchInput.text.trim().length > 0 ? AppSearch.fuzzyQuery(searchInput.text.trim()) : AppSearch.list

                    Layout.preferredWidth: panelWindow.gridColumns * panelWindow.cellWidth
                    Layout.preferredHeight: contentColumn.parent.height * 0.68
                    Layout.alignment: Qt.AlignHCenter

                    model: ScriptModel {
                        objectProp: "id"
                        values: [...grid.displayedApps]
                    }
                    cellWidth: panelWindow.cellWidth
                    cellHeight: panelWindow.cellHeight
                    boundsBehavior: Flickable.StopAtBounds
                    // One row per swipe, like the GNOME app grid pages
                    snapMode: GridView.SnapOneRow
                    highlightRangeMode: GridView.StrictlyEnforceRange
                    preferredHighlightBegin: 0
                    preferredHighlightEnd: panelWindow.cellHeight
                    flickDeceleration: 5000
                    maximumFlickVelocity: 1800

                    delegate: RippleButton {
                        id: appTile

                        required property int index
                        required property var modelData

                        buttonRadius: Appearance.rounding.normal
                        implicitWidth: panelWindow.cellWidth - 8
                        implicitHeight: panelWindow.cellHeight - 8
                        pointingHandCursor: true

                        releaseAction: () => {
                            appTile.modelData.execute();
                            panelWindow.close();
                        }
                        altAction: () => {
                            TaskbarApps.togglePin(appTile.modelData.id);
                        }

                        scale: panelWindow.contentShown ? 1 : 0.4
                        opacity: panelWindow.contentShown ? 1 : 0
                        Behavior on scale {
                            SequentialAnimation {
                                PauseAnimation { duration: panelWindow.contentShown ? Math.min(appTile.index * 6, 260) : 0 }
                                NumberAnimation {
                                    duration: 280
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
                                }
                            }
                        }
                        Behavior on opacity {
                            SequentialAnimation {
                                PauseAnimation { duration: panelWindow.contentShown ? Math.min(appTile.index * 6, 260) : 0 }
                                NumberAnimation { duration: 220 }
                            }
                        }

                        contentItem: ColumnLayout {
                            spacing: 8

                            Item {
                                Layout.alignment: Qt.AlignHCenter
                                implicitWidth: panelWindow.iconSize
                                implicitHeight: panelWindow.iconSize

                                SquircleIcon {
                                    anchors.fill: parent
                                    iconName: appTile.modelData.icon
                                    iconSize: panelWindow.iconSize
                                    clipToSquircle: Config.options.dock.squircleIcons ?? true
                                }
                                MaterialSymbol {
                                    visible: TaskbarApps.isPinned(appTile.modelData.id ?? "")
                                    anchors {
                                        right: parent.right
                                        top: parent.top
                                    }
                                    text: "keep"
                                    iconSize: 14
                                    color: Appearance.colors.colPrimary
                                }
                            }

                            StyledText {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: appTile.modelData.name
                                elide: Text.ElideRight
                                font.pixelSize: Appearance.font.pixelSize.smallie
                                color: Appearance.colors.colOnLayer0
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "appgrid"

        function toggle(): void {
            GlobalStates.appGridOpen = !GlobalStates.appGridOpen;
        }
        function open(): void {
            GlobalStates.appGridOpen = true;
        }
        function close(): void {
            GlobalStates.appGridOpen = false;
        }
    }

    GlobalShortcut {
        name: "appGridToggle"
        description: "Toggles the full-screen app grid"

        onPressed: {
            GlobalStates.appGridOpen = !GlobalStates.appGridOpen;
        }
    }
}
