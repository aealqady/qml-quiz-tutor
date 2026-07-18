import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: uploadPage
    color: "transparent"

    // Bind to Python controller
    property var docs: uploadController ? uploadController.documents : []

    Flickable {
        anchors.fill: parent
        contentHeight: mainCol.implicitHeight + 64
        clip: true

        ColumnLayout {
            id: mainCol
            width: Math.min(parent.width - 80, 900)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 32
            spacing: 28

            // ─── Header ───────────────────────────────────────────
            ColumnLayout {
                spacing: 6

                Text {
                    text: typeof Translator !== "undefined" ? Translator.currentDict["upload_title"] : "Knowledge Base"
                    color: Theme.foreground
                    font.family: Theme.fontSans
                    font.pixelSize: 22
                    font.weight: Font.Bold
                    font.letterSpacing: -0.4
                }
                Text {
                    text: typeof Translator !== "undefined" ? Translator.currentDict["upload_subtitle"] : "Upload PDF materials. The LLM will extract concepts and generate targeted questions."
                    color: Theme.muted
                    font.family: Theme.fontSans
                    font.pixelSize: 13
                }
            }

            // ─── Drop Zone ────────────────────────────────────────
            Rectangle {
                id: dropZone
                Layout.fillWidth: true
                Layout.preferredHeight: 160
                radius: 10
                color: dropArea.containsDrag ? Theme.accentGlow : Theme.surface
                border.color: dropArea.containsDrag ? Theme.accent : Theme.border
                border.width: 1.5

                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on border.color { ColorAnimation { duration: 200 } }

                // Dashed border overlay
                Canvas {
                    anchors.fill: parent
                    anchors.margins: 1
                    visible: !dropArea.containsDrag
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.08);
                        ctx.lineWidth = 1.5;
                        ctx.setLineDash([6, 4]);
                        var r = 9;
                        ctx.beginPath();
                        ctx.moveTo(r, 0);
                        ctx.lineTo(width - r, 0);
                        ctx.arcTo(width, 0, width, r, r);
                        ctx.lineTo(width, height - r);
                        ctx.arcTo(width, height, width - r, height, r);
                        ctx.lineTo(r, height);
                        ctx.arcTo(0, height, 0, height - r, r);
                        ctx.lineTo(0, r);
                        ctx.arcTo(0, 0, r, 0, r);
                        ctx.closePath();
                        ctx.stroke();
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 12

                    // Upload icon box
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 48; height: 48; radius: 10
                        color: Theme.accentDim
                        border.color: Theme.borderAccent
                        border.width: 1

                        Canvas {
                            anchors.centerIn: parent
                            width: 22; height: 22
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                ctx.strokeStyle = Theme.accent;
                                ctx.lineWidth = 1.5;
                                ctx.lineCap = "round";
                                ctx.lineJoin = "round";
                                // Upload arrow
                                ctx.beginPath();
                                ctx.moveTo(18, 13); ctx.lineTo(18, 17);
                                ctx.quadraticCurveTo(18, 19, 16, 19);
                                ctx.lineTo(6, 19);
                                ctx.quadraticCurveTo(4, 19, 4, 17);
                                ctx.lineTo(4, 13);
                                ctx.stroke();
                                ctx.beginPath();
                                ctx.moveTo(15, 7); ctx.lineTo(11, 3); ctx.lineTo(7, 7);
                                ctx.stroke();
                                ctx.beginPath();
                                ctx.moveTo(11, 3); ctx.lineTo(11, 13);
                                ctx.stroke();
                            }
                        }
                    }

                    ColumnLayout {
                        spacing: 4
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: typeof Translator !== "undefined" ? Translator.currentDict["upload_drop"] : "Drop PDF files here"
                            color: Theme.foreground
                            font.family: Theme.fontSans
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }
                        Row {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 0
                            Text {
                                text: "or "
                                color: Theme.muted
                                font.family: Theme.fontSans
                                font.pixelSize: 12
                            }
                            Text {
                                text: "browse"
                                color: Theme.accent
                                font.family: Theme.fontSans
                                font.pixelSize: 12
                            }
                            Text {
                                text: " · Supports multi-file upload"
                                color: Theme.muted
                                font.family: Theme.fontSans
                                font.pixelSize: 12
                            }
                        }
                    }
                }

                DropArea {
                    id: dropArea
                    anchors.fill: parent
                    onEntered: (drag) => {
                        if (drag.hasUrls) drag.accept()
                    }
                    onDropped: (drop) => {
                        var urls = []
                        for (var i = 0; i < drop.urls.length; i++) {
                            urls.push(drop.urls[i])
                        }
                        if (uploadController) {
                            uploadController.processFiles(urls)
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        console.log("Browse clicked - file dialog TODO")
                    }
                }
            }

            // ─── Document Table ───────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(docListView.contentHeight + 42, 200)
                color: Theme.surface
                border.color: Theme.border
                border.width: 1
                radius: 10
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Table Header Row
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        color: "transparent"

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width; height: 1
                            color: Theme.border
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16; anchors.rightMargin: 16
                            spacing: 0

                            Text {
                                text: "DOCUMENT"
                                color: Theme.muted
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                font.letterSpacing: 0.8
                                Layout.fillWidth: true
                            }
                            Text {
                                text: "PAGES"
                                color: Theme.muted
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                font.letterSpacing: 0.8
                                Layout.preferredWidth: 60
                                horizontalAlignment: Text.AlignHCenter
                            }
                            Text {
                                text: "QUESTIONS"
                                color: Theme.muted
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                font.letterSpacing: 0.8
                                Layout.preferredWidth: 80
                                horizontalAlignment: Text.AlignHCenter
                            }
                            Text {
                                text: "STATUS"
                                color: Theme.muted
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                font.letterSpacing: 0.8
                                Layout.preferredWidth: 80
                                horizontalAlignment: Text.AlignHCenter
                            }
                            Text {
                                text: "UPLOADED"
                                color: Theme.muted
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                font.letterSpacing: 0.8
                                Layout.preferredWidth: 100
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }

                    // Table Body
                    ListView {
                        id: docListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: uploadPage.docs
                        interactive: false

                        delegate: Rectangle {
                            width: docListView.width
                            height: modelData.status === "processing" ? 62 : 48
                            color: docRowMouse.containsMouse ? Theme.surface2 : "transparent"

                            Behavior on color { ColorAnimation { duration: 120 } }

                            // Bottom border
                            Rectangle {
                                width: parent.width; height: 1
                                anchors.bottom: parent.bottom
                                color: Theme.border
                                visible: index < docListView.count - 1
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16; anchors.rightMargin: 16
                                spacing: 0

                                // Name column with file icon
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    Row {
                                        spacing: 8
                                        // File icon
                                        Canvas {
                                            width: 14; height: 14
                                            anchors.verticalCenter: parent.verticalCenter
                                            onPaint: {
                                                var ctx = getContext("2d");
                                                ctx.clearRect(0, 0, width, height);
                                                ctx.strokeStyle = Theme.muted;
                                                ctx.lineWidth = 1.2;
                                                ctx.lineCap = "round";
                                                ctx.lineJoin = "round";
                                                ctx.beginPath();
                                                ctx.moveTo(2, 1);
                                                ctx.lineTo(9, 1); ctx.lineTo(12, 4); ctx.lineTo(12, 13);
                                                ctx.lineTo(2, 13); ctx.closePath();
                                                ctx.stroke();
                                                ctx.beginPath();
                                                ctx.moveTo(9, 1); ctx.lineTo(9, 4); ctx.lineTo(12, 4);
                                                ctx.stroke();
                                            }
                                        }
                                        Text {
                                            text: modelData.name
                                            color: Theme.foreground
                                            font.family: Theme.fontSans
                                            font.pixelSize: 13
                                            font.weight: Font.Medium
                                        }
                                    }

                                    // Progress bar for processing docs
                                    Rectangle {
                                        visible: modelData.status === "processing"
                                        Layout.fillWidth: true
                                        Layout.maximumWidth: 300
                                        height: 3; radius: 2
                                        color: Theme.surface3

                                        Rectangle {
                                            width: parent.width * (modelData.progress / 100)
                                            height: parent.height; radius: 2
                                            color: Theme.accent

                                            Behavior on width {
                                                NumberAnimation { duration: 400; easing.type: Easing.OutQuad }
                                            }
                                        }
                                    }
                                }

                                Text {
                                    text: String(modelData.pages)
                                    color: Theme.muted
                                    font.family: Theme.fontMono
                                    font.pixelSize: 12
                                    Layout.preferredWidth: 60
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                Text {
                                    text: modelData.questions > 0 ? String(modelData.questions) : "—"
                                    color: modelData.questions > 0 ? Theme.foreground : Theme.muted
                                    font.family: Theme.fontMono
                                    font.pixelSize: 12
                                    Layout.preferredWidth: 80
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                Text {
                                    text: modelData.status.toUpperCase()
                                    color: modelData.status === "ready" ? Theme.success
                                         : modelData.status === "processing" ? Theme.warning
                                         : Theme.danger
                                    font.family: Theme.fontMono
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    font.letterSpacing: 0.8
                                    Layout.preferredWidth: 80
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                Text {
                                    text: modelData.uploadedAt
                                    color: Theme.muted
                                    font.family: Theme.fontMono
                                    font.pixelSize: 12
                                    Layout.preferredWidth: 100
                                    horizontalAlignment: Text.AlignRight
                                }
                            }

                            MouseArea {
                                id: docRowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                            }
                        }
                    }
                }
            }
        }
    }
}
