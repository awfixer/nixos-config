import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Brave AI search ("Ask"). There is no embeddable widget for it, so this tab
// offers a search-style input that opens the query on search.brave.com/ask in
// the default browser and keeps a session-local list of recent asks.
Item {
    id: root
    property real padding: 4
    property var inputField: askInputField
    property var history: []
    property int maxHistoryEntries: 8
    property string askUrlBase: "https://search.brave.com/ask?q="

    onFocusChanged: focus => {
        if (focus)
            root.inputField.forceActiveFocus();
    }

    function ask(question) {
        const trimmed = question.trim();
        if (trimmed.length === 0)
            return;
        Qt.openUrlExternally(root.askUrlBase + encodeURIComponent(trimmed));
        root.history = [trimmed, ...root.history.filter(entry => entry !== trimmed)].slice(0, root.maxHistoryEntries);
        askInputField.clear();
        askInputField.forceActiveFocus();
    }

    Keys.onPressed: event => {
        askInputField.forceActiveFocus();
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: root.padding
        }
        spacing: root.padding

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            PagePlaceholder {
                shown: root.history.length === 0
                icon: "travel_explore"
                title: Translation.tr("Ask")
                description: Translation.tr("Type a question and press Enter\nOpens Brave AI search in your browser")
            }

            ColumnLayout { // Recent asks
                visible: root.history.length > 0
                anchors.centerIn: parent
                width: Math.min(implicitWidth, parent.width)
                spacing: 10

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    text: Translation.tr("Recent asks")
                }

                Flow { // Clickable list of previous questions
                    id: historyFlow
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 5

                    Repeater {
                        model: ScriptModel {
                            values: root.history
                        }
                        delegate: ApiCommandButton {
                            required property var modelData
                            buttonText: modelData.length > 40 ? modelData.slice(0, 37) + "..." : modelData
                            bounce: false
                            onClicked: root.ask(modelData)
                        }
                    }
                }
            }
        }

        Rectangle { // Input area
            id: inputWrapper
            Layout.fillWidth: true
            radius: Appearance.rounding.normal - root.padding
            color: Appearance.colors.colLayer2
            implicitHeight: Math.max(inputFieldRowLayout.implicitHeight + inputFieldRowLayout.anchors.topMargin * 2, 45)
            clip: true

            RowLayout { // Input field and send button
                id: inputFieldRowLayout
                anchors {
                    fill: parent
                    topMargin: 5
                    bottomMargin: 5
                }
                spacing: 0

                StyledTextArea { // The actual TextArea
                    id: askInputField
                    wrapMode: TextArea.Wrap
                    Layout.fillWidth: true
                    padding: 10
                    color: activeFocus ? Appearance.m3colors.m3onSurface : Appearance.m3colors.m3onSurfaceVariant
                    renderType: Text.NativeRendering
                    placeholderText: Translation.tr("Ask anything...")
                    background: null

                    Keys.onPressed: event => {
                        if ((event.key === Qt.Key_Enter || event.key === Qt.Key_Return)) {
                            if (event.modifiers & Qt.ShiftModifier) { // Insert newline
                                askInputField.insert(askInputField.cursorPosition, "\n");
                                event.accepted = true;
                            } else { // Submit
                                root.ask(text);
                                event.accepted = true;
                            }
                        } else if (event.key === Qt.Key_Escape && text.length > 0) {
                            askInputField.clear();
                            event.accepted = true;
                        }
                    }
                }

                RippleButton { // Send button
                    id: sendButton
                    Layout.alignment: Qt.AlignTop
                    Layout.rightMargin: 5
                    implicitWidth: 40
                    implicitHeight: 40
                    buttonRadius: Appearance.rounding.small
                    enabled: askInputField.text.trim().length > 0
                    toggled: enabled

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: sendButton.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.ask(askInputField.text)
                    }

                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        iconSize: 22
                        color: sendButton.enabled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer2Disabled
                        text: "arrow_upward"
                    }
                }
            }
        }
    }
}
