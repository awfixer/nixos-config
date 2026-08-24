import qs.modules.common
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Widgets

/**
 * An app icon clipped to an Apple-style squircle (continuous-looking corners).
 * Set clipToSquircle to false to render the icon unclipped.
 */
Item {
    id: root

    property string iconName
    property real iconSize: 48
    property bool clipToSquircle: true
    // macOS app icon corner ratio (~22.6% of the tile size)
    property real cornerRadiusRatio: 0.226

    width: iconSize
    height: iconSize
    readonly property real cornerRadius: iconSize * cornerRadiusRatio

    IconImage {
        anchors.fill: parent
        source: Quickshell.iconPath(root.iconName, "image-missing")
        visible: root.clipToSquircle
        layer.enabled: root.clipToSquircle
        // NOTE: relies on the mask source being a hidden layered item,
        // which still renders offscreen; see squircleMask below.
        layer.effect: OpacityMask {
            maskSource: squircleMask
        }
    }

    // Unclipped fallback when squircles are disabled
    IconImage {
        anchors.fill: parent
        source: Quickshell.iconPath(root.iconName, "image-missing")
        visible: !root.clipToSquircle
    }

    Shape {
        id: squircleMask
        visible: false
        layer.enabled: true
        anchors.fill: parent

        ShapePath {
            strokeWidth: -1
            fillColor: "black" // Only the alpha channel matters for OpacityMask
            PathSvg {
                path: root.squirclePath(root.width, root.height, root.cornerRadius)
            }
        }
    }

    // Rounded rect where each corner is one cubic Bezier. The control-point
    // offset o pushes the curve shoulders outward: o = 0.4477 * r is a plain
    // circular corner, smaller values give the fuller, continuous "squircle" look.
    function squirclePath(w, h, r) {
        const o = r * 0.3;
        return `M ${r} 0
            L ${w - r} 0
            C ${w - o} 0 ${w} ${o} ${w} ${r}
            L ${w} ${h - r}
            C ${w} ${h - o} ${w - o} ${h} ${w - r} ${h}
            L ${r} ${h}
            C ${o} ${h} 0 ${h - o} 0 ${h - r}
            L 0 ${r}
            C 0 ${o} ${o} 0 ${r} 0 Z`;
    }
}
