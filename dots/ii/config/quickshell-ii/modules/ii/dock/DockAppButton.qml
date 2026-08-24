import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

DockButton {
    id: root
    property var appToplevel
    property var appListRoot
    property int lastFocused: -1
    property real iconSize: 35
    property bool appIsActive: appToplevel.toplevels.find(t => (t.activated == true)) !== undefined

    readonly property bool isSeparator: appToplevel.appId === "SEPARATOR"
    readonly property real maxScale: appListRoot.magnification ?? 1
    property var desktopEntry: DesktopEntries.heuristicLookup(appToplevel.appId)
    enabled: !isSeparator
    implicitWidth: isSeparator ? 1 : implicitHeight - topInset - bottomInset
    // Apple dock style: icons grow upward from a fixed bottom edge
    transformOrigin: Item.Bottom

    // Magnification: Gaussian falloff of scale around the cursor position
    scale: {
        if (isSeparator || !appListRoot.pointerInside || maxScale <= 1)
            return 1;
        const dx = mapFromItem(appListRoot.listView, appListRoot.cursorX, 0).x - width / 2;
        return 1 + (maxScale - 1) * Math.exp(-(dx * dx) / (2 * appListRoot.sigma * appListRoot.sigma));
    }
    Behavior on scale {
        NumberAnimation {
            alwaysRunToEnd: true
            duration: 100
            easing.type: Easing.OutQuad
        }
    }

    SequentialAnimation {
        id: launchBounceAnim
        NumberAnimation {
            target: iconWrap
            property: "scale"
            to: 1.25
            duration: 150
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: iconWrap
            property: "scale"
            to: 1
            duration: 400
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
        }
    }

    function bounce() {
        if (Config.options.dock.launchBounce ?? true)
            launchBounceAnim.restart();
    }

    Connections {
        target: DesktopEntries

        function onApplicationsChanged() {
            root.desktopEntry = DesktopEntries.heuristicLookup(appToplevel.appId);
        }
    }

    Loader {
        active: isSeparator
        anchors {
            fill: parent
            topMargin: dockVisualBackground.margin + dockRow.padding + Appearance.rounding.normal
            bottomMargin: dockVisualBackground.margin + dockRow.padding + Appearance.rounding.normal
        }
        sourceComponent: DockSeparator {}
    }

    Loader {
        anchors.fill: parent
        active: appToplevel.toplevels.length > 0
        sourceComponent: MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onEntered: {
                appListRoot.lastHoveredButton = root
                appListRoot.buttonHovered = true
                lastFocused = appToplevel.toplevels.length - 1
            }
            onExited: {
                if (appListRoot.lastHoveredButton === root) {
                    appListRoot.buttonHovered = false
                }
            }
        }
    }

    onClicked: {
        if (appToplevel.toplevels.length === 0) {
            root.bounce();
            root.desktopEntry?.execute();
            return;
        }
        lastFocused = (lastFocused + 1) % appToplevel.toplevels.length
        appToplevel.toplevels[lastFocused].activate()
    }

    middleClickAction: () => {
        root.bounce();
        root.desktopEntry?.execute();
    }

    altAction: () => {
        appListRoot.openContextMenuFor(root);
    }

    contentItem: Loader {
        active: !isSeparator
        sourceComponent: Item {
            id: iconWrap
            anchors.centerIn: parent

            Loader {
                id: iconImageLoader
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                active: !root.isSeparator
                sourceComponent: SquircleIcon {
                    iconName: AppSearch.guessIcon(appToplevel.appId)
                    iconSize: root.iconSize
                    clipToSquircle: Config.options.dock.squircleIcons ?? true
                }
            }

            Loader {
                active: Config.options.dock.monochromeIcons
                anchors.fill: iconImageLoader
                sourceComponent: Item {
                    Desaturate {
                        id: desaturatedIcon
                        visible: false // There's already color overlay
                        anchors.fill: parent
                        source: iconImageLoader
                        desaturation: 0.8
                    }
                    ColorOverlay {
                        anchors.fill: desaturatedIcon
                        source: desaturatedIcon
                        color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.9)
                    }
                }
            }

            // Single macOS-style running indicator dot under the icon
            Rectangle {
                anchors {
                    top: iconImageLoader.bottom
                    topMargin: 2
                    horizontalCenter: iconImageLoader.horizontalCenter
                }
                visible: appToplevel.toplevels.length > 0
                radius: Appearance.rounding.full
                implicitWidth: 4
                implicitHeight: 4
                color: appIsActive ? Appearance.colors.colPrimary : ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.55)
                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }
            }
        }
    }
}
