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
                _model.reset();
                _model.clearSavedState();
            } else if (idStr.equals("help")) {
                var view = new HelpView();
                var delegate = new HelpDelegate(view);
                WatchUi.pushView(view, delegate, WatchUi.SLIDE_LEFT);
                return;
            } else if (idStr.equals("meditations")) {
                var menu = new WatchUi.Menu2({:title => WatchUi.loadResource(Rez.Strings.menu_meditation) as String});
                menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.mystery_joyful) as String, null, "cat_joyful", null));
                menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.mystery_luminous) as String, null, "cat_luminous", null));
                menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.mystery_sorrowful) as String, null, "cat_sorrowful", null));
                menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.mystery_glorious) as String, null, "cat_glorious", null));
                WatchUi.pushView(menu, new MeditationMenuDelegate(_model), WatchUi.SLIDE_LEFT);
                return;
            } else if (idStr.equals("start_rosary")) {
                _model.startFullRosary();
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
            } else if (idStr.equals("toggle_auto_meditation")) {
                var currentValue = _model.isAutoMeditationEnabled();
                _model.setAutoMeditation(!currentValue);
                return;
            }
        }
        
        _model.saveState();
        
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.requestUpdate();
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}