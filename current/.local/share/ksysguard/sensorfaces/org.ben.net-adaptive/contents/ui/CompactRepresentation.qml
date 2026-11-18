import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors
import org.kde.ksysguard.faces as Faces

Faces.CompactSensorFace {
    id: root
    Sensors.Sensor { id: download; sensorId: root.controller.highPrioritySensorIds[0] || ""; updateRateLimit: root.controller.updateRateLimit }
    Sensors.Sensor { id: upload; sensorId: root.controller.highPrioritySensorIds[1] || ""; updateRateLimit: root.controller.updateRateLimit }
    TextMetrics { id: downMetrics; font: Kirigami.Theme.defaultFont; text: download.formattedValue }
    TextMetrics { id: upMetrics; font: Kirigami.Theme.defaultFont; text: upload.formattedValue }
    TextMetrics { id: downArrowMetrics; font: Kirigami.Theme.defaultFont; text: root.controller.sensorLabels[download.sensorId] || "" }
    TextMetrics { id: upArrowMetrics; font: Kirigami.Theme.defaultFont; text: root.controller.sensorLabels[upload.sensorId] || "" }
    readonly property int leftInset: 2
    readonly property int rightInset: 5
    readonly property int columnGap: 4
    readonly property int arrowWidth: Math.ceil(Math.max(downArrowMetrics.width, upArrowMetrics.width))
    readonly property int desiredWidth: Math.max(64, Math.ceil(Math.max(downMetrics.width, upMetrics.width)) + leftInset + rightInset + columnGap + arrowWidth + 2)
    Layout.minimumWidth: desiredWidth
    Layout.preferredWidth: desiredWidth
    Layout.maximumWidth: desiredWidth
    contentItem: Item {
        ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 3
        anchors.bottomMargin: 3
        anchors.leftMargin: root.leftInset
        anchors.rightMargin: root.rightInset
        spacing: 0
        Repeater {
            id: readings
            model: root.controller.highPrioritySensorIds
            RowLayout {
                spacing: root.columnGap
                Layout.fillWidth: true
                Layout.fillHeight: true
                Label {
                    color: "#ace1d6"
                    text: root.controller.sensorLabels[modelData] || ""
                    font: Kirigami.Theme.defaultFont
                    Layout.preferredWidth: root.arrowWidth
                }
                Label {
                    Layout.fillWidth: true
                    text: sensor.formattedValue
                    font: Kirigami.Theme.defaultFont
                    horizontalAlignment: Text.AlignLeft
                    elide: Text.ElideRight
                }
                Sensors.Sensor {
                    id: sensor
                    sensorId: modelData
                    updateRateLimit: root.controller.updateRateLimit
                }
            }
        }
    }
    }
}
