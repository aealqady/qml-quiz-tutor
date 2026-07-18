import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: progressPage
    color: "transparent"

    // Remove mock data properties; we will use progressController directly

    // Component.onCompleted triggers a refresh to ensure data is up to date when the page loads
    Component.onCompleted: {
        if (typeof progressController !== "undefined") {
            progressController.refresh()
        }
    }
    
    // Connect to signals to trigger canvas repaints
    Connections {
        target: typeof progressController !== "undefined" ? progressController : null
        function onActivityChanged() { if (areaChart) areaChart.requestPaint() }
        function onTopicsChanged() { if (radarChart) radarChart.requestPaint() }
    }

    Flickable {
        anchors.fill: parent
        contentHeight: mainCol.implicitHeight + 64
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: mainCol
            width: Math.min(parent.width - 80, 1100)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 32
            spacing: 24

            // ─── Header ───────────────────────────────────────
            ColumnLayout {
                spacing: 6

                Text { text: "Analytics Dashboard"; color: Theme.foreground; font.family: Theme.fontSans; font.pixelSize: 22; font.weight: Font.Bold; font.letterSpacing: -0.4 }
                Text { text: "Performance trends, SRS schedule, and knowledge gap analysis."; color: Theme.muted; font.family: Theme.fontSans; font.pixelSize: 13 }
            }

            // ─── Stats Row ────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Repeater {
                    model: [
                        { label: "EXAMS COMPLETED", val: typeof progressController !== "undefined" ? progressController.examsCompleted : "0", sub: "Total completed exams", isAccent: true },
                        { label: "AVG EXAM SCORE", val: typeof progressController !== "undefined" ? progressController.avgScoreStr : "0%", sub: "Across all exams", isAccent: false },
                        { label: "QUESTIONS ANSWERED", val: typeof progressController !== "undefined" ? progressController.questionsAnswered : "0", sub: "across all exams", isAccent: false },
                        { label: "STUDY STREAK", val: typeof progressController !== "undefined" ? progressController.studyStreakStr : "0d", sub: "Consecutive study days", isAccent: false }
                    ]
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 100; radius: 10
                        color: Theme.surface
                        border.color: modelData.isAccent ? Theme.borderAccent : Theme.border
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 18; spacing: 0

                            Text { text: modelData.label; color: Theme.muted; font.family: Theme.fontMono; font.pixelSize: 10; font.letterSpacing: 0.8 }
                            Item { Layout.fillHeight: true }
                            Text { text: modelData.val; color: modelData.isAccent ? Theme.accent : Theme.foreground; font.family: Theme.fontMono; font.pixelSize: 26; font.weight: Font.Bold }
                            Text { text: modelData.sub; color: Theme.muted; font.family: Theme.fontSans; font.pixelSize: 11; Layout.topMargin: 4 }
                        }
                    }
                }
            }

            // ─── Charts Row: Daily Activity + SRS Schedule ────
            RowLayout {
                Layout.fillWidth: true
                spacing: 20

                // Daily Activity Area Chart
                Rectangle {
                    Layout.fillWidth: true
                    height: 260; radius: 10
                    color: Theme.surface
                    border.color: Theme.border; border.width: 1

                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 20; spacing: 12

                        Text { text: "DAILY ACTIVITY"; color: Theme.muted; font.family: Theme.fontMono; font.pixelSize: 10; font.letterSpacing: 0.8 }

                        Canvas {
                            id: areaChart
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                var data = typeof progressController !== "undefined" ? progressController.activityData : [];
                                if (!data || data.length === 0) return;

                                var padL = 30, padR = 10, padT = 10, padB = 24;
                                var w = width - padL - padR;
                                var h = height - padT - padB;
                                var maxVal = 12;

                                // Grid lines
                                ctx.strokeStyle = "rgba(255,255,255,0.04)";
                                ctx.lineWidth = 1;
                                ctx.setLineDash([3, 3]);
                                for (var g = 0; g <= 4; g++) {
                                    var gy = padT + h - (g / 4) * h;
                                    ctx.beginPath(); ctx.moveTo(padL, gy); ctx.lineTo(padL + w, gy); ctx.stroke();
                                }
                                ctx.setLineDash([]);

                                // Y axis labels
                                ctx.fillStyle = "#8b949e";
                                ctx.font = "9px 'DejaVu Sans Mono'";
                                ctx.textAlign = "right";
                                for (var yl = 0; yl <= 4; yl++) {
                                    var yVal = Math.round(maxVal * yl / 4);
                                    var yPos = padT + h - (yl / 4) * h;
                                    ctx.fillText(String(yVal), padL - 6, yPos + 3);
                                }

                                // X axis labels
                                ctx.textAlign = "center";
                                for (var xi = 0; xi < data.length; xi++) {
                                    var xp = padL + (xi / (data.length - 1)) * w;
                                    ctx.fillText(data[xi].day, xp, height - 2);
                                }

                                // Helper to get point coordinates
                                function getP(idx, key) {
                                    return {
                                        x: padL + (idx / (data.length - 1)) * w,
                                        y: padT + h - (data[idx][key] / maxVal) * h
                                    };
                                }

                                // Draw filled area + line for "correct"
                                // Gradient fill
                                var grad1 = ctx.createLinearGradient(0, padT, 0, padT + h);
                                grad1.addColorStop(0, "rgba(34,211,238,0.25)");
                                grad1.addColorStop(1, "rgba(34,211,238,0)");
                                ctx.fillStyle = grad1;
                                ctx.beginPath();
                                var p0 = getP(0, "correct");
                                ctx.moveTo(p0.x, padT + h);
                                ctx.lineTo(p0.x, p0.y);
                                for (var ci = 1; ci < data.length; ci++) {
                                    var prev = getP(ci - 1, "correct");
                                    var curr = getP(ci, "correct");
                                    var cpx = (prev.x + curr.x) / 2;
                                    ctx.bezierCurveTo(cpx, prev.y, cpx, curr.y, curr.x, curr.y);
                                }
                                ctx.lineTo(getP(data.length - 1, "correct").x, padT + h);
                                ctx.closePath();
                                ctx.fill();

                                // Line
                                ctx.strokeStyle = "#22d3ee";
                                ctx.lineWidth = 2;
                                ctx.beginPath();
                                ctx.moveTo(p0.x, p0.y);
                                for (var li = 1; li < data.length; li++) {
                                    var lp = getP(li - 1, "correct");
                                    var lc = getP(li, "correct");
                                    var lcpx = (lp.x + lc.x) / 2;
                                    ctx.bezierCurveTo(lcpx, lp.y, lcpx, lc.y, lc.x, lc.y);
                                }
                                ctx.stroke();

                                // Draw "incorrect" area
                                var grad2 = ctx.createLinearGradient(0, padT, 0, padT + h);
                                grad2.addColorStop(0, "rgba(248,81,73,0.2)");
                                grad2.addColorStop(1, "rgba(248,81,73,0)");
                                ctx.fillStyle = grad2;
                                ctx.beginPath();
                                var ip0 = getP(0, "incorrect");
                                ctx.moveTo(ip0.x, padT + h);
                                ctx.lineTo(ip0.x, ip0.y);
                                for (var ii = 1; ii < data.length; ii++) {
                                    var iprev = getP(ii - 1, "incorrect");
                                    var icurr = getP(ii, "incorrect");
                                    var icpx = (iprev.x + icurr.x) / 2;
                                    ctx.bezierCurveTo(icpx, iprev.y, icpx, icurr.y, icurr.x, icurr.y);
                                }
                                ctx.lineTo(getP(data.length - 1, "incorrect").x, padT + h);
                                ctx.closePath();
                                ctx.fill();

                                ctx.strokeStyle = "#f85149";
                                ctx.lineWidth = 2;
                                ctx.beginPath();
                                ctx.moveTo(ip0.x, ip0.y);
                                for (var ji = 1; ji < data.length; ji++) {
                                    var jp = getP(ji - 1, "incorrect");
                                    var jc = getP(ji, "incorrect");
                                    var jcpx = (jp.x + jc.x) / 2;
                                    ctx.bezierCurveTo(jcpx, jp.y, jcpx, jc.y, jc.x, jc.y);
                                }
                                ctx.stroke();

                                // Dots on correct line
                                for (var di = 0; di < data.length; di++) {
                                    var dp = getP(di, "correct");
                                    ctx.fillStyle = "#22d3ee";
                                    ctx.beginPath();
                                    ctx.arc(dp.x, dp.y, 3, 0, Math.PI * 2);
                                    ctx.fill();
                                }
                            }
                        }
                    }
                }

                // SRS Schedule
                Rectangle {
                    Layout.preferredWidth: 300
                    height: 260; radius: 10
                    color: Theme.surface
                    border.color: Theme.border; border.width: 1

                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 20; spacing: 12

                        Text { text: "SRS SCHEDULE"; color: Theme.muted; font.family: Theme.fontMono; font.pixelSize: 10; font.letterSpacing: 0.8 }

                        Repeater {
                            model: typeof progressController !== "undefined" ? progressController.srsData : []
                            delegate: RowLayout {
                                Layout.fillWidth: true; spacing: 10

                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 4
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: modelData.topic; color: Theme.foreground; font.family: Theme.fontSans; font.pixelSize: 12; font.weight: Font.Medium }
                                        Item { Layout.fillWidth: true }
                                        Text { text: modelData.date; color: Theme.muted; font.family: Theme.fontMono; font.pixelSize: 11 }
                                    }
                                    Rectangle {
                                        Layout.fillWidth: true; height: 4; radius: 2; color: Theme.surface3
                                        Rectangle {
                                            width: parent.width * (modelData.count > 0 ? (modelData.count / 15) : 0) // normalized to roughly 15 items max for display scale
                                            height: parent.height; radius: 2
                                            color: index === 0 ? Theme.accent : Theme.surface2
                                            border.color: index === 0 ? "transparent" : Theme.border
                                            border.width: index === 0 ? 0 : 1
                                        }
                                    }
                                }
                                Text {
                                    text: String(modelData.count)
                                    color: index === 0 ? Theme.accent : Theme.foreground
                                    font.family: Theme.fontMono; font.pixelSize: 12; font.weight: Font.Bold
                                    Layout.preferredWidth: 20
                                    horizontalAlignment: Text.AlignRight
                                }
                            }
                        }
                    }
                }
            }

            // ─── Bottom Row: Radar Chart + Topic Breakdown ────
            RowLayout {
                Layout.fillWidth: true
                spacing: 20

                // Knowledge Map (Radar Chart)
                Rectangle {
                    Layout.preferredWidth: 300
                    height: 280; radius: 10
                    color: Theme.surface
                    border.color: Theme.border; border.width: 1

                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 20; spacing: 8

                        Text { text: "KNOWLEDGE MAP"; color: Theme.muted; font.family: Theme.fontMono; font.pixelSize: 10; font.letterSpacing: 0.8 }

                        Canvas {
                            id: radarChart
                            Layout.fillWidth: true; Layout.fillHeight: true

                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                var data = typeof progressController !== "undefined" ? progressController.radarData : [];
                                if (!data || data.length === 0) return;

                                var cx = width / 2, cy = height / 2;
                                var maxR = Math.min(cx, cy) - 30;
                                var n = data.length;
                                var angleStep = (2 * Math.PI) / n;
                                var startAngle = -Math.PI / 2;

                                // Draw concentric pentagons (grid)
                                for (var ring = 1; ring <= 4; ring++) {
                                    var r = maxR * ring / 4;
                                    ctx.strokeStyle = "rgba(255,255,255,0.06)";
                                    ctx.lineWidth = 1;
                                    ctx.beginPath();
                                    for (var ri = 0; ri <= n; ri++) {
                                        var a = startAngle + ri * angleStep;
                                        var px = cx + r * Math.cos(a);
                                        var py = cy + r * Math.sin(a);
                                        if (ri === 0) ctx.moveTo(px, py);
                                        else ctx.lineTo(px, py);
                                    }
                                    ctx.closePath();
                                    ctx.stroke();
                                }

                                // Spokes
                                for (var si = 0; si < n; si++) {
                                    var sa = startAngle + si * angleStep;
                                    ctx.strokeStyle = "rgba(255,255,255,0.06)";
                                    ctx.beginPath();
                                    ctx.moveTo(cx, cy);
                                    ctx.lineTo(cx + maxR * Math.cos(sa), cy + maxR * Math.sin(sa));
                                    ctx.stroke();
                                }

                                // Data polygon fill
                                ctx.fillStyle = "rgba(34,211,238,0.12)";
                                ctx.strokeStyle = "#22d3ee";
                                ctx.lineWidth = 1.5;
                                ctx.beginPath();
                                for (var di = 0; di <= n; di++) {
                                    var idx = di % n;
                                    var da = startAngle + idx * angleStep;
                                    var dr = maxR * (data[idx].score / 100);
                                    var dx = cx + dr * Math.cos(da);
                                    var dy = cy + dr * Math.sin(da);
                                    if (di === 0) ctx.moveTo(dx, dy);
                                    else ctx.lineTo(dx, dy);
                                }
                                ctx.closePath();
                                ctx.fill();
                                ctx.stroke();

                                // Data points
                                for (var pi = 0; pi < n; pi++) {
                                    var pa = startAngle + pi * angleStep;
                                    var pr = maxR * (data[pi].score / 100);
                                    ctx.fillStyle = "#22d3ee";
                                    ctx.beginPath();
                                    ctx.arc(cx + pr * Math.cos(pa), cy + pr * Math.sin(pa), 3, 0, Math.PI * 2);
                                    ctx.fill();
                                }

                                // Labels
                                ctx.fillStyle = "#8b949e";
                                ctx.font = "9px 'DejaVu Sans Mono'";
                                ctx.textAlign = "center";
                                for (var li = 0; li < n; li++) {
                                    var la = startAngle + li * angleStep;
                                    var lx = cx + (maxR + 18) * Math.cos(la);
                                    var ly = cy + (maxR + 18) * Math.sin(la);
                                    ctx.fillText(data[li].topic, lx, ly + 3);
                                }
                            }
                        }
                    }
                }

                // Topic Breakdown
                Rectangle {
                    Layout.fillWidth: true
                    height: 280; radius: 10
                    color: Theme.surface
                    border.color: Theme.border; border.width: 1

                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 20; spacing: 10

                        Text { text: "TOPIC BREAKDOWN"; color: Theme.muted; font.family: Theme.fontMono; font.pixelSize: 10; font.letterSpacing: 0.8 }

                        Repeater {
                            model: typeof progressController !== "undefined" ? progressController.topicBreakdown : []
                            delegate: RowLayout {
                                Layout.fillWidth: true; spacing: 14

                                Text {
                                    text: modelData.topic
                                    color: Theme.foreground
                                    font.family: Theme.fontSans; font.pixelSize: 13; font.weight: Font.Medium
                                    Layout.preferredWidth: 110
                                }

                                Rectangle {
                                    Layout.fillWidth: true; height: 8; radius: 4
                                    color: Theme.surface3

                                    Rectangle {
                                        width: parent.width * (modelData.score / 100)
                                        height: parent.height; radius: 4
                                        color: modelData.color

                                        Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutQuad } }
                                    }
                                }

                                Text {
                                    text: modelData.score + "%"
                                    color: modelData.score < 60 ? Theme.danger : Theme.foreground
                                    font.family: Theme.fontMono; font.pixelSize: 13
                                    Layout.preferredWidth: 36
                                    horizontalAlignment: Text.AlignRight
                                }

                                // WEAK badge
                                Rectangle {
                                    visible: modelData.score < 60
                                    width: 40; height: 18; radius: 4
                                    color: Qt.rgba(0.973, 0.318, 0.286, 0.12)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "WEAK"
                                        color: Theme.danger
                                        font.family: Theme.fontMono
                                        font.pixelSize: 9; font.weight: Font.Bold
                                        font.letterSpacing: 0.8
                                    }
                                }

                                // Spacer for alignment when no WEAK badge
                                Item { visible: modelData.score >= 60; width: 40 }
                            }
                        }
                    }
                }
            }
        }
    }
}
