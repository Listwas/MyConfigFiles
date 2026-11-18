/*
 * Copyright 2013  David Edmundson <davidedmundson@kde.org>
 * Copyright 2016  Eike Hein <hein@kde.org>
 * Copyright 2021-2024  Tino Lorenz <tilrnz@gmx.net>
 * Copyright 2022  Diego Miguel <hello@diegomiguel.me>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import QtQuick
import QtQuick.Controls as QtControls
import QtQuick.Layouts as QtLayouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
	id: layoutGeneralRoot

	property alias cfg_forceLayout: pagerLayout.currentIndex
	property alias cfg_enableDnD: enableDnD.checked
	property alias cfg_enableScrolling: enableScrolling.checked
	property alias cfg_invertScrollDirection: invertScrollDirection.checked
	property alias cfg_wrapPage: wrapPage.checked
	property alias cfg_currentDesktopSelected: currentDesktopSelectedBox.currentIndex
	property alias cfg_actionOnCompactLayout: actionOnCompactLayout.checked
	property alias cfg_stayVisible: stayVisible.checked
	property alias cfg_showDesktopNames: showDesktopNames.checked
	property alias cfg_showWindowIcons: showWindowIcons.checked
	property alias cfg_showOnlyCurrentScreen: showOnlyCurrentScreen.checked
	property alias cfg_hideDesktopsWithoutWindows: hideDesktopsWithoutWindows.checked

	// monitor order (comma-separated connector names, left → right)
	property string cfg_screenOrder: ""
	property var monitorOrder: []

	function screenByName(nm) {
		var s = Qt.application.screens
		for (var i = 0; i < s.length; i++)
			if (s[i].name === nm) return s[i]
		return null
	}
	function rebuildOrder() {
		var s = Qt.application.screens
		var all = []
		for (var i = 0; i < s.length; i++) all.push(s[i].name)
		var saved = (cfg_screenOrder || "").trim().length ? cfg_screenOrder.split(",") : []
		var result = []
		for (var j = 0; j < saved.length; j++) {
			var nm = saved[j].trim()
			if (all.indexOf(nm) >= 0 && result.indexOf(nm) < 0) result.push(nm)
		}
		for (var k = 0; k < all.length; k++)
			if (result.indexOf(all[k]) < 0) result.push(all[k])
		monitorOrder = result
	}
	function moveMonitor(idx, dir) {
		var arr = monitorOrder.slice()
		var n = idx + dir
		if (n < 0 || n >= arr.length) return
		var t = arr[idx]; arr[idx] = arr[n]; arr[n] = t
		monitorOrder = arr
		cfg_screenOrder = arr.join(",")
	}
	Component.onCompleted: rebuildOrder()

	Kirigami.FormLayout {
		id: layoutGeneral

		QtControls.CheckBox {
			id: stayVisible
			text: i18n("Stay visible when there is only one virtual desktop")
		}

		QtControls.CheckBox {
			id: enableDnD
			text: i18n("Enable dropping apps to move")
			QtControls.ToolTip.visible: hovered
			QtControls.ToolTip.text: i18n("Enable drag-and-dropping apps from the task manager to move them to other desktops")
		}

		QtControls.CheckBox {
			id: enableScrolling
			text: i18n("Enable scrolling to change the active desktop")
		}

		QtControls.CheckBox {
			id: invertScrollDirection
			enabled: enableScrolling.checked
			text: i18n("Invert scroll direction")
		}

		QtControls.CheckBox {
			id: wrapPage
			enabled: enableScrolling.checked
			text: i18n("Navigation wraps around")
		}

		QtControls.CheckBox {
			id: showOnlyCurrentScreen
			text: i18n("Only show windows from current Screen in pager")
		}

		QtControls.CheckBox {
			id: hideDesktopsWithoutWindows
			text: i18n("Hide desktops without any windows")
		}

		Item {
			Kirigami.FormData.isSection: true
		}

		QtControls.Label {
			Kirigami.FormData.label: i18n("Monitor order:")
			text: i18n("Only one monitor detected")
			visible: layoutGeneralRoot.monitorOrder.length <= 1
			opacity: 0.7
		}

		QtLayouts.ColumnLayout {
			Kirigami.FormData.label: i18n("Monitor order (top = leftmost):")
			visible: layoutGeneralRoot.monitorOrder.length > 1
			spacing: Kirigami.Units.smallSpacing

			Repeater {
				model: layoutGeneralRoot.monitorOrder
				delegate: QtLayouts.RowLayout {
					required property int index
					required property var modelData
					QtLayouts.Layout.fillWidth: true

					QtControls.Label {
						QtLayouts.Layout.fillWidth: true
						text: {
							var s = layoutGeneralRoot.screenByName(modelData)
							var res = s ? "  (" + s.width + "\u00d7" + s.height + ")" : ""
							return (index + 1) + ".  " + modelData + res
						}
					}
					QtControls.ToolButton {
						icon.name: "go-up"
						enabled: index > 0
						QtControls.ToolTip.visible: hovered
						QtControls.ToolTip.text: i18n("Move left (earlier)")
						onClicked: layoutGeneralRoot.moveMonitor(index, -1)
					}
					QtControls.ToolButton {
						icon.name: "go-down"
						enabled: index < layoutGeneralRoot.monitorOrder.length - 1
						QtControls.ToolTip.visible: hovered
						QtControls.ToolTip.text: i18n("Move right (later)")
						onClicked: layoutGeneralRoot.moveMonitor(index, 1)
					}
				}
			}
		}

		Item {
			Kirigami.FormData.isSection: true
		}

		QtControls.ButtonGroup {
			buttons: [showDesktopNumbers, showDesktopNames, showWindowIcons]
		}

		QtControls.RadioButton {
			id: showDesktopNumbers
			Kirigami.FormData.label: i18n("What to show in box:")
			text: i18n("Show desktop numbers")
			checked: !showDesktopNames.checked && !showWindowIcons.checked
		}

		QtControls.RadioButton {
			id: showDesktopNames
			text: i18n("Show desktop names")
		}

		QtControls.RadioButton {
			id: showWindowIcons
			text: i18n("Show window icons")
		}

		Item {
			Kirigami.FormData.isSection: true
		}

		QtLayouts.RowLayout {
			QtLayouts.Layout.fillWidth: true

			Kirigami.FormData.label: i18n("Layout:")
			QtControls.ComboBox {
				id: pagerLayout
				model: [i18n("Adaptive"), i18n("Full"), i18n("Compact")]
			}

			QtControls.Button {
				id: infoButton
				icon.name: "dialog-information"
				QtControls.ToolTip.visible: hovered
				QtControls.ToolTip.text: i18n(
					"<b>Adaptive</b>:<br>Switch the layout depending on available space.<br><br><b>Full</b>:<br>Always show full layout.<br><br><b>Compact</b>:<br>Always show compact layout."
				)
			}
		}

		Item {
			Kirigami.FormData.isSection: true
		}

		QtControls.ComboBox {
			id: currentDesktopSelectedBox
			Kirigami.FormData.label: i18n("Selecting current virtual desktop:")

			model: [i18n("Does nothing"), i18n("Shows the desktop"), i18n("Shows overview")]
		}

		QtControls.CheckBox {
			id: actionOnCompactLayout
			text: i18n("Directly do selected action in compact layout\ninstead of expanding full layout")
		}
	}
}
