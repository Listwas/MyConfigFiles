/*
 * Copyright 2012  Luís Gabriel Lima <lampih@gmail.com>
 * Copyright 2016  Kai Uwe Broulik <kde@privat.broulik.de>
 * Copyright 2016  Eike Hein <hein@kde.org>
 * Copyright 2021  Tino Lorenz <tilrnz@gmx.net>
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
 * You should have received a copy of the GNU General Public License.
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.workspace.dbus as DBus
import org.kde.taskmanager
import org.kde.kcmutils as KCM
import org.kde.config as KConfig
import org.kde.plasma.plasma5support as Plasma5Support

import "./lib"

PlasmoidItem {
	id: root

	property int wheelDelta: 0

	// list of physical screens in user-defined order (monitor names in
	// plasmoid.configuration.screenOrder, left→right). Unknown/new monitors are
	// appended; hotplug still updates the list. Empty config = native Qt order.
	property var screens: {
		var all = Qt.application.screens
		var orderStr = (plasmoid.configuration.screenOrder || "").trim()
		if (orderStr.length === 0)
			return all
		var order = orderStr.split(",")
		var byName = ({})
		for (var i = 0; i < all.length; i++)
			byName[all[i].name] = all[i]
		var result = []
		for (var j = 0; j < order.length; j++) {
			var nm = order[j].trim()
			if (byName[nm] !== undefined) {
				result.push(byName[nm])
				delete byName[nm]
			}
		}
		for (var k = 0; k < all.length; k++) {
			if (byName[all[k].name] !== undefined)
				result.push(all[k])
		}
		return result
	}

	// есть ли сейчас вообще сфокусированное окно — для точной подсветки
	// "этот монитор + этот стол" (см. isActiveCell в ReprLayout)
	property bool anyWindowActive:
		mainTasksModel.activeTask !== undefined && mainTasksModel.activeTask.row >= 0

	// Отражает настройку KWin "Switch desktops independently for each screen"
	// (kwinrc: [Desktops] PerOutputVirtualDesktops). true -> разбивка по экранам;
	// false -> один набор столов с окнами со всех мониторов вместе.
	property bool perOutputEnabled: false

	// winId окна, которое сейчас перетаскивают между столами (drag&drop)
	property string draggedWinId: ""

	// Память виджета: последний наблюдённый текущий стол на каждом мониторе
	// { имя_монитора: desktopId }. Заполняется, когда на мониторе появляется
	// сфокусированное окно, и СОХРАНЯЕТСЯ, даже если фокус ушёл на другой
	// монитор — это и даёт одновременную подсветку всех экранов.
	property var perScreenDesktop: ({})

	function recordActive(screenName, desktopId) {
		if (!screenName || desktopId === undefined)
			return
		var m = root.perScreenDesktop || ({})
		if (m[screenName] === desktopId)
			return
		var copy = {}
		for (var k in m)
			copy[k] = m[k]
		copy[screenName] = desktopId
		root.perScreenDesktop = copy   // переприсваивание -> пересчёт подсветки
	}

	Component.onCompleted: {
		kwinCfgReader.read()
	}

	// имя монитора, на котором стоит панель с этим виджетом
	readonly property string panelScreenName: {
		var c = Plasmoid.containment
		if (!c || c.screenGeometry === undefined)
			return ""
		var all = Qt.application.screens
		for (var i = 0; i < all.length; i++)
			if (all[i].virtualX === c.screenGeometry.x
					&& all[i].virtualY === c.screenGeometry.y)
				return all[i].name
		return ""
	}

	// Флаг «переключение запущено самим виджетом» (прокрутка колесом).
	// Нужен, чтобы при переходе на ПУСТОЙ стол (фокусного окна не будет,
	// память подсветки сама не обновится) записать переход по факту смены
	// currentDesktop — но только для своих переключений, чтобы не
	// приписывать панели чужие смены столов на других мониторах.
	property bool selfSwitch: false
	Timer {
		id: selfSwitchTimer
		interval: 1000
		onTriggered: root.selfSwitch = false
	}
	function markSelfSwitch() {
		selfSwitch = true
		selfSwitchTimer.restart()
	}

	// Переход на ПУСТОЙ стол любым способом (комбинация клавиш, жест):
	// фокусного окна после переключения нет, память подсветки сама не
	// обновится. Если чуть позже смены стола активного окна нигде нет —
	// считаем, что переключился экран этой панели.
	Timer {
		id: emptySwitchTimer
		interval: 250
		onTriggered: {
			if (!root.anyWindowActive && root.perOutputEnabled
					&& root.panelScreenName.length > 0)
				root.recordActive(root.panelScreenName, pagerModel.currentDesktop)
		}
	}

	Connections {
		target: pagerModel
		function onCurrentDesktopChanged() {
			if (root.selfSwitch && root.perOutputEnabled
					&& root.panelScreenName.length > 0)
				root.recordActive(root.panelScreenName, pagerModel.currentDesktop)
			emptySwitchTimer.restart()
		}
	}

	// ---- читаем настройку KWin PerOutputVirtualDesktops из kwinrc ----
	Plasma5Support.DataSource {
		id: kwinCfgReader
		engine: "executable"
		connectedSources: []
		onNewData: (source, data) => {
			var out = ((data["stdout"] || "")).trim().toLowerCase()
			root.perOutputEnabled = (out === "true")
			disconnectSource(source)
		}
		function read() {
			connectSource('grep -i "^PerOutputVirtualDesktops" "${XDG_CONFIG_HOME:-$HOME/.config}/kwinrc" 2>/dev/null | tail -1 | cut -d= -f2')
		}
	}

	// перечитываем настройку, чтобы подхватить переключение галочки без перезапуска
	Timer {
		interval: 3000; running: true; repeat: true
		onTriggered: kwinCfgReader.read()
	}

	function action_addDesktop() {
		let desktopCount = pagerModel.numberOfDesktops
		DBus.SessionBus.asyncCall({
			"service": "org.kde.kglobalaccel",
			"path": "/VirtualDesktopManager",
			"iface": "org.kde.KWin.VirtualDesktopManager",
			"member": "createDesktop",
			"arguments": [
				// if there are 3 desktops, create the new one at the end with name "Desktop 4"
				new DBus.uint32(desktopCount),
				new DBus.string("New Desktop")
			],
		})
	}

	function action_removeDesktop() {
		// TODO pretty sure this has always worked by removing the last desktop, but we probably should make the
		// context menu aware of which one was clicked (at least in full representation) and remove that one?
		let lastDesktopId = pagerModel.desktopIds[pagerModel.numberOfDesktops - 1]
		DBus.SessionBus.asyncCall({
			"service": "org.kde.kglobalaccel",
			"path": "/VirtualDesktopManager",
			"iface": "org.kde.KWin.VirtualDesktopManager",
			"member": "removeDesktop",
			"arguments": [
				// This might not work under X11, as desktop IDs are unit there
				new DBus.string(lastDesktopId)
			],
		})
	}

	function runOverview() {
		DBus.SessionBus.asyncCall({
			"service": "org.kde.kglobalaccel",
			"path": "/component/kwin",
			"iface": "org.kde.kglobalaccel.Component",
			"member": "invokeShortcut",
			"arguments": [
				new DBus.string("Overview")
			],
		})
	}

	function showDesktop() {
		// using the shortcut rather than the method of kwin itself as this has no argument and
		// always toggles the effect
		DBus.SessionBus.asyncCall({
			"service": "org.kde.kglobalaccel",
			"path": "/component/kwin",
			"iface": "org.kde.kglobalaccel.Component",
			"member": "invokeShortcut",
			"arguments": [
				new DBus.string("Show Desktop")
			],
		})
	}

	// index is 1-based, like in the DBus method
	function setCurrentDesktop(index) {
		DBus.SessionBus.asyncCall({
			"service": "org.kde.KWin",
			"path": "/KWin",
			"iface": "org.kde.KWin",
			"member": "setCurrentDesktop",
			"arguments": [
				new DBus.int32(index)
			],
		})
	}

	function nextDesktop() {
		DBus.SessionBus.asyncCall({
			"service": "org.kde.kglobalaccel",
			"path": "/KWin",
			"iface": "org.kde.KWin",
			"member": "nextDesktop",
		})
	}

	function previousDesktop() {
		DBus.SessionBus.asyncCall({
			"service": "org.kde.kglobalaccel",
			"path": "/KWin",
			"iface": "org.kde.KWin",
			"member": "previousDesktop",
		})
	}

	function switchDesktop(wheel) {
		markSelfSwitch()
		// Magic number 120 for common "one click, see:
		// https://doc.qt.io/qt-5/qml-qtquick-wheelevent.html#angleDelta-prop
		wheelDelta += wheel.angleDelta.y || wheel.angleDelta.x;

		var increment = 0;

		while (wheelDelta >= 120) {
			wheelDelta -= 120;
			increment++;
		}

		while (wheelDelta <= -120) {
			wheelDelta += 120;
			increment--;
		}

		if (plasmoid.configuration.invertScrollDirection) {
			increment = -increment;
		}

		let isOnFirstDesktop = pagerModel.currentDesktop === pagerModel.desktopIds[0]
		let isOnLastDesktop = pagerModel.currentDesktop === pagerModel.desktopIds[pagerModel.numberOfDesktops - 1]

		while (increment !== 0) {
			if (increment < 0) {
				if (plasmoid.configuration.wrapPage || !isOnLastDesktop) {
					nextDesktop()
				}
			} else {
				if (plasmoid.configuration.wrapPage || !isOnFirstDesktop) {
					previousDesktop()
				}
			}

			increment += (increment < 0) ? 1 : -1;
		}
	}

	MouseArea {
		id: rootMouseArea
		anchors.fill: parent

		onWheel: wheel => {
			if (plasmoid.configuration.enableScrolling)
				switchDesktop(wheel)
		}
	}

	preferredRepresentation: compactRepresentation
	compactRepresentation: ReprLayout {
		isFullRep: false
	}
	fullRepresentation: ReprLayout {
		isFullRep: true
	}

	VirtualDesktopInfo {
		id: pagerModel
	}

	ActivityInfo {
		id: activityModel
	}

	TasksModel {
		id: mainTasksModel
		filterByVirtualDesktop: false
		groupMode: TasksModel.GroupDisabled
	}

	// Перенос окна на другой стол по его winId (drag&drop). Ищем окно в общей
	// модели задач в момент drop — см. libtaskmanager/abstracttasksmodel.h,
	// роль WinIdList (262) недоступна из QML по имени.
	function moveWindowToDesktop(windowId, desktopId) {
		const WIN_ID_LIST_ROLE = 262
		for (let i = 0; i < mainTasksModel.count; i++) {
			const modelIdx = mainTasksModel.index(i, 0)
			const winIds = modelIdx.data(WIN_ID_LIST_ROLE)
			if (winIds && winIds.length > 0 && String(winIds[0]) === String(windowId)) {
				mainTasksModel.requestVirtualDesktops(modelIdx, [desktopId])
				return
			}
		}
		console.warn("Icon Pager: window not found for DnD move, winId:", windowId)
	}

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Add Virtual Desktop")
            icon.name: "list-add"
            visible: KConfig.KAuthorized.authorize("kcm_kwin_virtualdesktops")
            onTriggered: action_addDesktop()
        },
        PlasmaCore.Action {
            text: i18n("Remove Virtual Desktop")
            icon.name: "list-remove"
            visible: KConfig.KAuthorized.authorize("kcm_kwin_virtualdesktops")
			enabled: Qt.binding(function() {
				return pagerModel.numberOfDesktops > 1;
			});
            onTriggered: action_removeDesktop()
        },
        PlasmaCore.Action {
            text: i18n("Configure Virtual Desktops…")
            visible: KConfig.KAuthorized.authorize("kcm_kwin_virtualdesktops")
            onTriggered: KCM.KCMLauncher.openSystemSettings("kcm_kwin_virtualdesktops")
        }
    ]
}
