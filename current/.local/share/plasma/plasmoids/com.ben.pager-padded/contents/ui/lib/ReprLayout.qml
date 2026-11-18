/*
 * Copyright 2021-2024  Tino Lorenz <tilrnz@gmx.net>
 * Copyright 2022  Diego Miguel <hello@diegomiguel.me>
 * Per-screen virtual-desktop split (Plasma 6.7+):
 *   one cell per (screen, desktop); cells grouped by desktop and separated
 *   by a vertical separator. Window icon buckets are filtered per physical
 *   screen via TasksModel.filterByScreen + screenGeometry.
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
 */

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.taskmanager
import org.kde.draganddrop as DnD


RowLayout {
	id: reprLayout
	property bool isFullRep: true

	spacing: Kirigami.Units.smallSpacing

	// ----- colours (unchanged from upstream) -----
	// Фон: если включён custom -> цвет из настроек (при выборе в диалоге читается
	// корректно), иначе — выразительный фолбэк, зашитый здесь.
	property color bgColorHighlight: plasmoid.configuration.activeBgColorChecked
		? plasmoid.configuration.activeBgColor
		: Qt.rgba(60/255, 140/255, 245/255, 120/255)   // насыщенный синий

	property color fontColor: plasmoid.configuration.fontColorChecked ?
			plasmoid.configuration.fontColor : Kirigami.Theme.textColor

	property color bgColor: plasmoid.configuration.inactiveBgColorChecked
		? plasmoid.configuration.inactiveBgColor
		: Qt.rgba(255/255, 255/255, 255/255, 85/255)
	property color bgColorWithoutWindows: plasmoid.configuration.inactiveBgColorWithoutWindowsChecked
		? plasmoid.configuration.inactiveBgColorWithoutWindows
		: Qt.rgba(255/255, 255/255, 255/255, 85/255)
	// рамка полностью прозрачная (формат цвета для рамки в конфиге ненадёжен)
	property color borderColorHighlight: Qt.rgba(255/255, 255/255, 255/255, 0)
	property color borderColor: Qt.rgba(255/255, 255/255, 255/255, 0)

	// ----- screens -----
	// Если в KWin включён режим независимых столов -> реальные экраны (по одному
	// блоку на монитор). Если выключен -> один псевдо-экран (null): единый набор
	// столов с окнами со всех мониторов вместе, без фильтра по экрану.
	readonly property var screensList: !root.perOutputEnabled
		? [null]
		: ((root.screens && root.screens.length > 0)
			? root.screens
			: [Qt.application.primaryScreen])
	readonly property int screenCount: screensList.length

	// Текущий ли это стол для данного экрана. Виджет сам не может спросить KWin
	// про каждый монитор, поэтому: 1) память виджета — последний наблюдённый
	// стол этого монитора (сохраняется и для нефокусного монитора, поэтому
	// подсветка горит на всех экранах разом); 2) если монитор ещё не наблюдался —
	// ячейка с фокусом, иначе глобальный текущий стол.
	// `screenObj` — Qt Screen; `desktopId` — id из VirtualDesktopInfo.
	// mime-данные приходят из Qt6 как ArrayBuffer — собираем строку побайтно
	function mimeText(md, format) {
		var u = new Uint8Array(md.getDataAsByteArray(format))
		var s = ""
		for (var i = 0; i < u.length; i++)
			s += String.fromCharCode(u[i])
		return s.replace(/\0+$/, "")
	}

	function isActiveCell(screenObj, desktopId, cellHasActiveWindow) {
		if (!screenObj)
			return pagerModel.currentDesktop === desktopId
		var m = root.perScreenDesktop
		if (m && m[screenObj.name] !== undefined)
			return m[screenObj.name] === desktopId
		if (root.anyWindowActive)
			return cellHasActiveWindow
		return pagerModel.currentDesktop === desktopId
	}

	// Screen groups, left → right. One delegate per physical screen; each delegate
	// is [ row of per-desktop cells ] [ vertical separator (except last) ].
	Repeater {
		id: screenRep
		model: reprLayout.screenCount

		RowLayout {
			id: screenGroup
			required property int index            // screen index, 0-based
			readonly property var screenObj: reprLayout.screensList[index]
			// расстояние между рабочими столами (настраивается)
			spacing: plasmoid.configuration.desktopSpacing

			// one cell per virtual desktop for this screen
			Repeater {
				model: pagerModel.numberOfDesktops

				NumberBox {
					id: nBox
					required property int index        // desktop index, 0-based
					readonly property var screenObj: screenGroup.screenObj
					readonly property var desktopId: pagerModel.desktopIds[index]
					// активное окно в модели именно этой ячейки -> мы сейчас здесь
					readonly property bool hasActiveWindow:
						tasksModel.activeTask !== undefined && tasksModel.activeTask.row >= 0
					// как только в ячейке появился фокус — запоминаем, что этот
					// монитор сейчас на этом столе (память переживает уход фокуса)
					onHasActiveWindowChanged: if (hasActiveWindow)
						root.recordActive(screenObj ? screenObj.name : "", desktopId)
					Component.onCompleted: if (hasActiveWindow)
						root.recordActive(screenObj ? screenObj.name : "", desktopId)
					readonly property bool isActive:
						reprLayout.isActiveCell(screenObj, desktopId, hasActiveWindow)

					// number = desktop number for this cell
					text: plasmoid.configuration.showDesktopNames
						? pagerModel.desktopNames[nBox.index]
						: nBox.index + 1

					Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
					Layout.topMargin: 3
					Layout.bottomMargin: 3
					Layout.fillHeight: true

					// hide a cell only if it is empty AND not the active one AND the
					// user opted to hide empty desktops; the active cell is always shown.
					visible: isActive
						|| tasksModel.count > 0
						|| !plasmoid.configuration.hideDesktopsWithoutWindows

					// Windows strictly on THIS desktop AND THIS physical screen.
					TasksModel {
						id: tasksModel
						filterByVirtualDesktop: true
						virtualDesktop: nBox.desktopId
						groupMode: TasksModel.GroupDisabled
						// в объединённом режиме (screenObj == null) не фильтруем по
						// экрану — показываем окна со всех мониторов на этом столе
						filterByScreen: nBox.screenObj !== null && nBox.screenObj !== undefined
						screenGeometry: (nBox.screenObj !== null && nBox.screenObj !== undefined)
							? Qt.rect(nBox.screenObj.virtualX, nBox.screenObj.virtualY,
								nBox.screenObj.width, nBox.screenObj.height)
							: Qt.rect(0, 0, 0, 0)
						filterByActivity: true
						activity: activityModel.currentActivity
					}

					showWindowIndicator: plasmoid.configuration.showWindowIndicator && tasksModel.count > 0
					appTasksModel: tasksModel
					desktopIds: pagerModel.desktopIds
					desktopNames: pagerModel.desktopNames

					// иконку начали тащить -> запоминаем её окно; закончили
					// (drop или отмена) -> забываем
					onWindowDragStarted: (winId) => { root.draggedWinId = winId }
					onWindowDragEnded: { root.draggedWinId = "" }

					DnD.DropArea {
						enabled: plasmoid.configuration.enableDnD
						anchors.fill: parent
						preventStealing: true
						onDrop: event => {
							// перетаскивание иконки внутри пейджера
							if (root.draggedWinId && root.draggedWinId.length > 0) {
								moveWindowToDesktop(root.draggedWinId, nBox.desktopId)
								root.draggedWinId = ""
								return
							}
							// внешние перетаскивания окон — например, из панели
							// задач (windowsystem/winid, windowsystem/multiple-winids)
							let md = event.mimeData
							for (let format of md.formats) {
								if (format === "windowsystem/winid"
										|| format.startsWith("windowsystem/winid+{")) {
									moveWindowToDesktop(
										reprLayout.mimeText(md, format), nBox.desktopId)
									return
								}
								if (format === "windowsystem/multiple-winids") {
									var ids = reprLayout.mimeText(md, format)
										.split(/[\s,;\0]+/).filter(x => x.length > 0)
									for (var w = 0; w < ids.length; w++)
										moveWindowToDesktop(ids[w], nBox.desktopId)
									return
								}
							}
						}
					}

					color: isActive ? bgColorHighlight
						: ((tasksModel.count > 0) ? bgColor : bgColorWithoutWindows)
					border.color: isActive ? borderColorHighlight : borderColor

					MouseArea {
						anchors.fill: parent
						onClicked: {
							if (nBox.isActive) {
								switch (plasmoid.configuration.currentDesktopSelected) {
									case 1: showDesktop(); break;
									case 2: runOverview(); break;
								}
								root.expanded = false
							} else {
								// переключаем стол напрямую (мост не используется —
								// подсветка ведётся памятью виджета)
								setCurrentDesktop(nBox.index + 1)
								// на пустом столе фокусного окна не появится и память
								// сама не обновится — записываем переход явно
								root.recordActive(nBox.screenObj ? nBox.screenObj.name : "",
									nBox.desktopId)
								root.expanded = false
							}
						}
					}
				}
			}

			// vertical separator between screen groups
			Kirigami.Separator {
				visible: screenGroup.index < reprLayout.screenCount - 1
				Layout.fillHeight: true
				Layout.preferredHeight: Kirigami.Units.iconSizes.small
				Layout.leftMargin: Kirigami.Units.smallSpacing
				Layout.rightMargin: Kirigami.Units.smallSpacing
			}
		}
	}
}
