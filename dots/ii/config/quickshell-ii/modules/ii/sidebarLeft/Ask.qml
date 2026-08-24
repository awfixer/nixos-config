import qs
import QtQuick
import QtWebEngine

// Brave AI search ("Ask"), rendered live inside the panel via QtWebEngine
// (enabled by the EnableQtWebEngineQuick pragma in shell.qml).
Item {
    id: root

    onFocusChanged: focus => {
        if (focus)
            webView.forceActiveFocus();
    }

    WebEngineView {
        id: webView
        anchors.fill: parent
        url: "https://search.brave.com/ask"
    }
}
