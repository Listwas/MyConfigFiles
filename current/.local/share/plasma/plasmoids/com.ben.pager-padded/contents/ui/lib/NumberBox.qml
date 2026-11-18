import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.draganddrop as DnD
import org.kde.kirigami as Kirigami

Rectangle {
    id: numberBox
    property alias text: numberText.text
    property color fontColor: plasmoid.configuration.fontColorChecked
        ? plasmoid.configuration.fontColor
        : Kirigami.Theme.textColor
    property bool showWindowIndicator: true
    property var appTasksModel: null

    // перетаскивание окна на другой стол: сообщаем winId наверх (в ReprLayout)
    signal windowDragStarted(string winId)
    signal windowDragEnded()
    property var desktopIds: []

    property var desktopNames: []

    readonly property bool iconsMode: plasmoid.configuration.showWindowIcons
    readonly property int cfgSpacing:  plasmoid.configuration.iconSpacing
    readonly property int cfgMaxIcons: plasmoid.configuration.maxIcons
    readonly property int iconPadding: 6

    // Сколько иконок показываем
    readonly property int shownCount: {
        if (!appTasksModel) return 0
        var n = appTasksModel.count
        return (cfgMaxIcons > 0) ? Math.min(n, cfgMaxIcons) : n
    }

    // Размер иконки. Если задан явно (>0) — берём его. Иначе АВТО: подгоняем под
    // высоту ячейки (толщину панели), чтобы иконки заполняли место, а не были
    // фиксированно маленькими.
    readonly property int iconSize: {
        var cfg = plasmoid.configuration.iconSize
        if (cfg > 0)
            return Math.max(6, cfg)
        var h = numberBox.height
        return h > 0 ? Math.max(12, Math.round(h) - 2) : 22
    }

    // Реальный размер иконки: не больше высоты ячейки (панели). По нему считаем и
    // ширину слота — иначе при iconSize больше высоты слот растёт (лишний отступ),
    // а иконка упирается в высоту.
    readonly property int effectiveIconSize: numberBox.height > 0
        ? Math.min(numberBox.iconSize, Math.round(numberBox.height))
        : numberBox.iconSize

    // Ширина под иконки. Для пустого рабочего стола (окон нет) держим
    // комфортную минимальную ширину, чтобы по квадрату было удобно кликать
    // для переключения стола.
    readonly property int iconsWidth: shownCount > 0
        ? shownCount * effectiveIconSize + Math.max(0, shownCount - 1) * cfgSpacing + iconPadding
        : Math.max(effectiveIconSize, Math.round(Kirigami.Units.gridUnit * 1.3)) + iconPadding

    // Текстовый референс для не-иконочного режима
    Text {
        id: sizeRefText
        visible: false
        text: numberBox.text
        font {
            family:    plasmoid.configuration.fontFamily || Kirigami.Theme.defaultFont.family
            bold:      plasmoid.configuration.fontBold
            italic:    plasmoid.configuration.fontItalic
            pixelSize: plasmoid.configuration.fontSizeChecked
                ? plasmoid.configuration.fontSize
                : Kirigami.Theme.defaultFont.pixelSize
        }
    }

    border.width: plasmoid.configuration.displayBorder
        ? plasmoid.configuration.borderThickness : 0
    radius: Math.min(width, height) * (plasmoid.configuration.borderRadius / 100)

    // === Layout — точно как в оригинале ===
    // Ширина фиксированная = под иконки (или под текст)
    // Высота fillHeight = растягивается на всю панель
    Layout.minimumWidth:   iconsMode ? iconsWidth         : (sizeRefText.width + 10)
    Layout.preferredWidth: iconsMode ? iconsWidth         : (sizeRefText.width + 10)
    Layout.maximumWidth:   iconsMode ? iconsWidth         : (sizeRefText.width + 10)
    Layout.minimumHeight:  sizeRefText.height
    Layout.preferredHeight: sizeRefText.height
    // fillHeight — блок занимает всю высоту панели, как в референсе
    Layout.fillWidth:  Plasmoid.formFactor !== PlasmaCore.Types.Horizontal
    Layout.fillHeight: Plasmoid.formFactor !== PlasmaCore.Types.Vertical

    // Цифра / имя
    Text {
        id: numberText
        visible: !iconsMode
        anchors.centerIn: parent
        width:  parent.width - 10
        height: parent.height
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment:   Text.AlignVCenter
        color: fontColor
        font {
            family:    plasmoid.configuration.fontFamily || Kirigami.Theme.defaultFont.family
            bold:      plasmoid.configuration.fontBold
            italic:    plasmoid.configuration.fontItalic
            pixelSize: plasmoid.configuration.fontSizeChecked
                ? plasmoid.configuration.fontSize : 999
        }
        fontSizeMode:     plasmoid.configuration.fontSizeChecked ? Text.FixedSize : Text.Fit
        minimumPixelSize: Kirigami.Theme.smallFont.pixelSize
    }

    Rectangle {
        visible: numberBox.showWindowIndicator && !iconsMode
        anchors.left: numberText.right
        anchors.top:  numberText.top
        width: 8; height: 8
        border.color: numberBox.fontColor
        border.width: 1
        color: "transparent"
        radius: width * (plasmoid.configuration.windowIndicatorRadius / 100)
    }

    // Иконки — интерактивный ряд (мини-панель задач):
    //  • клик по иконке активирует окно (а если оно уже активно — сворачивает);
    //  • средняя кнопка — новый экземпляр приложения;
    //  • активное окно подсвечивается, свёрнутое приглушено.
    Row {
        id: iconRow
        visible: iconsMode
        anchors.centerIn: parent
        spacing: numberBox.cfgSpacing
        // поверх MouseArea переключения стола из ReprLayout, чтобы клики по
        // иконкам шли сюда, а клики по пустому месту ячейки — на переключение
        z: 10

        readonly property int iconDim: numberBox.effectiveIconSize

        Repeater {
            // модель целиком: даёт доступ к ролям TasksModel по именам
            model: numberBox.appTasksModel

            delegate: Item {
                id: iconDelegate
                width:  iconRow.iconDim
                height: iconRow.iconDim
                // ограничение количества иконок (maxIcons); скрытые Row пропускает.
                // Прячем задачи-«запуски» (IsStartup): пока окно не размещено на
                // экране/столе, оно попадает в фильтры всех ячеек — отсюда вспышка
                // «открылось на всех экранах». Показываем только уже размещённые окна.
                visible: index < numberBox.shownCount
                    && model.IsStartup !== true
                    && model.IsWindow !== false

                // роли TasksModel (через roleNames()); отсутствующая роль -> undefined
                readonly property bool taskActive:    model.IsActive === true
                readonly property bool taskMinimized: model.IsMinimized === true
                readonly property string winId: {
                    var wl = model.WinIdList
                    return (wl && wl.length > 0) ? String(wl[0]) : ""
                }

                DnD.DragArea {
                    id: iconDrag
                    anchors.fill: parent
                    enabled: plasmoid.configuration.enableDnD && iconDelegate.winId.length > 0
                    defaultAction: Qt.MoveAction
                    supportedActions: Qt.MoveAction
                    delegateImage: model.decoration
                    // ВАЖНО: не задаём mimeData.text/url — иначе промах мимо
                    // ячейки роняет текст на панель/стол, и Plasma создаёт из
                    // него виджет-заметку, а панель дёргается, освобождая место
                    // под drop. Окно передаём через root.draggedWinId.
                    mimeData.source: iconDrag
                    onDragStarted: numberBox.windowDragStarted(iconDelegate.winId)
                    onDrop: numberBox.windowDragEnded()

                    // подсветка активного окна
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -1
                        radius: 3
                        visible: iconDelegate.taskActive
                        color: Qt.rgba(Kirigami.Theme.highlightColor.r,
                                       Kirigami.Theme.highlightColor.g,
                                       Kirigami.Theme.highlightColor.b, 0.25)
                        border.width: 1
                        border.color: Kirigami.Theme.highlightColor
                    }

                    Kirigami.Icon {
                        anchors.fill: parent
                        roundToIconSize: false
                        opacity: iconDelegate.taskMinimized ? 0.5 : 1.0
                        source: model.decoration
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                        onClicked: mouse => {
                            let mi = numberBox.appTasksModel.index(index, 0)
                            if (mouse.button === Qt.RightButton) {
                                ctxMenu.taskRow = index
                                ctxMenu.launcherUrl = (model.LauncherUrlWithoutIcon || "").toString()
                                ctxMenu.jumpActions = []
                                numberBox.fetchJumpActions(ctxMenu.launcherUrl)
                                ctxMenu.popup()
                            } else if (mouse.button === Qt.MiddleButton) {
                                numberBox.appTasksModel.requestNewInstance(mi)
                            } else if (iconDelegate.taskActive) {
                                numberBox.appTasksModel.requestToggleMinimized(mi)
                            } else {
                                numberBox.appTasksModel.requestActivate(mi)
                            }
                        }
                    }
                }
            }
        }
    }

    // Контекстное меню по ПКМ — как в Icons-Only Task Manager
    QQC2.Menu {
        id: ctxMenu
        // отдельное окно + системная тема (Breeze): иначе меню обрезается до
        // пары строк (в высоту окна апплета) и не берёт нативное оформление
        popupType: QQC2.Popup.Window

        property int taskRow: -1
        property string launcherUrl: ""
        property var jumpActions: []
        function targetIndex() { return numberBox.appTasksModel.index(ctxMenu.taskRow, 0) }
        readonly property bool hasTarget: ctxMenu.taskRow >= 0
            && numberBox.appTasksModel
            && ctxMenu.taskRow < numberBox.appTasksModel.count

        // --- джамплист приложения (.desktop Actions) сверху ---
        Instantiator {
            model: ctxMenu.jumpActions
            delegate: QQC2.MenuItem {
                required property var modelData
                text: modelData.name
                icon.name: "window-new"
                visible: plasmoid.configuration.menuShowJumpList
                onTriggered: numberBox.launchJumpAction(ctxMenu.launcherUrl, modelData.id)
            }
            onObjectAdded: (index, object) => ctxMenu.insertItem(index, object)
            onObjectRemoved: (index, object) => ctxMenu.removeItem(object)
        }
        QQC2.MenuSeparator {
            visible: plasmoid.configuration.menuShowJumpList && ctxMenu.jumpActions.length > 0
        }

        QQC2.MenuItem {
            text: i18n("Activate")
            icon.name: "window"
            visible: plasmoid.configuration.menuShowActivate
            enabled: ctxMenu.hasTarget
            onTriggered: numberBox.appTasksModel.requestActivate(ctxMenu.targetIndex())
        }

        // --- Move to Desktop ---
        QQC2.Menu {
            id: desktopMenu
            title: i18n("Move to Desktop")
            popupType: QQC2.Popup.Window
            visible: plasmoid.configuration.menuShowMoveToDesktop

            QQC2.MenuItem {
                text: i18n("All Desktops")
                enabled: ctxMenu.hasTarget
                onTriggered: numberBox.appTasksModel.requestVirtualDesktops(ctxMenu.targetIndex(), [])
            }
            QQC2.MenuSeparator {}
            Instantiator {
                model: numberBox.desktopIds
                delegate: QQC2.MenuItem {
                    required property int index
                    required property var modelData
                    text: (numberBox.desktopNames && numberBox.desktopNames[index])
                        ? numberBox.desktopNames[index]
                        : i18n("Desktop %1", index + 1)
                    enabled: ctxMenu.hasTarget
                    onTriggered: numberBox.appTasksModel.requestVirtualDesktops(
                        ctxMenu.targetIndex(), [modelData])
                }
                onObjectAdded: (index, object) => desktopMenu.insertItem(index + 2, object)
                onObjectRemoved: (index, object) => desktopMenu.removeItem(object)
            }
        }

        // --- More (оконные действия) ---
        QQC2.Menu {
            id: moreMenu
            title: i18n("More")
            icon.name: "application-menu"
            popupType: QQC2.Popup.Window
            visible: plasmoid.configuration.menuShowMore

            QQC2.MenuItem {
                text: i18n("Move")
                icon.name: "transform-move"
                enabled: ctxMenu.hasTarget
                onTriggered: numberBox.appTasksModel.requestMove(ctxMenu.targetIndex())
            }
            QQC2.MenuItem {
                text: i18n("Resize")
                icon.name: "transform-scale"
                enabled: ctxMenu.hasTarget
                onTriggered: numberBox.appTasksModel.requestResize(ctxMenu.targetIndex())
            }
            QQC2.MenuItem {
                text: i18n("Maximize")
                icon.name: "window-maximize"
                enabled: ctxMenu.hasTarget
                onTriggered: numberBox.appTasksModel.requestToggleMaximized(ctxMenu.targetIndex())
            }
            QQC2.MenuItem {
                text: i18n("Minimize")
                icon.name: "window-minimize"
                enabled: ctxMenu.hasTarget
                onTriggered: numberBox.appTasksModel.requestToggleMinimized(ctxMenu.targetIndex())
            }
            QQC2.MenuItem {
                text: i18n("Keep Above Others")
                icon.name: "window-keep-above"
                enabled: ctxMenu.hasTarget
                onTriggered: numberBox.appTasksModel.requestToggleKeepAbove(ctxMenu.targetIndex())
            }
            QQC2.MenuItem {
                text: i18n("Keep Below Others")
                icon.name: "window-keep-below"
                enabled: ctxMenu.hasTarget
                onTriggered: numberBox.appTasksModel.requestToggleKeepBelow(ctxMenu.targetIndex())
            }
            QQC2.MenuItem {
                text: i18n("Fullscreen")
                icon.name: "view-fullscreen"
                enabled: ctxMenu.hasTarget
                onTriggered: numberBox.appTasksModel.requestToggleFullScreen(ctxMenu.targetIndex())
            }
            QQC2.MenuItem {
                text: i18n("Shade")
                icon.name: "window-shade"
                enabled: ctxMenu.hasTarget
                onTriggered: numberBox.appTasksModel.requestToggleShaded(ctxMenu.targetIndex())
            }
        }

        QQC2.MenuItem {
            text: i18n("Start New Instance")
            icon.name: "list-add"
            visible: plasmoid.configuration.menuShowNewInstance
            enabled: ctxMenu.hasTarget
            onTriggered: numberBox.appTasksModel.requestNewInstance(ctxMenu.targetIndex())
        }
        QQC2.MenuSeparator { visible: plasmoid.configuration.menuShowClose }
        QQC2.MenuItem {
            text: i18n("Close")
            icon.name: "window-close"
            visible: plasmoid.configuration.menuShowClose
            enabled: ctxMenu.hasTarget
            onTriggered: numberBox.appTasksModel.requestClose(ctxMenu.targetIndex())
        }
    }

    // путь к helper-скрипту внутри пакета
    readonly property string jumpScript:
        Qt.resolvedUrl("../../code/jumplist.sh").toString().replace(/^file:\/\//, "")

    function shellQuote(s) {
        return "'" + String(s).replace(/'/g, "'\\''") + "'"
    }

    // file:///path%20with%20spaces -> file:///path with spaces, иначе скрипт
    // не найдёт .desktop-файл по закодированному пути
    function decodeLauncher(u) {
        var s = String(u)
        try { return decodeURIComponent(s) } catch (e) { return s }
    }

    // запросить действия .desktop для приложения окна
    function fetchJumpActions(launcherUrl) {
        if (!launcherUrl || launcherUrl.length === 0)
            return
        jumpLister.connectSource("bash " + numberBox.shellQuote(numberBox.jumpScript)
            + " list " + numberBox.shellQuote(numberBox.decodeLauncher(launcherUrl)))
    }

    function launchJumpAction(launcherUrl, actionId) {
        if (!launcherUrl || !actionId)
            return
        jumpLauncher.connectSource("bash " + numberBox.shellQuote(numberBox.jumpScript)
            + " launch " + numberBox.shellQuote(numberBox.decodeLauncher(launcherUrl))
            + " " + numberBox.shellQuote(actionId))
    }

    // читает список действий и наполняет меню
    P5Support.DataSource {
        id: jumpLister
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            var out = (data["stdout"] || "").trim()
            var list = []
            if (out.length > 0) {
                var lines = out.split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split("\t")
                    if (parts.length >= 2 && parts[0].length > 0)
                        list.push({ id: parts[0], name: parts[1] })
                }
            }
            ctxMenu.jumpActions = list
            disconnectSource(source)
        }
    }

    // запускает выбранное действие (вывод не нужен)
    P5Support.DataSource {
        id: jumpLauncher
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => disconnectSource(source)
    }
}
