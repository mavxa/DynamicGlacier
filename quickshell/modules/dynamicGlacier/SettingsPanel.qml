import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property bool liquidGlassEnabled: false
    property int idleWidth: 340
    property int idleHeight: 132
    property string fontFamily: "Noto Sans"
    property real morph: 0

    readonly property color primaryText: "#f7f7f7"
    readonly property color secondaryText: "#777777"
    readonly property int panelPadding: 16
    readonly property int headerHeight: 32
    readonly property int glassRowHeight: 54
    readonly property int sizeRowHeight: 64
    readonly property int footerHeight: 28
    readonly property int sectionSpacing: 10
    readonly property real contentHeight: root.panelPadding * 2
                                          + root.headerHeight
                                          + root.glassRowHeight
                                          + root.sizeRowHeight
                                          + root.footerHeight
                                          + root.sectionSpacing * 3
    readonly property real panelProgress: Math.max(0, Math.min(1, (root.morph - 0.22) / 0.78))

    signal closeRequested
    signal liquidGlassRequested(bool enabled)
    signal idleWidthRequested(int width)
    signal idleHeightRequested(int height)
    signal resetRequested

    component StepControl: Rectangle {
        id: stepControl

        required property string label
        required property string valueText
        required property int step

        signal valueRequested(int delta)

        Layout.fillWidth: true
        Layout.preferredHeight: root.sizeRowHeight
        radius: 14
        color: "#080808"
        border.width: 1
        border.color: "#202020"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: stepControl.label
                    color: "#a8a8a8"
                    font.family: root.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }

                Text {
                    text: stepControl.valueText
                    color: root.primaryText
                    font.family: root.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Bold
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: [-stepControl.step, stepControl.step]

                    delegate: Rectangle {
                        id: stepButton

                        required property int modelData

                        Layout.fillWidth: true
                        Layout.preferredHeight: 22
                        radius: 8
                        color: stepMouse.containsMouse ? "#181818" : "#0d0d0d"
                        border.width: 1
                        border.color: "#242424"

                        MIcon {
                            anchors.centerIn: parent
                            name: stepButton.modelData < 0 ? "remove" : "add"
                            size: 12
                            color: "#cfcfcf"
                        }

                        MouseArea {
                            id: stepMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: stepControl.valueRequested(stepButton.modelData)
                        }
                    }
                }
            }
        }
    }

    opacity: root.panelProgress
    visible: opacity > 0.001
    scale: 0.94 + 0.06 * root.panelProgress
    transformOrigin: Item.Top

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.panelPadding
        spacing: root.sectionSpacing

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: root.headerHeight
            spacing: 10

            Rectangle {
                Layout.preferredWidth: root.headerHeight
                Layout.preferredHeight: root.headerHeight
                radius: 11
                color: "#090909"
                border.width: 1
                border.color: "#232323"

                MIcon {
                    anchors.centerIn: parent
                    name: "settings"
                    size: 15
                    color: root.primaryText
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: "Glacier settings"
                    color: root.primaryText
                    elide: Text.ElideRight
                    font.family: root.fontFamily
                    font.pixelSize: 15
                    font.weight: Font.Bold
                }

                Text {
                    Layout.fillWidth: true
                    text: "Saved automatically"
                    color: root.secondaryText
                    elide: Text.ElideRight
                    font.family: root.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
            }

            Rectangle {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                radius: 10
                color: closeMouse.containsMouse ? "#1a1a1a" : "#0a0a0a"
                border.width: 1
                border.color: "#232323"

                MIcon {
                    anchors.centerIn: parent
                    name: "close"
                    size: 12
                    color: "#999999"
                }

                MouseArea {
                    id: closeMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeRequested()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root.glassRowHeight
            radius: 14
            color: "#080808"
            border.width: 1
            border.color: root.liquidGlassEnabled ? "#343434" : "#202020"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                MIcon {
                    name: "water_drop"
                    size: 17
                    color: root.liquidGlassEnabled ? "#f0f0f0" : "#777777"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 7

                        Text {
                            text: "Liquid Glass"
                            color: root.primaryText
                            font.family: root.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }

                        Rectangle {
                            Layout.preferredWidth: experimentalLabel.implicitWidth + 10
                            Layout.preferredHeight: 16
                            radius: 8
                            color: "#141414"
                            border.width: 1
                            border.color: "#292929"

                            Text {
                                id: experimentalLabel

                                anchors.centerIn: parent
                                text: "EXPERIMENTAL"
                                color: "#8d8d8d"
                                font.family: root.fontFamily
                                font.pixelSize: 8
                                font.weight: Font.Bold
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Real backdrop blur for every Glacier surface"
                        color: root.secondaryText
                        elide: Text.ElideRight
                        font.family: root.fontFamily
                        font.pixelSize: 10
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 22
                    radius: 11
                    color: root.liquidGlassEnabled ? "#f0f0f0" : "#0a0a0a"
                    border.width: 1
                    border.color: root.liquidGlassEnabled ? "#f0f0f0" : "#292929"

                    Rectangle {
                        width: 16
                        height: 16
                        radius: 8
                        y: 3
                        x: root.liquidGlassEnabled ? parent.width - width - 3 : 3
                        color: root.liquidGlassEnabled ? "#000000" : "#555555"

                        Behavior on x {
                            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.liquidGlassRequested(!root.liquidGlassEnabled)
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: root.sizeRowHeight
            spacing: 8

            StepControl {
                label: "IDLE WIDTH"
                valueText: root.idleWidth + " px"
                step: 20
                onValueRequested: delta => root.idleWidthRequested(root.idleWidth + delta)
            }

            StepControl {
                label: "IDLE HEIGHT"
                valueText: root.idleHeight + " px"
                step: 8
                onValueRequested: delta => root.idleHeightRequested(root.idleHeight + delta)
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: root.footerHeight

            Text {
                Layout.fillWidth: true
                text: "Handle mode is available in the idle header"
                color: "#606060"
                elide: Text.ElideRight
                font.family: root.fontFamily
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }

            Rectangle {
                Layout.preferredWidth: 76
                Layout.preferredHeight: root.footerHeight
                radius: 10
                color: resetMouse.containsMouse ? "#181818" : "#0a0a0a"
                border.width: 1
                border.color: "#242424"

                Text {
                    anchors.centerIn: parent
                    text: "Reset"
                    color: "#bdbdbd"
                    font.family: root.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    id: resetMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.resetRequested()
                }
            }
        }
    }
}
