import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: settingsPage
    color: "transparent"

    // Bind local state to controller
    property string localUrl: typeof settingsController !== "undefined" ? settingsController.ollamaUrl : "http://localhost:11434"
    property string localModel: typeof settingsController !== "undefined" ? settingsController.selectedModel : ""

    Flickable {
        anchors.fill: parent
        contentHeight: mainCol.implicitHeight + 64
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: mainCol
            width: Math.min(parent.width - 80, 800)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 32
            spacing: 24

            // ─── Header ───────────────────────────────────────
            ColumnLayout {
                spacing: 6

                Text { text: Translator.currentDict["settings_title"]; color: Theme.foreground; font.family: Theme.fontSans; font.pixelSize: 28; font.weight: Font.Bold; font.letterSpacing: -0.5 }
                Text { text: Translator.currentDict["settings_subtitle"]; color: Theme.muted; font.family: Theme.fontSans; font.pixelSize: 15 }
            }

            // ─── Language Section ─────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 80
                color: Theme.surface
                border.color: Theme.border
                border.width: 1
                radius: 12

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 16
                    
                    ColumnLayout {
                        spacing: 4
                        Text { text: Translator.currentDict["lang_section"]; color: Theme.foreground; font.family: Theme.fontSans; font.pixelSize: 16; font.weight: Font.Bold }
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    Rectangle {
                        width: 160; height: 40; radius: 6
                        color: Theme.accent
                        
                        Text {
                            anchors.centerIn: parent
                            text: Translator.currentDict["switch_lang"]
                            color: "#000"
                            font.family: Theme.fontSans
                            font.pixelSize: 14
                            font.weight: Font.Bold
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Translator.lang = Translator.lang === "en" ? "ar" : "en";
                            }
                        }
                    }
                }
            }

            // ─── Connection Settings ──────────────────────────
            Rectangle {
                Layout.fillWidth: true
                radius: 10
                color: Theme.surface
                border.color: Theme.border
                border.width: 1
                implicitHeight: configCol.implicitHeight + 40

                ColumnLayout {
                    id: configCol
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    Text { text: Translator.currentDict["ollama_setup"].toUpperCase(); color: Theme.muted; font.family: Theme.fontMono; font.pixelSize: 10; font.letterSpacing: 0.8 }

                    // URL Input
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text { text: Translator.currentDict["ollama_url"]; color: Theme.foreground; font.family: Theme.fontSans; font.pixelSize: 13; font.weight: Font.Medium }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            
                            Rectangle {
                                Layout.fillWidth: true
                                height: 40
                                radius: 6
                                color: Theme.background
                                border.color: urlInput.activeFocus ? Theme.accent : Theme.border
                                border.width: 1
                                
                                TextInput {
                                    id: urlInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 12; anchors.rightMargin: 12
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: Theme.foreground
                                    font.family: Theme.fontMono
                                    font.pixelSize: 13
                                    text: settingsPage.localUrl
                                    onTextChanged: settingsPage.localUrl = text
                                }
                            }
                            
                            Rectangle {
                                width: 100; height: 40; radius: 6
                                color: (typeof settingsController !== "undefined" && settingsController.isChecking) ? Theme.surface2 : Theme.accent
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: (typeof settingsController !== "undefined" && settingsController.isChecking) ? "..." : Translator.currentDict["test_conn"]
                                    color: (typeof settingsController !== "undefined" && settingsController.isChecking) ? Theme.muted : "#000000"
                                    font.family: Theme.fontSans
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (typeof settingsController !== "undefined" && !settingsController.isChecking) {
                                            settingsController.checkOllama(settingsPage.localUrl)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Model Selection
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text { text: Translator.currentDict["ai_model"]; color: Theme.foreground; font.family: Theme.fontSans; font.pixelSize: 13; font.weight: Font.Medium }
                        
                        Rectangle {
                            Layout.fillWidth: true
                            height: 40
                            radius: 6
                            color: Theme.background
                            border.color: Theme.border
                            border.width: 1
                            
                            ComboBox {
                                id: modelCombo
                                anchors.fill: parent
                                anchors.margins: 1
                                
                                model: typeof settingsController !== "undefined" ? settingsController.availableModels : []
                                
                                background: Rectangle { color: "transparent" }
                                
                                contentItem: Text {
                                    leftPadding: 12; rightPadding: 12
                                    text: modelCombo.currentText
                                    color: Theme.foreground
                                    font.family: Theme.fontSans
                                    font.pixelSize: 13
                                    verticalAlignment: Text.AlignVCenter
                                }
                                
                                delegate: ItemDelegate {
                                    width: modelCombo.width
                                    contentItem: Text {
                                        text: modelData
                                        color: Theme.foreground
                                        font.family: Theme.fontSans
                                        font.pixelSize: 13
                                    }
                                    background: Rectangle {
                                        color: parent.highlighted ? Theme.surface2 : Theme.surface
                                    }
                                }
                                
                                popup: Popup {
                                    y: modelCombo.height - 1
                                    width: modelCombo.width
                                    implicitHeight: contentItem.implicitHeight
                                    padding: 1
                                    
                                    contentItem: ListView {
                                        clip: true
                                        implicitHeight: contentHeight
                                        model: modelCombo.popup.visible ? modelCombo.delegateModel : null
                                        currentIndex: modelCombo.highlightedIndex
                                        ScrollIndicator.vertical: ScrollIndicator { }
                                    }
                                    
                                    background: Rectangle {
                                        color: Theme.surface
                                        border.color: Theme.border
                                        radius: 6
                                    }
                                }
                                
                                onActivated: {
                                    settingsPage.localModel = currentText
                                }
                                
                                // Auto-select the saved model if it exists in the new list
                                Connections {
                                    target: typeof settingsController !== "undefined" ? settingsController : null
                                    function onModelsChanged() {
                                        if (!settingsController) return;
                                        let models = settingsController.availableModels;
                                        let saved = settingsController.selectedModel;
                                        
                                        if (models.length > 0) {
                                            let idx = models.indexOf(saved);
                                            if (idx >= 0) {
                                                modelCombo.currentIndex = idx;
                                                settingsPage.localModel = saved;
                                            } else {
                                                modelCombo.currentIndex = 0;
                                                settingsPage.localModel = models[0];
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Status Message
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        
                        Text {
                            Layout.fillWidth: true
                            text: typeof settingsController !== "undefined" ? settingsController.statusMessage : "Ready"
                            color: text.includes("Error") || text.includes("Failed") ? Theme.danger : Theme.muted
                            font.family: Theme.fontSans
                            font.pixelSize: 13
                        }
                        
                        Rectangle {
                            width: 120; height: 40; radius: 6
                            color: Theme.accentDim
                            border.color: Theme.borderAccent
                            border.width: 1
                            
                            Text {
                                anchors.centerIn: parent
                                text: Translator.currentDict["save_settings"]
                                color: Theme.accent
                                font.family: Theme.fontSans
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (typeof settingsController !== "undefined") {
                                        settingsController.saveSettings(settingsPage.localUrl, settingsPage.localModel)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
