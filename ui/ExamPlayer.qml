import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: examPlayer
    color: Theme.background

    // This will receive the questions list from examController
    property var questions: typeof examController !== "undefined" ? examController.questions : []
    property int currentIndex: 0
    property var currentQuestion: questions.length > 0 && currentIndex < questions.length ? questions[currentIndex] : null
    property bool isFinished: currentIndex >= questions.length && questions.length > 0

    // Store user answers
    property var userAnswers: ({}) // map of index -> string

    // Track if we already started an exam to prevent resets mid-exam
    property int _loadedQuestionCount: 0

    // When questions load, reset only if it's a genuinely new exam
    onQuestionsChanged: {
        if (questions.length > 0 && questions.length !== _loadedQuestionCount) {
            _loadedQuestionCount = questions.length;
            currentIndex = 0;
            userAnswers = {};
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 40
        spacing: 24

        // Top bar
        RowLayout {
            Layout.fillWidth: true
            
            Text {
                text: isFinished ? "Exam Completed" : "Question " + (currentIndex + 1) + " of " + questions.length
                color: Theme.muted
                font.family: Theme.fontMono
                font.pixelSize: 14
            }
            
            Item { Layout.fillWidth: true }
            
            // Exit button
            Rectangle {
                width: 80; height: 32; radius: 6
                color: Theme.surface2
                border.color: Theme.border
                border.width: 1
                
                Text {
                    anchors.centerIn: parent
                    text: "Exit Exam"
                    color: Theme.foreground
                    font.family: Theme.fontSans
                    font.pixelSize: 12
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        window.currentPage = "progress"; // Or "exam" config page
                    }
                }
            }
        }

        // Progress bar
        Rectangle {
            Layout.fillWidth: true
            height: 4
            radius: 2
            color: Theme.surface3
            
            Rectangle {
                width: questions.length > 0 ? (currentIndex / questions.length) * parent.width : 0
                height: parent.height
                radius: 2
                color: Theme.accent
                Behavior on width { NumberAnimation { duration: 300 } }
            }
        }

        // Main Content Area
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // State 1: No Questions (or Generating)
            ColumnLayout {
                anchors.centerIn: parent
                visible: questions.length === 0
                spacing: 16
                
                // Show loading state if generation is active
                ColumnLayout {
                    visible: typeof examController !== "undefined" && examController.generationProgress < 100
                    spacing: 12
                    Layout.alignment: Qt.AlignHCenter
                    
                    BusyIndicator {
                        Layout.alignment: Qt.AlignHCenter
                        width: 40; height: 40
                    }
                    
                    Text {
                        text: typeof examController !== "undefined" ? examController.generationStep : "Generating..."
                        color: Theme.accent
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        Layout.alignment: Qt.AlignHCenter
                    }
                    
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 250; height: 6; radius: 3
                        color: Theme.surface3
                        
                        Rectangle {
                            width: (typeof examController !== "undefined" ? examController.generationProgress / 100 : 0) * parent.width
                            height: parent.height; radius: 3
                            color: Theme.accent
                            Behavior on width { NumberAnimation { duration: 200 } }
                        }
                    }
                }
                
                // If not generating and still empty
                Text {
                    visible: typeof examController === "undefined" || examController.generationProgress >= 100
                    text: "No questions generated yet."
                    color: Theme.muted
                    font.pixelSize: 16
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            // State 2: Finished
            ColumnLayout {
                anchors.centerIn: parent
                visible: isFinished
                spacing: 24

                Text {
                    text: "🎉 Exam Finished!"
                    color: Theme.accent
                    font.pixelSize: 32
                    font.weight: Font.Bold
                    Layout.alignment: Qt.AlignHCenter
                }
                
                Text {
                    text: "Your answers have been saved and will be evaluated."
                    color: Theme.muted
                    font.pixelSize: 16
                    Layout.alignment: Qt.AlignHCenter
                }
                
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 200; height: 48; radius: 8
                    color: Theme.accent
                    
                    Text {
                        anchors.centerIn: parent
                        text: "View Progress"
                        color: "#000"
                        font.pixelSize: 16
                        font.weight: Font.Bold
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: window.currentPage = "progress"
                    }
                }
            }

            // State 3: Active Question
            ColumnLayout {
                anchors.fill: parent
                visible: !isFinished && questions.length > 0
                spacing: 24

                // Question Box
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: qText.implicitHeight + 40
                    color: Theme.surface
                    border.color: Theme.border
                    border.width: 1
                    radius: 12
                    
                    Text {
                        id: qText
                        anchors.fill: parent
                        anchors.margins: 20
                        text: currentQuestion ? currentQuestion.text : ""
                        color: Theme.foreground
                        font.family: Theme.fontSans
                        font.pixelSize: 18
                        wrapMode: Text.WordWrap
                    }
                }
                
                // Answers Area
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    // MCQ
                    ColumnLayout {
                        anchors.fill: parent
                        visible: currentQuestion && currentQuestion.type === "mcq"
                        spacing: 12
                        
                        Repeater {
                            model: currentQuestion && currentQuestion.choices ? currentQuestion.choices : []
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: 56
                                radius: 8
                                
                                property bool isSelected: userAnswers[currentIndex] === String(index)
                                
                                color: isSelected ? Theme.accentGlow : Theme.surface2
                                border.color: isSelected ? Theme.accent : Theme.border
                                border.width: 1
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 12
                                    
                                    Rectangle {
                                        width: 20; height: 20; radius: 10
                                        color: "transparent"
                                        border.color: isSelected ? Theme.accent : Theme.border
                                        border.width: 2
                                        
                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 10; height: 10; radius: 5
                                            color: Theme.accent
                                            visible: isSelected
                                        }
                                    }
                                    
                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData
                                        color: Theme.foreground
                                        font.family: Theme.fontSans
                                        font.pixelSize: 15
                                        wrapMode: Text.WordWrap
                                    }
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var ans = Object.assign({}, userAnswers);
                                        ans[currentIndex] = String(index);
                                        userAnswers = ans;
                                    }
                                }
                            }
                        }
                        
                        Item { Layout.fillHeight: true }
                    }
                    
                    // True/False
                    RowLayout {
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: currentQuestion && currentQuestion.type === "truefalse"
                        spacing: 24
                        
                        Repeater {
                            model: [
                                { label: "True", val: "true", color: "#3fb950" },
                                { label: "False", val: "false", color: "#f85149" }
                            ]
                            delegate: Rectangle {
                                width: 200; height: 80; radius: 12
                                
                                property bool isSelected: userAnswers[currentIndex] === modelData.val
                                
                                color: isSelected ? Qt.rgba(Qt.color(modelData.color).r, Qt.color(modelData.color).g, Qt.color(modelData.color).b, 0.1) : Theme.surface2
                                border.color: isSelected ? modelData.color : Theme.border
                                border.width: 2
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: isSelected ? modelData.color : Theme.foreground
                                    font.pixelSize: 24
                                    font.weight: Font.Bold
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var ans = Object.assign({}, userAnswers);
                                        ans[currentIndex] = modelData.val;
                                        userAnswers = ans;
                                    }
                                }
                            }
                        }
                    }
                    
                    // Open Ended
                    ColumnLayout {
                        anchors.fill: parent
                        visible: currentQuestion && currentQuestion.type === "openended"
                        
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: Theme.surface2
                            border.color: Theme.border
                            border.width: 1
                            radius: 8
                            
                            Flickable {
                                anchors.fill: parent
                                anchors.margins: 12
                                TextArea.flickable: TextArea {
                                    id: openTextArea
                                    placeholderText: "Type your answer here..."
                                    color: Theme.foreground
                                    font.pixelSize: 15
                                    wrapMode: Text.Wrap
                                    background: null
                                    
                                    onTextChanged: {
                                        var ans = Object.assign({}, userAnswers);
                                        ans[currentIndex] = text;
                                        userAnswers = ans;
                                    }
                                    
                                    Connections {
                                        target: examPlayer
                                        function onCurrentIndexChanged() {
                                            openTextArea.text = userAnswers[currentIndex] || "";
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Bottom actions
                RowLayout {
                    Layout.fillWidth: true
                    
                    Rectangle {
                        width: 120; height: 44; radius: 8
                        color: Theme.surface3
                        visible: currentIndex > 0
                        
                        Text {
                            anchors.centerIn: parent
                            text: "Previous"
                            color: Theme.foreground
                            font.pixelSize: 14
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: currentIndex--
                        }
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    Rectangle {
                        width: 120; height: 44; radius: 8
                        color: userAnswers[currentIndex] !== undefined && userAnswers[currentIndex] !== "" ? Theme.accent : Theme.surface3
                        
                        Text {
                            anchors.centerIn: parent
                            text: currentIndex === questions.length - 1 ? "Submit" : "Next"
                            color: userAnswers[currentIndex] !== undefined && userAnswers[currentIndex] !== "" ? "#000" : Theme.muted
                            font.pixelSize: 14
                            font.weight: Font.Bold
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (currentIndex < questions.length - 1) {
                                    currentIndex++;
                                } else if (currentIndex === questions.length - 1) {
                                    if (typeof examController !== "undefined") {
                                        examController.submitExam(userAnswers);
                                    }
                                    window.currentPage = "progress";
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
