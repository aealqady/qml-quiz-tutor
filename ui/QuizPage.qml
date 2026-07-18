import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: quizPage
    color: "transparent"

    // Documents from database
    property var readyDocs: []

    // Config state
    property int questionCount: 8
    property int maxQuestions: 32 // Initially based on first document
    property string selectedLanguage: "Arabic"
    property var selectedTypes: ({"mcq": true, "truefalse": true, "openended": true})
    property var selectedDiffs: ({"easy": true, "medium": true, "hard": true})
    property bool timeLimitEnabled: true
    property int timeLimitMin: 20
    property int selectedDocCount: 1

    function refreshDocs() {
        if (typeof uploadController === "undefined") return;
        var allDocs = uploadController.documents;
        var filtered = [];
        for (var i = 0; i < allDocs.length; i++) {
            if (allDocs[i].status === "ready") {
                var isSelected = filtered.length === 0;
                for (var j = 0; j < quizPage.readyDocs.length; j++) {
                    if (quizPage.readyDocs[j].id === allDocs[i].id) {
                        isSelected = quizPage.readyDocs[j].selected;
                        break;
                    }
                }
                filtered.push({
                    id: allDocs[i].id,
                    name: allDocs[i].name,
                    pages: allDocs[i].pages,
                    questions: allDocs[i].questions,
                    topics: 0,
                    selected: isSelected
                });
            }
        }
        quizPage.readyDocs = filtered;
        _recalcStats();
    }

    // Toggle document selection — runs in quizPage scope, not in delegate scope
    function toggleDoc(docIndex) {
        var arr = JSON.parse(JSON.stringify(quizPage.readyDocs));
        arr[docIndex].selected = !arr[docIndex].selected;
        quizPage.readyDocs = arr;
        _recalcStats();
    }

    // Recalculate selectedDocCount and maxQuestions from current readyDocs
    function _recalcStats() {
        var count = 0;
        var totalQs = 0;
        for (var k = 0; k < quizPage.readyDocs.length; k++) {
            if (quizPage.readyDocs[k].selected) {
                count++;
                totalQs += quizPage.readyDocs[k].questions;
            }
        }
        quizPage.selectedDocCount = count;
        quizPage.maxQuestions = Math.max(4, totalQs > 0 ? totalQs : 20);
        if (quizPage.questionCount > quizPage.maxQuestions) {
            quizPage.questionCount = quizPage.maxQuestions;
        }
    }

    // Launch exam — runs in quizPage scope, captures all values before navigating
    function launchExam() {
        console.log("Generate Exam clicked!");
        if (typeof examController === "undefined") return;

        var doc_id = 1;
        for (var i = 0; i < quizPage.readyDocs.length; i++) {
            if (quizPage.readyDocs[i].selected) {
                var parsed = parseInt(quizPage.readyDocs[i].id.toString().replace('d', ''));
                if (!isNaN(parsed)) doc_id = parsed;
                break;
            }
        }
        var types = [];
        for (var t in quizPage.selectedTypes) { if (quizPage.selectedTypes[t]) types.push(t); }
        var diffs = [];
        for (var d in quizPage.selectedDiffs) { if (quizPage.selectedDiffs[d]) diffs.push(d); }

        examController.startGeneration(doc_id, quizPage.questionCount, types, diffs, quizPage.selectedLanguage);
        window.currentPage = "examPlayer";
    }

    Component.onCompleted: {
        refreshDocs();
    }

    Connections {
        target: typeof uploadController !== "undefined" ? uploadController : null
        function onDocumentsChanged() {
            refreshDocs();
        }
    }

    Flickable {
        id: flickable
        anchors.fill: parent
        contentHeight: setupCol.implicitHeight + 64
        contentWidth: width  // Force contentItem to fill flickable width
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: setupCol
            width: Math.min(flickable.width - 80, 980)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 32
            spacing: 24

            // ─── Header ───────────────────────────────────────
            ColumnLayout {
                spacing: 6
                Text {
                    text: "Configure Exam"
                    color: Theme.foreground
                    font.family: Theme.fontSans
                    font.pixelSize: 22
                    font.weight: Font.Bold
                    font.letterSpacing: -0.4
                }
                Text {
                    text: "Select source documents and customize question generation parameters."
                    color: Theme.muted
                    font.family: Theme.fontSans
                    font.pixelSize: 13
                }
            }

            // ─── Two-Column Layout ────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: 24

                // ══════ LEFT COLUMN ══════
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: 20

                    // ── Step 1: Source Documents ──
                    Pane {
                        Layout.fillWidth: true
                        padding: 24
                        background: Rectangle {
                            color: Theme.surface; border.color: Theme.border; border.width: 1; radius: 12
                        }

                        contentItem: ColumnLayout {
                            spacing: 14

                            // Step header
                            RowLayout {
                                spacing: 10
                                Rectangle {
                                    width: 22; height: 22; radius: 6
                                    color: Theme.accentDim
                                    border.color: Theme.borderAccent
                                    Text { anchors.centerIn: parent; text: "1"; color: Theme.accent; font.family: Theme.fontMono; font.pixelSize: 11; font.weight: Font.Bold }
                                }
                                Text { text: "Source Documents"; color: Theme.foreground; font.family: Theme.fontSans; font.pixelSize: 14; font.weight: Font.DemiBold }
                                Item { Layout.fillWidth: true }
                                Text { text: quizPage.selectedDocCount + " selected"; color: Theme.muted; font.family: Theme.fontMono; font.pixelSize: 11 }
                            }

                            // Document list
                            Repeater {
                                model: quizPage.readyDocs
                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    height: 56; radius: 8
                                    color: modelData.selected ? Theme.accentGlow : Theme.surface2
                                    border.color: modelData.selected ? Theme.borderAccent : Theme.border
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 14; anchors.rightMargin: 14
                                        spacing: 12

                                        // Checkbox
                                        Rectangle {
                                            width: 18; height: 18; radius: 4
                                            color: modelData.selected ? Theme.accent : "transparent"
                                            border.color: modelData.selected ? Theme.accent : Theme.border
                                            border.width: 1.5

                                            Text {
                                                anchors.centerIn: parent
                                                text: "✓"; color: "#000"
                                                font.pixelSize: 11; font.weight: Font.Bold
                                                visible: modelData.selected
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2
                                            Text {
                                                text: modelData.name
                                                color: Theme.foreground
                                                font.family: Theme.fontSans
                                                font.pixelSize: 13; font.weight: Font.Medium
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }
                                            Text {
                                                text: modelData.pages + " pages · " + modelData.questions + " questions · " + modelData.topics + " topics"
                                                color: Theme.muted
                                                font.family: Theme.fontMono
                                                font.pixelSize: 10
                                            }
                                        }

                                        Text {
                                            visible: modelData.selected
                                            text: "✓ SELECTED"
                                            color: Theme.accent
                                            font.family: Theme.fontMono
                                            font.pixelSize: 10
                                            font.letterSpacing: 0.8
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: quizPage.toggleDoc(index)
                                    }
                                }
                            }

                            // Topics available box
                            Rectangle {
                                Layout.fillWidth: true
                                height: 40; radius: 8
                                color: Theme.surface3

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12; anchors.rightMargin: 12
                                    spacing: 4
                                    anchors.verticalCenter: parent.verticalCenter

                                    Text {
                                        text: "Topics available: "
                                        color: Theme.foreground; font.weight: Font.Medium
                                        font.family: Theme.fontSans; font.pixelSize: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: "Supervised Learning · Unsupervised Learning · Evaluation Metrics · Feature Engineering"
                                        color: Theme.muted
                                        font.family: Theme.fontSans; font.pixelSize: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        elide: Text.ElideRight
                                        width: parent.width - 120
                                    }
                                }
                            }
                        }
                    }

                    // ── Step 2: Question Count ──
                    Pane {
                        Layout.fillWidth: true
                        padding: 24
                        background: Rectangle {
                            color: Theme.surface; border.color: Theme.border; border.width: 1; radius: 12
                        }

                        contentItem: ColumnLayout {
                            spacing: 14

                            RowLayout {
                                spacing: 10
                                Rectangle {
                                    width: 22; height: 22; radius: 6
                                    color: Theme.accentDim; border.color: Theme.borderAccent
                                    Text { anchors.centerIn: parent; text: "2"; color: Theme.accent; font.family: Theme.fontMono; font.pixelSize: 11; font.weight: Font.Bold }
                                }
                                Text { text: "Question Count"; color: Theme.foreground; font.family: Theme.fontSans; font.pixelSize: 14; font.weight: Font.DemiBold }
                                Item { Layout.fillWidth: true }
                                Text { text: String(quizPage.questionCount); color: Theme.accent; font.family: Theme.fontMono; font.pixelSize: 20; font.weight: Font.Bold }
                            }

                            Slider {
                                id: qCountSlider
                                Layout.fillWidth: true
                                from: 4; to: quizPage.maxQuestions; stepSize: 1
                                
                                Component.onCompleted: value = quizPage.questionCount
                                
                                onValueChanged: {
                                    if (quizPage.questionCount !== value) {
                                        quizPage.questionCount = value;
                                    }
                                }
                                
                                Connections {
                                    target: quizPage
                                    function onQuestionCountChanged() {
                                        if (!qCountSlider.pressed && qCountSlider.value !== quizPage.questionCount) {
                                            qCountSlider.value = quizPage.questionCount;
                                        }
                                    }
                                }

                                background: Rectangle {
                                    implicitWidth: 200
                                    implicitHeight: 6
                                    x: qCountSlider.leftPadding; y: qCountSlider.topPadding + qCountSlider.availableHeight / 2 - height / 2
                                    width: qCountSlider.availableWidth; height: 6; radius: 3
                                    color: Theme.surface3
                                    Rectangle {
                                        width: qCountSlider.visualPosition * parent.width
                                        height: parent.height; radius: 3
                                        color: Theme.accent
                                    }
                                }
                                handle: Rectangle {
                                    implicitWidth: 18
                                    implicitHeight: 18
                                    x: qCountSlider.leftPadding + qCountSlider.visualPosition * (qCountSlider.availableWidth - width)
                                    y: qCountSlider.topPadding + qCountSlider.availableHeight / 2 - height / 2
                                    width: 18; height: 18; radius: 9
                                    color: Theme.accent
                                    border.color: "#fff"; border.width: 2
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "4 min"; color: Theme.muted; font.family: Theme.fontMono; font.pixelSize: 11 }
                                Item { Layout.fillWidth: true }
                                Text { text: "~" + Math.round(quizPage.questionCount * 3) + " min est."; color: Theme.muted; font.family: Theme.fontMono; font.pixelSize: 11 }
                                Item { Layout.fillWidth: true }
                                Text { text: quizPage.maxQuestions + " max"; color: Theme.muted; font.family: Theme.fontMono; font.pixelSize: 11 }
                            }
                        }
                    }

                    // ── Step 3: Question Types ──
                    Pane {
                        Layout.fillWidth: true
                        padding: 24
                        background: Rectangle {
                            color: Theme.surface; border.color: Theme.border; border.width: 1; radius: 12
                        }

                        contentItem: ColumnLayout {
                            spacing: 14

                            RowLayout {
                                spacing: 10
                                Rectangle {
                                    width: 22; height: 22; radius: 6
                                    color: Theme.accentDim; border.color: Theme.borderAccent
                                    Text { anchors.centerIn: parent; text: "3"; color: Theme.accent; font.family: Theme.fontMono; font.pixelSize: 11; font.weight: Font.Bold }
                                }
                                Text { text: "Question Types"; color: Theme.foreground; font.family: Theme.fontSans; font.pixelSize: 14; font.weight: Font.DemiBold }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Repeater {
                                    model: [
                                        { typeId: "mcq", label: "Multiple Choice", desc: "4 options, 1 correct", icon: "◉" },
                                        { typeId: "truefalse", label: "True / False", desc: "Binary judgment", icon: "◈" },
                                        { typeId: "openended", label: "Open-ended", desc: "LLM-evaluated", icon: "◇" }
                                    ]

                                    delegate: Rectangle {
                                        Layout.fillWidth: true
                                        height: 80; radius: 8
                                        property bool isSelected: quizPage.selectedTypes[modelData.typeId] === true
                                        color: isSelected ? Theme.accentGlow : Theme.surface2
                                        border.color: isSelected ? Theme.borderAccent : Theme.border; border.width: 1

                                        ColumnLayout {
                                            anchors.centerIn: parent; spacing: 4
                                            Text { Layout.alignment: Qt.AlignHCenter; text: modelData.icon; font.pixelSize: 18; color: isSelected ? Theme.accent : Theme.muted }
                                            Text { Layout.alignment: Qt.AlignHCenter; text: modelData.label; font.pixelSize: 12; font.weight: Font.DemiBold; color: isSelected ? Theme.foreground : Theme.muted; font.family: Theme.fontSans }
                                            Text { Layout.alignment: Qt.AlignHCenter; text: modelData.desc; font.pixelSize: 10; color: Theme.muted; font.family: Theme.fontMono }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                var types = Object.assign({}, quizPage.selectedTypes);
                                                types[modelData.typeId] = !types[modelData.typeId];
                                                quizPage.selectedTypes = types;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ══════ RIGHT COLUMN ══════
                ColumnLayout {
                    Layout.preferredWidth: 320
                    Layout.alignment: Qt.AlignTop
                    spacing: 20

                    // ── Step 4: Difficulty ──
                    Pane {
                        Layout.fillWidth: true
                        padding: 24
                        background: Rectangle {
                            color: Theme.surface; border.color: Theme.border; border.width: 1; radius: 12
                        }

                        contentItem: ColumnLayout {
                            spacing: 12

                            RowLayout {
                                spacing: 10
                                Rectangle {
                                    width: 22; height: 22; radius: 6
                                    color: Theme.accentDim; border.color: Theme.borderAccent
                                    Text { anchors.centerIn: parent; text: "4"; color: Theme.accent; font.family: Theme.fontMono; font.pixelSize: 11; font.weight: Font.Bold }
                                }
                                Text { text: "Difficulty"; color: Theme.foreground; font.family: Theme.fontSans; font.pixelSize: 14; font.weight: Font.DemiBold }
                            }

                            Repeater {
                                model: [
                                    { diffId: "easy", label: "Easy", desc: "Recall & recognition", clr: "#3fb950" },
                                    { diffId: "medium", label: "Medium", desc: "Comprehension", clr: "#d29922" },
                                    { diffId: "hard", label: "Hard", desc: "Analysis & synthesis", clr: "#f85149" }
                                ]
                                delegate: Rectangle {
                                    Layout.fillWidth: true; height: 40; radius: 8
                                    property bool isActive: quizPage.selectedDiffs[modelData.diffId] === true
                                    color: isActive ? Qt.rgba(Qt.color(modelData.clr).r, Qt.color(modelData.clr).g, Qt.color(modelData.clr).b, 0.06) : Theme.surface2
                                    border.color: isActive ? Qt.rgba(Qt.color(modelData.clr).r, Qt.color(modelData.clr).g, Qt.color(modelData.clr).b, 0.3) : Theme.border
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10
                                        Rectangle { width: 8; height: 8; radius: 4; color: isActive ? modelData.clr : Theme.surface3 }
                                        Text { text: modelData.label; color: isActive ? modelData.clr : Theme.muted; font.pixelSize: 13; font.weight: Font.DemiBold; font.family: Theme.fontSans }
                                        Item { Layout.fillWidth: true }
                                        Text { text: modelData.desc; color: Theme.muted; font.pixelSize: 11; font.family: Theme.fontSans }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            var diffs = Object.assign({}, quizPage.selectedDiffs);
                                            diffs[modelData.diffId] = !diffs[modelData.diffId];
                                            quizPage.selectedDiffs = diffs;
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── Step 5: Time Limit ──
                    Pane {
                        Layout.fillWidth: true
                        padding: 24
                        background: Rectangle {
                            color: Theme.surface; border.color: Theme.border; border.width: 1; radius: 12
                        }

                        contentItem: ColumnLayout {
                            spacing: 10

                            RowLayout {
                                spacing: 10
                                Rectangle {
                                    width: 22; height: 22; radius: 6
                                    color: Theme.accentDim; border.color: Theme.borderAccent
                                    Text { anchors.centerIn: parent; text: "5"; color: Theme.accent; font.family: Theme.fontMono; font.pixelSize: 11; font.weight: Font.Bold }
                                }
                                Text { text: "Time Limit"; color: Theme.foreground; font.family: Theme.fontSans; font.pixelSize: 14; font.weight: Font.DemiBold }
                                Item { Layout.fillWidth: true }

                                // Toggle switch
                                Rectangle {
                                    width: 36; height: 20; radius: 10
                                    color: quizPage.timeLimitEnabled ? Theme.accent : Theme.surface3

                                    Rectangle {
                                        x: quizPage.timeLimitEnabled ? 18 : 2
                                        y: 2; width: 16; height: 16; radius: 8
                                        color: "#fff"
                                        Behavior on x { NumberAnimation { duration: 200 } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: quizPage.timeLimitEnabled = !quizPage.timeLimitEnabled
                                    }
                                }
                            }

                            // Duration display
                            RowLayout {
                                visible: quizPage.timeLimitEnabled
                                Layout.fillWidth: true
                                Text { text: "Duration"; color: Theme.muted; font.pixelSize: 12; font.family: Theme.fontSans }
                                Item { Layout.fillWidth: true }
                                Text { text: quizPage.timeLimitMin + " min"; color: Theme.accent; font.family: Theme.fontMono; font.pixelSize: 16; font.weight: Font.Bold }
                            }

                            Slider {
                                id: timeSlider
                                visible: quizPage.timeLimitEnabled
                                Layout.fillWidth: true
                                from: 5; to: 120; stepSize: 5
                                
                                Component.onCompleted: value = quizPage.timeLimitMin
                                
                                onValueChanged: {
                                    if (quizPage.timeLimitMin !== value) {
                                        quizPage.timeLimitMin = value;
                                    }
                                }
                                
                                Connections {
                                    target: quizPage
                                    function onTimeLimitMinChanged() {
                                        if (!timeSlider.pressed && timeSlider.value !== quizPage.timeLimitMin) {
                                            timeSlider.value = quizPage.timeLimitMin;
                                        }
                                    }
                                }

                                background: Rectangle {
                                    implicitWidth: 200
                                    implicitHeight: 6
                                    x: timeSlider.leftPadding; y: timeSlider.topPadding + timeSlider.availableHeight / 2 - height / 2
                                    width: timeSlider.availableWidth; height: 6; radius: 3; color: Theme.surface3
                                    Rectangle { width: timeSlider.visualPosition * parent.width; height: parent.height; radius: 3; color: Theme.accent }
                                }
                                handle: Rectangle {
                                    implicitWidth: 16
                                    implicitHeight: 16
                                    x: timeSlider.leftPadding + timeSlider.visualPosition * (timeSlider.availableWidth - width)
                                    y: timeSlider.topPadding + timeSlider.availableHeight / 2 - height / 2
                                    width: 16; height: 16; radius: 8; color: Theme.accent; border.color: "#fff"; border.width: 2
                                }
                            }

                            Text {
                                visible: quizPage.timeLimitEnabled
                                text: "≈ " + Math.round(quizPage.timeLimitMin / quizPage.questionCount * 60) + "s per question"
                                color: Theme.muted; font.family: Theme.fontMono; font.pixelSize: 11
                            }

                            Text {
                                visible: !quizPage.timeLimitEnabled
                                text: "No time limit — practice at your own pace."
                                color: Theme.muted; font.pixelSize: 12; font.family: Theme.fontSans
                            }
                        }
                    }

                    // ── Step 6: Language ──
                    Pane {
                        Layout.fillWidth: true
                        padding: 24
                        background: Rectangle {
                            color: Theme.surface; border.color: Theme.border; border.width: 1; radius: 12
                        }

                        contentItem: ColumnLayout {
                            spacing: 14

                            RowLayout {
                                spacing: 10
                                Rectangle {
                                    width: 22; height: 22; radius: 6
                                    color: Theme.accentDim; border.color: Theme.borderAccent
                                    Text { anchors.centerIn: parent; text: "6"; color: Theme.accent; font.family: Theme.fontMono; font.pixelSize: 11; font.weight: Font.Bold }
                                }
                                Text { text: "Language"; color: Theme.foreground; font.family: Theme.fontSans; font.pixelSize: 14; font.weight: Font.DemiBold }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                
                                Repeater {
                                    model: ["Arabic", "English"]
                                    delegate: Rectangle {
                                        Layout.fillWidth: true; height: 40; radius: 8
                                        property bool isActive: quizPage.selectedLanguage === modelData
                                        color: isActive ? Qt.rgba(Qt.color(Theme.accent).r, Qt.color(Theme.accent).g, Qt.color(Theme.accent).b, 0.1) : Theme.surface2
                                        border.color: isActive ? Theme.accent : Theme.border
                                        border.width: 1

                                        Text { 
                                            anchors.centerIn: parent
                                            text: modelData
                                            color: isActive ? Theme.accent : Theme.muted
                                            font.pixelSize: 13; font.weight: Font.DemiBold; font.family: Theme.fontSans 
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: quizPage.selectedLanguage = modelData
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── Exam Summary + Generate Button ──
                    Pane {
                        Layout.fillWidth: true
                        padding: 24
                        background: Rectangle {
                            color: Theme.surface; border.color: Theme.borderAccent; border.width: 1; radius: 12
                        }

                        contentItem: ColumnLayout {
                            spacing: 10

                            Text { text: "EXAM SUMMARY"; color: Theme.accent; font.family: Theme.fontMono; font.pixelSize: 11; font.letterSpacing: 1.0 }

                            Repeater {
                                model: [
                                    { k: "Documents", v: quizPage.selectedDocCount + " selected" },
                                    { k: "Questions", v: String(quizPage.questionCount) },
                                    { k: "Types", v: "mcq, truefalse, openended" },
                                    { k: "Difficulty", v: "easy, medium, hard" },
                                    { k: "Time limit", v: quizPage.timeLimitEnabled ? quizPage.timeLimitMin + " min" : "Unlimited" },
                                    { k: "Language", v: quizPage.selectedLanguage }
                                ]
                                delegate: Item {
                                    Layout.fillWidth: true; height: 30

                                    RowLayout {
                                        anchors.fill: parent
                                        Text { text: modelData.k; color: Theme.muted; font.pixelSize: 12; font.family: Theme.fontSans }
                                        Item { Layout.fillWidth: true }
                                        Text { text: modelData.v; color: Theme.foreground; font.pixelSize: 12; font.weight: Font.Medium; font.family: Theme.fontMono }
                                    }
                                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
                                }
                            }

                            // Generate Button
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.topMargin: 6
                                height: 44; radius: 8
                                color: Theme.accent

                                Row {
                                    anchors.centerIn: parent; spacing: 8
                                    Text { text: "✦"; color: "#000"; font.pixelSize: 14 }
                                    Text {
                                        text: "Generate Exam with LLM"
                                        color: "#000"
                                        font.family: Theme.fontSans
                                        font.pixelSize: 14
                                        font.weight: Font.Bold
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: quizPage.launchExam()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
