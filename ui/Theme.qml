pragma Singleton
import QtQuick

QtObject {
    // ─── Core Palette ──────────────────────────────────────────────
    readonly property color background: "#07090f"
    readonly property color surface:    "#0d1117"
    readonly property color surface2:   "#161b22"
    readonly property color surface3:   "#1f2937"
    readonly property color border:     Qt.rgba(1, 1, 1, 0.08)
    readonly property color borderAccent: Qt.rgba(0.133, 0.827, 0.933, 0.3)
    readonly property color foreground: "#f0f6fc"
    readonly property color muted:      "#8b949e"

    // ─── Accent & Semantic Colors ──────────────────────────────────
    readonly property color accent:     "#22d3ee"
    readonly property color accentDim:  Qt.rgba(0.133, 0.827, 0.933, 0.12)
    readonly property color accentGlow: Qt.rgba(0.133, 0.827, 0.933, 0.06)
    readonly property color success:    "#3fb950"
    readonly property color warning:    "#d29922"
    readonly property color danger:     "#f85149"

    // ─── Typography ────────────────────────────────────────────────
    readonly property string fontSans: "Ubuntu Sans"
    readonly property string fontMono: "DejaVu Sans Mono"

    // ─── Layout ────────────────────────────────────────────────────
    readonly property int sidebarWidth: 180
    readonly property int radius:       10
    readonly property int radiusSmall:   6

    // ─── Helper Functions ──────────────────────────────────────────
    function withAlpha(baseColor, alpha) {
        return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, alpha);
    }
}
