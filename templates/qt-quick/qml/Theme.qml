pragma Singleton

import QtQuick

QtObject {
    readonly property color background: "#111827"
    readonly property color surface: "#1f2937"
    readonly property color surfaceRaised: "#374151"
    readonly property color textPrimary: "#f9fafb"
    readonly property color textSecondary: "#cbd5e1"
    readonly property color accent: "#60a5fa"
    readonly property color accentSoft: "#1e3a5f"

    readonly property string fontFamily: "sans-serif"
    readonly property int fontSizeBody: 16
    readonly property int fontSizeTitle: 30
    readonly property int fontWeightTitle: Font.DemiBold

    readonly property int spaceXs: 4
    readonly property int spaceSm: 8
    readonly property int spaceMd: 16
    readonly property int spaceLg: 24
    readonly property int spaceXl: 32

    readonly property int radiusSm: 8
    readonly property int radiusMd: 16

    readonly property int motionFast: 120
    readonly property int motionNormal: 220
    readonly property int easingStandard: Easing.OutCubic
}
