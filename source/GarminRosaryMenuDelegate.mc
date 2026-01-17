import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

//! Gère les actions du menu principal
class GarminRosaryMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _model as RosaryModel;

    function initialize(model as RosaryModel) {
        Menu2InputDelegate.initialize();
        _model = model;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        
        if (id != null) {
            var idStr = id.toString();
            
            if (idStr.equals("restart")) {
                _model.fullReset(); // Reset Intelligent (retour auto)
                _model.clearSavedState();
            } else if (idStr.equals("mystery_auto")) {
                _model.setAutoMystery();
            } else if (idStr.equals("mystery_joyful")) {
                _model.setManualMystery(RosaryModel.MYSTERY_JOYFUL);
            } else if (idStr.equals("mystery_sorrowful")) {
                _model.setManualMystery(RosaryModel.MYSTERY_SORROWFUL);
            } else if (idStr.equals("mystery_glorious")) {
                _model.setManualMystery(RosaryModel.MYSTERY_GLORIOUS);
            } else if (idStr.equals("mystery_luminous")) {
                _model.setManualMystery(RosaryModel.MYSTERY_LUMINOUS);
            }
        }
        
        // Sauvegarder l'état pour que la Vue le recharge correctement
        _model.saveState();
        
        // Fermer le menu et rafraîchir
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.requestUpdate();
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}