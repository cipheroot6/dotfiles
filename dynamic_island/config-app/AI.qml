import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

PagePanel {
    title: qsTr("Dynamic Island - Extras")

    ColumnLayout {
        width: parent.width
        spacing: 12

        Label {
            text: qsTr("AI Prompt (Ollama)")
            font.weight: 600
        }

        ConfigTextField {
            Layout.fillWidth: true
            label: qsTr("Endpoint")
            text: Backend.ollamaEndpoint
            onEditingFinished: Backend.ollamaEndpoint = text
        }

        ConfigTextField {
            Layout.fillWidth: true
            label: qsTr("Model Name")
            text: Backend.ollamaModel
            onEditingFinished: Backend.ollamaModel = text
        }

        ConfigTextField {
            Layout.fillWidth: true
            label: qsTr("API Key")
            text: Backend.ollamaApiKey
            echoMode: TextInput.Password
            onEditingFinished: Backend.ollamaApiKey = text
        }

        Item { Layout.preferredHeight: 12 }

        Label {
            text: qsTr("Fun & Productivity")
            font.weight: 600
        }

        RowLayout {
            Label {
                text: qsTr("Enable Desktop Pet")
                Layout.fillWidth: true
            }
            Switch {
                checked: Backend.petEnabled
                onCheckedChanged: Backend.petEnabled = checked
            }
        }
    }
}
