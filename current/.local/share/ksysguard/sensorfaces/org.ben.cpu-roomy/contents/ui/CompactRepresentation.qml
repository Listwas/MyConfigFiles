import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors
import org.kde.ksysguard.faces as Faces

Faces.CompactSensorFace {
    id: root
    readonly property int leftInset: 4
    readonly property int rightInset: 1
    readonly property int columnGap: 5
    readonly property int processorWidth: Math.ceil(Math.max(cpuMetrics.width, gpuMetrics.width))
    readonly property int usageWidth: Math.ceil(usageMetrics.width)
    readonly property int temperatureWidth: Math.ceil(temperatureMetrics.width)
    readonly property int metricsWidth: leftInset + processorWidth + usageWidth + temperatureWidth + 2 * columnGap + rightInset
    Layout.minimumWidth: metricsWidth
    Layout.preferredWidth: metricsWidth
    Layout.maximumWidth: metricsWidth

    TextMetrics { id: cpuMetrics; font: Kirigami.Theme.defaultFont; text: "CPU" }
    TextMetrics { id: gpuMetrics; font: Kirigami.Theme.defaultFont; text: "GPU" }
    TextMetrics { id: usageMetrics; font: Kirigami.Theme.defaultFont; text: "100%" }
    TextMetrics { id: temperatureMetrics; font: Kirigami.Theme.defaultFont; text: "100 °C" }
    contentItem: Item {
        ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 3
        anchors.bottomMargin: 3
        anchors.leftMargin: root.leftInset
        anchors.rightMargin: root.rightInset
        spacing: 0
        Repeater {
            model: 2
            RowLayout {
                required property int index
                spacing: root.columnGap
                Layout.fillWidth: true
                Layout.fillHeight: true
                Label {
                    text: index === 0 ? "CPU" : "GPU"
                    font: Kirigami.Theme.defaultFont
                    Layout.preferredWidth: root.processorWidth
                }
                Label {
                    color: "#ace1d6"
                    text: Number.isFinite(Number(usage.value)) ? Math.round(Number(usage.value)) + "%" : "—"
                    font: Kirigami.Theme.defaultFont
                    Layout.preferredWidth: root.usageWidth
                    horizontalAlignment: Text.AlignLeft
                    elide: Text.ElideRight
                }
                Label {
                    color: "#d8c3ad"
                    text: Number.isFinite(Number(temperature.value)) ? Math.round(Number(temperature.value)) + " °C" : "—"
                    font: Kirigami.Theme.defaultFont
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignLeft
                    elide: Text.ElideRight
                }
                Sensors.Sensor {
                    id: usage
                    sensorId: root.controller.highPrioritySensorIds[index] || ""
                    updateRateLimit: root.controller.updateRateLimit
                }
                Sensors.Sensor {
                    id: temperature
                    sensorId: root.controller.highPrioritySensorIds[index + 2] || ""
                    updateRateLimit: root.controller.updateRateLimit
                }
            }
        }
    }
    }
}
