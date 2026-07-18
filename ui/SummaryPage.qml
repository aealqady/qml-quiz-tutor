import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: summaryPage
    color: "transparent"

    property var chatHistory: typeof summaryController !== "undefined" ? summaryController.chatHistory : []
    property bool isGenerating: typeof summaryController !== "undefined" ? summaryController.isGenerating : false
    
    // Select document to summarize
    property var readyDocs: []
    property int selectedDocId: -1
    
    function refreshDocs() {
        if (typeof uploadController === "undefined") return;
        var allDocs = uploadController.documents;
        var filtered = [];
        for (var i = 0; i < allDocs.length; i++) {
            if (allDocs[i].status === "ready") {
                filtered.push(allDocs[i]);
            }
        }
        readyDocs = filtered;
        if (filtered.length > 0 && selectedDocId === -1) {
            selectedDocId = parseInt(filtered[0].id);
        }
    }
    
    function sendSummaryRequest() {
        if (!isGenerating && inputField.text.trim() !== "" && typeof summaryController !== "undefined" && selectedDocId !== -1) {
            summaryController.sendMessage(selectedDocId, inputField.text);
            inputField.text = "";
        }
    }

    Component.onCompleted: refreshDocs()
    Connections {
        target: typeof uploadController !== "undefined" ? uploadController : null
        function onDocumentsChanged() { refreshDocs() }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 32
        spacing: 20

        // ─── Header ───────────────────────────────────────
        ColumnLayout {
            spacing: 6

            Text { text: typeof Translator !== "undefined" ? Translator.currentDict["sum_title"] : "AI Summary Generator"; color: Theme.foreground; font.family: Theme.fontSans; font.pixelSize: 22; font.weight: Font.Bold; font.letterSpacing: -0.4 }
            Text { text: typeof Translator !== "undefined" ? Translator.currentDict["sum_subtitle"] : "Chat with the AI to generate a structured PDF summary from a document."; color: Theme.muted; font.family: Theme.fontSans; font.pixelSize: 13 }
        }

        // Document Selection
        RowLayout {
            spacing: 12
            Text { text: typeof Translator !== "undefined" ? Translator.currentDict["source_doc"] : "Source Document:"; color: Theme.foreground; font.pixelSize: 14 }
            ComboBox {
                model: readyDocs.map(function(d) { return d.name; })
                implicitWidth: 300
                onCurrentIndexChanged: {
                    if (currentIndex >= 0 && currentIndex < readyDocs.length) {
                        selectedDocId = parseInt(readyDocs[currentIndex].id);
                    }
                }
            }
        }

        // Chat View
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.surface
            border.color: Theme.border
            border.width: 1
            radius: 12

            ListView {
                id: chatView
                anchors.fill: parent
                anchors.margins: 16
                clip: true
                spacing: 16
                model: chatHistory
                
                delegate: ColumnLayout {
                    width: chatView.width - 32
                    
                    // Delete button row - anchored above each message bubble
                    RowLayout {
                        Layout.alignment: modelData.role === "user" ? Qt.AlignRight : Qt.AlignLeft
                        spacing: 4
                        
                        Rectangle {
                            width: delRow.implicitWidth + 16
                            height: 22
                            radius: 4
                            color: delMouseArea.containsMouse ? "#44FF4444" : "transparent"
                            
                            RowLayout {
                                id: delRow
                                anchors.centerIn: parent
                                spacing: 4
                                
                                // Trash icon
                                Canvas {
                                    width: 12; height: 12
                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.clearRect(0, 0, width, height);
                                        ctx.strokeStyle = delMouseArea.containsMouse ? "#FF6666" : Theme.muted;
                                        ctx.lineWidth = 1.2;
                                        ctx.lineCap = "round";
                                        ctx.lineJoin = "round";
                                        // Lid
                                        ctx.beginPath();
                                        ctx.moveTo(1, 3); ctx.lineTo(11, 3);
                                        ctx.stroke();
                                        ctx.beginPath();
                                        ctx.moveTo(4, 3); ctx.lineTo(4, 1.5); ctx.lineTo(8, 1.5); ctx.lineTo(8, 3);
                                        ctx.stroke();
                                        // Body
                                        ctx.beginPath();
                                        ctx.moveTo(2.5, 3); ctx.lineTo(3, 11); ctx.lineTo(9, 11); ctx.lineTo(9.5, 3);
                                        ctx.stroke();
                                        // Lines
                                        ctx.beginPath(); ctx.moveTo(5, 5); ctx.lineTo(5, 9); ctx.stroke();
                                        ctx.beginPath(); ctx.moveTo(7, 5); ctx.lineTo(7, 9); ctx.stroke();
                                    }
                                }
                                
                                Text {
                                    text: typeof Translator !== "undefined" ? Translator.currentDict["delete_msg"] : "Delete"
                                    color: delMouseArea.containsMouse ? "#FF6666" : Theme.muted
                                    font.pixelSize: 10
                                }
                            }
                            
                            MouseArea {
                                id: delMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (typeof summaryController !== "undefined" && typeof modelData.id !== "undefined") {
                                        summaryController.deleteMessage(modelData.id);
                                    }
                                }
                            }
                        }
                    }
                    
                    // Message bubble
                    Rectangle {
                        Layout.alignment: modelData.role === "user" ? Qt.AlignRight : Qt.AlignLeft
                        color: modelData.role === "user" ? Theme.accentDim : Theme.surface2
                        border.color: modelData.role === "user" ? Theme.borderAccent : Theme.border
                        border.width: 1
                        radius: 12
                        implicitWidth: Math.min(msgText.implicitWidth + 32, chatView.width * 0.7)
                        implicitHeight: contentCol.implicitHeight + 24
                        
                        ColumnLayout {
                            id: contentCol
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8
                            
                            Text {
                                text: modelData.role === "user" ? (typeof Translator !== "undefined" ? Translator.currentDict["you"] : "You") : (typeof Translator !== "undefined" ? Translator.currentDict["agent"] : "ITS Agent")
                                color: modelData.role === "user" ? Theme.accent : Theme.muted
                                font.pixelSize: 10
                                font.weight: Font.Bold
                            }
                            
                            Text {
                                id: msgText
                                Layout.fillWidth: true
                                text: modelData.text
                                color: Theme.foreground
                                font.pixelSize: 14
                                wrapMode: Text.Wrap
                            }
                            
                            // PDF Button if generated
                            Rectangle {
                                visible: typeof modelData.pdf_path !== "undefined" && modelData.pdf_path !== ""
                                Layout.topMargin: 8
                                width: 140; height: 36; radius: 6
                                color: Theme.accent
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: typeof Translator !== "undefined" ? Translator.currentDict["open_pdf"] : "Open PDF"
                                    color: "#000"
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Qt.openUrlExternally("file://" + modelData.pdf_path);
                                    }
                                }
                            }
                        }
                    }
                }
                
                onCountChanged: {
                    chatView.positionViewAtEnd();
                }
            }
            
            // Loading Indicator
            RowLayout {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.margins: 16
                visible: isGenerating
                spacing: 8
                
                BusyIndicator { width: 24; height: 24 }
                Text { text: typeof Translator !== "undefined" ? Translator.currentDict["generating"] : "Generating summary and PDF..."; color: Theme.muted; font.pixelSize: 12 }
            }
        }

        // Input Area
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            
            Rectangle {
                Layout.fillWidth: true
                height: 48
                radius: 8
                color: Theme.surface2
                border.color: Theme.border
                border.width: 1
                
                TextInput {
                    id: inputField
                    anchors.fill: parent
                    anchors.margins: 16
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.foreground
                    font.pixelSize: 14
                    text: typeof Translator !== "undefined" ? Translator.currentDict["sum_placeholder"] : "Create a detailed summary of this document..."
                    
                    Keys.onReturnPressed: sendSummaryRequest()
                }
            }
            
            Rectangle {
                id: sendBtn
                width: 80; height: 48; radius: 8
                color: isGenerating ? Theme.surface3 : Theme.accent
                
                Text {
                    anchors.centerIn: parent
                    text: typeof Translator !== "undefined" ? Translator.currentDict["send"] : "Send"
                    color: isGenerating ? Theme.muted : "#000"
                    font.weight: Font.Bold
                    font.pixelSize: 14
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: isGenerating ? Qt.ArrowCursor : Qt.PointingHandCursor
                    onClicked: sendSummaryRequest()
                }
            }
        }
    }
}
