import QtQuick
import "../services"

// Encapsulates the keyboard dispatch logic for the launcher search field.
// Instantiate this alongside the search field and forward Keys.onPressed
// events to handleKeyPress(event).
QtObject {
    required property var launcher

    function handleKeyPress(event) {
        if (event.key === Qt.Key_Escape) {
            if (launcher.handleEscapeAction())
                event.accepted = true;
        } else if ((event.modifiers & Qt.ControlModifier) && !(event.modifiers & Qt.AltModifier) && (event.key === Qt.Key_L || event.key === Qt.Key_U)) {
            launcher.clearSearchQuery();
            event.accepted = true;
        } else if (Config.launcherWebNumberHotkeysEnabled && launcher.mode === "web" && (event.modifiers & Qt.ControlModifier) && !(event.modifiers & Qt.AltModifier) && !(event.modifiers & Qt.ShiftModifier)) {
            var openSlot = launcher.webProviderSlotFromKey(event.key);
            if (openSlot > 0 && launcher.executeWebProviderBySlot(openSlot))
                event.accepted = true;
        } else if (Config.launcherWebNumberHotkeysEnabled && launcher.mode === "web" && (event.modifiers & Qt.AltModifier) && !(event.modifiers & Qt.ControlModifier)) {
            var slot = launcher.webProviderSlotFromKey(event.key);
            if (slot > 0 && launcher.selectWebProviderBySlot(slot))
                event.accepted = true;
        } else if (launcher.drunCategoryFiltersEnabled && launcher.mode === "drun" && (event.modifiers & Qt.AltModifier) && !(event.modifiers & Qt.ControlModifier)) {
            if (event.key === Qt.Key_Left) {
                if (launcher.cycleDrunCategoryFilter(-1))
                    event.accepted = true;
            } else if (event.key === Qt.Key_Right) {
                if (launcher.cycleDrunCategoryFilter(1))
                    event.accepted = true;
            } else if (event.key === Qt.Key_PageUp) {
                if (launcher.cycleDrunCategoryFilter(-1))
                    event.accepted = true;
            } else if (event.key === Qt.Key_PageDown) {
                if (launcher.cycleDrunCategoryFilter(1))
                    event.accepted = true;
            } else if (event.key === Qt.Key_Home) {
                if (launcher.jumpDrunCategoryBoundary(false))
                    event.accepted = true;
            } else if (event.key === Qt.Key_End) {
                if (launcher.jumpDrunCategoryBoundary(true))
                    event.accepted = true;
            } else if (event.key === Qt.Key_0 || event.key === Qt.Key_Backspace) {
                if (launcher.setDrunCategoryFilter(""))
                    event.accepted = true;
            } else {
                var categorySlot = launcher.webProviderSlotFromKey(event.key);
                if (categorySlot > 0 && launcher.selectDrunCategorySlot(categorySlot))
                    event.accepted = true;
            }
        } else if (launcher.drunCategoryFiltersEnabled && launcher.mode === "drun" && launcher.showLauncherHome && (event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_Tab) {
            var direction = (event.modifiers & Qt.ShiftModifier) ? -1 : 1;
            if (launcher.cycleDrunCategoryFilter(direction))
                event.accepted = true;
        } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
            launcher.cycleMode(1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Tab) {
            if (launcher.launcherTabBehavior === "mode")
                launcher.cycleMode(1);
            else if (launcher.launcherTabBehavior === "results")
                launcher.cycleSelection(1);
            else if (launcher.filteredItems.length > 0)
                launcher.cycleSelection(1);
            else
                launcher.cycleMode(1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            launcher.handleSearchAccepted(event.modifiers);
        } else if ((event.modifiers & Qt.ControlModifier) && !(event.modifiers & Qt.AltModifier) && event.key === Qt.Key_P) {
            if (launcher.moveSelectionRelative(-1))
                event.accepted = true;
        } else if ((event.modifiers & Qt.ControlModifier) && !(event.modifiers & Qt.AltModifier) && event.key === Qt.Key_N) {
            if (launcher.moveSelectionRelative(1))
                event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            if (launcher.moveSelectionRelative(-1))
                event.accepted = true;
        } else if (event.key === Qt.Key_Down) {
            if (launcher.moveSelectionRelative(1))
                event.accepted = true;
        } else if (event.key === Qt.Key_PageUp) {
            if (launcher.pageSelection(-1))
                event.accepted = true;
        } else if (event.key === Qt.Key_PageDown) {
            if (launcher.pageSelection(1))
                event.accepted = true;
        } else if (event.key === Qt.Key_Home) {
            if (launcher.jumpSelectionBoundary(false))
                event.accepted = true;
        } else if (event.key === Qt.Key_End) {
            if (launcher.jumpSelectionBoundary(true))
                event.accepted = true;
        }
    }
}
