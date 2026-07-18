import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: sidebar
    width: Theme.sidebarWidth
    color: Theme.surface

    // Right border line
    Rectangle {
        width: 1; height: parent.height
        anchors.right: parent.right
        color: Theme.border
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ─── Header / Brand ───────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 64

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width; height: 1
                color: Theme.border
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16; anchors.rightMargin: 16
                spacing: 10

                // Brain icon box
                Rectangle {
                    width: 32; height: 32; radius: 8
                    color: Theme.accentDim
                    border.color: Theme.borderAccent
                    border.width: 1

                    // Brain SVG-like icon drawn with Canvas
                    Canvas {
                        anchors.centerIn: parent
                        width: 18; height: 18
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            ctx.strokeStyle = Theme.accent;
                            ctx.lineWidth = 1.3;
                            ctx.lineCap = "round";

                            // Left hemisphere
                            ctx.beginPath();
                            ctx.arc(7, 5, 3.5, Math.PI, 0);
                            ctx.arc(6, 9, 3, -Math.PI/3, Math.PI/2);
                            ctx.arc(7, 13, 3, -Math.PI/4, Math.PI/3);
                            ctx.stroke();

                            // Right hemisphere
                            ctx.beginPath();
                            ctx.arc(11, 5, 3.5, Math.PI, 0);
                            ctx.arc(12, 9, 3, Math.PI/2, Math.PI + Math.PI/3);
                            ctx.arc(11, 13, 3, Math.PI*2/3, Math.PI + Math.PI/4);
                            ctx.stroke();

                            // Center line
                            ctx.beginPath();
                            ctx.moveTo(9, 2);
                            ctx.lineTo(9, 16);
                            ctx.stroke();
                        }
                    }
                }

                Column {
                    Layout.fillWidth: true
                    Text {
                        text: "ITS"
                        color: Theme.foreground
                        font.family: Theme.fontSans
                        font.weight: Font.Bold
                        font.pixelSize: 14
                        font.letterSpacing: 0.3
                    }
                    Text {
                        text: "TUTOR v1.0"
                        color: Theme.muted
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        font.letterSpacing: 0.8
                    }
                }
            }
        }

        // ─── Navigation Items ─────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 10
            Layout.leftMargin: 8; Layout.rightMargin: 8
            spacing: 2

            Repeater {
                model: ListModel {
                    ListElement { pageId: "upload";   dictKey: "menu_docs";     iconType: "upload" }
                    ListElement { pageId: "exam";     dictKey: "menu_exam";     iconType: "exam" }
                    ListElement { pageId: "progress"; dictKey: "menu_progress"; iconType: "progress" }
                    ListElement { pageId: "summary";  dictKey: "menu_summary";  iconType: "summary" }
                    ListElement { pageId: "settings"; dictKey: "menu_settings"; iconType: "settings" }
                }

                delegate: Rectangle {
                    id: navItem
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    radius: 6

                    property bool isActive: window.currentPage === pageId
                    property bool isHovered: navArea.containsMouse

                    color: isActive ? Theme.accentDim
                         : isHovered ? Theme.surface2
                         : "transparent"

                    Behavior on color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10; anchors.rightMargin: 10
                        spacing: 8

                        // Custom SVG-like icons
                        Canvas {
                            width: 16; height: 16
                            Layout.alignment: Qt.AlignVCenter

                            property color iconColor: navItem.isActive ? Theme.accent : Theme.muted

                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                ctx.strokeStyle = iconColor;
                                ctx.lineWidth = 1.5;
                                ctx.lineCap = "round";
                                ctx.lineJoin = "round";

                                if (iconType === "upload") {
                                    // Upload arrow icon
                                    ctx.beginPath();
                                    ctx.moveTo(14, 10);
                                    ctx.lineTo(14, 13);
                                    ctx.quadraticCurveTo(14, 14, 13, 14);
                                    ctx.lineTo(3, 14);
                                    ctx.quadraticCurveTo(2, 14, 2, 13);
                                    ctx.lineTo(2, 10);
                                    ctx.stroke();

                                    ctx.beginPath();
                                    ctx.moveTo(11, 5); ctx.lineTo(8, 2); ctx.lineTo(5, 5);
                                    ctx.stroke();
                                    ctx.beginPath();
                                    ctx.moveTo(8, 2); ctx.lineTo(8, 10);
                                    ctx.stroke();
                                } else if (iconType === "exam") {
                                    // Document icon
                                    ctx.beginPath();
                                    ctx.moveTo(4, 1);
                                    ctx.lineTo(10, 1); ctx.lineTo(13, 4); ctx.lineTo(13, 14);
                                    ctx.quadraticCurveTo(13, 15, 12, 15);
                                    ctx.lineTo(4, 15);
                                    ctx.quadraticCurveTo(3, 15, 3, 14);
                                    ctx.lineTo(3, 2);
                                    ctx.quadraticCurveTo(3, 1, 4, 1);
                                    ctx.stroke();
                                    // Lines
                                    ctx.beginPath();
                                    ctx.moveTo(6, 6); ctx.lineTo(11, 6); ctx.stroke();
                                    ctx.beginPath();
                                    ctx.moveTo(6, 9); ctx.lineTo(11, 9); ctx.stroke();
                                    ctx.beginPath();
                                    ctx.moveTo(6, 12); ctx.lineTo(9, 12); ctx.stroke();
                                } else if (iconType === "progress") {
                                    // Bar chart icon
                                    ctx.beginPath();
                                    ctx.moveTo(4, 14); ctx.lineTo(4, 9); ctx.stroke();
                                    ctx.beginPath();
                                    ctx.moveTo(8, 14); ctx.lineTo(8, 3); ctx.stroke();
                                    ctx.beginPath();
                                    ctx.moveTo(12, 14); ctx.lineTo(12, 7); ctx.stroke();
                                } else if (iconType === "summary") {
                                    // document with text icon
                                    ctx.beginPath();
                                    ctx.moveTo(3, 2); ctx.lineTo(10, 2); ctx.lineTo(13, 5); ctx.lineTo(13, 14);
                                    ctx.lineTo(3, 14); ctx.closePath();
                                    ctx.stroke();
                                    // lines
                                    ctx.beginPath();
                                    ctx.moveTo(5, 6); ctx.lineTo(11, 6);
                                    ctx.moveTo(5, 9); ctx.lineTo(11, 9);
                                    ctx.moveTo(5, 12); ctx.lineTo(9, 12);
                                    ctx.stroke();
                                } else if (iconType === "settings") {
                                    // Gear/Settings icon
                                    ctx.beginPath();
                                    ctx.arc(8, 8, 3, 0, 2 * Math.PI);
                                    ctx.stroke();
                                    // Spokes
                                    for (let i = 0; i < 8; i++) {
                                        let angle = (i * Math.PI) / 4;
                                        ctx.beginPath();
                                        ctx.moveTo(8 + 4 * Math.cos(angle), 8 + 4 * Math.sin(angle));
                                        ctx.lineTo(8 + 6 * Math.cos(angle), 8 + 6 * Math.sin(angle));
                                        ctx.stroke();
                                    }
                                }
                            }
                            onIconColorChanged: requestPaint()
                        }

                        Text {
                            Layout.fillWidth: true
                            text: typeof Translator !== "undefined" ? Translator.currentDict[dictKey] : ""
                            color: navItem.isActive ? Theme.accent : Theme.muted
                            font.family: Theme.fontSans
                            font.pixelSize: 13
                            font.weight: navItem.isActive ? Font.DemiBold : Font.Normal
                        }

                        // NEW badge for Exam
                        Rectangle {
                            visible: pageId === "exam"
                            width: 32; height: 16
                            radius: 8
                            color: Theme.accent

                            Text {
                                anchors.centerIn: parent
                                text: "NEW"
                                color: "#000000"
                                font.family: Theme.fontMono
                                font.pixelSize: 8
                                font.weight: Font.Bold
                            }
                        }
                    }

                    MouseArea {
                        id: navArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: window.currentPage = pageId
                    }
                }
            }
        }

        Item { Layout.fillHeight: true } // Spacer

        // ─── Session Stats Footer ─────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 100

            Rectangle {
                anchors.top: parent.top
                width: parent.width; height: 1
                color: Theme.border
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 4

                Text {
                    text: typeof Translator !== "undefined" ? Translator.currentDict["session_stats"] : ""
                    color: Theme.muted
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    font.letterSpacing: 0.6
                    Layout.bottomMargin: 2
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: typeof Translator !== "undefined" ? Translator.currentDict["stat_reviewed"] : ""
                        color: Theme.muted; font.family: Theme.fontSans; font.pixelSize: 12
                        Layout.fillWidth: true
                    }
                    Text {
                        text: typeof progressController !== "undefined" ? progressController.questionsAnswered.toString() : "0"
                        color: Theme.foreground; font.family: Theme.fontMono; font.pixelSize: 12; font.weight: Font.DemiBold
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: typeof Translator !== "undefined" ? Translator.currentDict["stat_streak"] : ""
                        color: Theme.muted; font.family: Theme.fontSans; font.pixelSize: 12
                        Layout.fillWidth: true
                    }
                    Text {
                        text: typeof progressController !== "undefined" ? progressController.studyStreakStr : "0d"
                        color: Theme.foreground; font.family: Theme.fontMono; font.pixelSize: 12; font.weight: Font.DemiBold
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: typeof Translator !== "undefined" ? Translator.currentDict["stat_accuracy"] : ""
                        color: Theme.muted; font.family: Theme.fontSans; font.pixelSize: 12
                        Layout.fillWidth: true
                    }
                    Text {
                        text: typeof progressController !== "undefined" ? progressController.avgScoreStr : "0%"
                        color: Theme.foreground; font.family: Theme.fontMono; font.pixelSize: 12; font.weight: Font.DemiBold
                    }
                }
            }
        }
    }
}
