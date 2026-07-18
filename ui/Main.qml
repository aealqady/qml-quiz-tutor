import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ui 1.0

ApplicationWindow {
    id: window
    visible: true
    width: 1200
    height: 800
    title: "Intelligent Tutoring System"
    color: Theme.background
    
    // Support RTL when Arabic is selected
    LayoutMirroring.enabled: typeof Translator !== "undefined" ? Translator.isAr : false
    LayoutMirroring.childrenInherit: true

    // Global state for current page
    property string currentPage: "upload" // upload | exam | progress | settings

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ─── Top Title Bar ────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            color: Theme.surface

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width; height: 1
                color: Theme.border
            }

            Text {
                anchors.centerIn: parent
                text: "Intelligent Tutoring System"
                color: Theme.accent
                font.family: Theme.fontSans
                font.pixelSize: 12
                font.weight: Font.DemiBold
                font.letterSpacing: 0.3
            }
        }

        // ─── Main Content ─────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            Sidebar {
                Layout.fillHeight: true
                Layout.preferredWidth: Theme.sidebarWidth
            }

            // Main Content Area
            StackLayout {
                id: mainStack
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: {
                    if (window.currentPage === "upload") return 0;
                    if (window.currentPage === "exam") return 1;
                    if (window.currentPage === "progress") return 2;
                    if (window.currentPage === "summary") return 3;
                    if (window.currentPage === "settings") return 4;
                    if (window.currentPage === "examPlayer") return 5;
                    return 0;
                }

                UploadPage {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                QuizPage {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                ProgressPage {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                SummaryPage {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                SettingsPage {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                ExamPlayer {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }
    }
}
