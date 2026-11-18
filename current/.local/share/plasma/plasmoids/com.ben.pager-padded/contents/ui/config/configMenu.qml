import QtQuick
import QtQuick.Controls as QtControls
import QtQuick.Layouts as QtLayouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: root

    property alias cfg_menuShowJumpList: jumpListCheck.checked
    property alias cfg_menuShowMoveToDesktop: moveDesktopCheck.checked
    property alias cfg_menuShowMore: moreCheck.checked
    property alias cfg_menuShowActivate: activateCheck.checked
    property alias cfg_menuShowNewInstance: newInstanceCheck.checked
    property alias cfg_menuShowClose: closeCheck.checked

    QtLayouts.ColumnLayout {
        width: parent.width
        spacing: Kirigami.Units.largeSpacing

        Kirigami.Heading {
            level: 3
            text: i18n("Show items in the right-click menu")
        }
        QtControls.CheckBox { id: jumpListCheck;    text: i18n("Application actions (jump list)") }
        QtControls.CheckBox { id: activateCheck;    text: i18n("Activate") }
        QtControls.CheckBox { id: moveDesktopCheck; text: i18n("Move to Desktop") }
        QtControls.CheckBox { id: moreCheck;        text: i18n("More (window actions)") }
        QtControls.CheckBox { id: newInstanceCheck; text: i18n("Start New Instance") }
        QtControls.CheckBox { id: closeCheck;       text: i18n("Close") }
    }
}
