import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window

    width: 720
    height: 480
    minimumWidth: 480
    minimumHeight: 360
    visible: true
    title: model.title
    color: Theme.background

    AppModel {
        id: model
    }

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.spaceXl * 2, 560)
        height: content.implicitHeight + Theme.spaceXl * 2
        radius: Theme.radiusMd
        color: model.count % 2 === 0 ? Theme.surface : Theme.accentSoft

        Behavior on color {
            ColorAnimation {
                duration: Theme.motionNormal
                easing.type: Theme.easingStandard
            }
        }

        ColumnLayout {
            id: content

            anchors.fill: parent
            anchors.margins: Theme.spaceXl
            spacing: Theme.spaceLg

            Label {
                Layout.fillWidth: true
                text: model.title
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeTitle
                font.weight: Theme.fontWeightTitle
                wrapMode: Text.WordWrap
            }

            Label {
                Layout.fillWidth: true
                text: qsTr("This QML view reads and writes properties on a C++ QObject.")
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeBody
                wrapMode: Text.WordWrap
            }

            TextField {
                Layout.fillWidth: true
                text: model.title
                placeholderText: qsTr("Application title")
                selectByMouse: true
                onEditingFinished: model.title = text
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spaceMd

                Label {
                    Layout.fillWidth: true
                    text: qsTr("Count: %1").arg(model.count)
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeBody
                }

                Button {
                    text: qsTr("Reset")
                    onClicked: model.reset()
                }

                Button {
                    text: qsTr("Increment")
                    highlighted: true
                    onClicked: model.count += 1
                }
            }
        }
    }
}
