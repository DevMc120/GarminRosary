import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

class MeditationDelegate extends WatchUi.BehaviorDelegate {

    private var _view as MeditationView or MeditationViewStatic;
    private var _lastDragY as Number = 0;

    function initialize(view as MeditationView or MeditationViewStatic) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    function onDrag(dragEvent as WatchUi.DragEvent) as Boolean {
        var type = dragEvent.getType();
        var y = dragEvent.getCoordinates()[1];
        
        if (type == WatchUi.DRAG_TYPE_START) {
            _lastDragY = y;
            return true;
        } else if (type == WatchUi.DRAG_TYPE_CONTINUE) {
            var delta = y - _lastDragY;
            
            if (delta < -30) { 
                if (_view.scrollDown()) {
                    _lastDragY = y;
                }
                return true;
            } else if (delta > 30) { 
                if (_view.scrollUp()) {
                    _lastDragY = y;
                }
                return true;
            }
        }
        return false;
    }

    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
        var direction = swipeEvent.getDirection();
        
        if (direction == WatchUi.SWIPE_DOWN) {
            _view.scrollUp();
            return true;
        } else if (direction == WatchUi.SWIPE_UP) {
            _view.scrollDown();
            return true;
        } else if (direction == WatchUi.SWIPE_RIGHT) {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            return true;
        }
        
        return false;
    }



    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        
        if (key == WatchUi.KEY_DOWN) {
            _view.scrollDown();
            return true;
        } else if (key == WatchUi.KEY_UP) {
            _view.scrollUp();
            return true;
        } else if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            return true;
        }
        
        return false; 
    }

    function onNextPage() as Boolean {
        _view.scrollDown();
        return true;
    }

    function onPreviousPage() as Boolean {
        _view.scrollUp();
        return true;
    }

    function onMenu() as Boolean {
        if (_view has :getModel) {
            var model = (_view as MeditationView).getModel();

            var settings = System.getDeviceSettings();
            var screenWidth = settings.screenWidth;
            var screenHeight = settings.screenHeight;
            var isRectangular = (screenHeight > screenWidth * 1.1);
            var useShortStrings = (screenWidth < 220) || isRectangular; 
            
            var title = useShortStrings ? null : WatchUi.loadResource(Rez.Strings.AppName) as String;
            var menu = new WatchUi.Menu2({:title=>title});
            
            menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.menu_restart) as String, null, "restart", null));
            menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(useShortStrings ? Rez.Strings.MysteryAuto_short : Rez.Strings.MysteryAuto) as String, null, "mystery_auto", null));
            menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(useShortStrings ? Rez.Strings.menu_rosary_short : Rez.Strings.menu_rosary) as String, null, "start_rosary", null));
            
            menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(useShortStrings ? Rez.Strings.menu_joyful_short : Rez.Strings.menu_joyful) as String, null, "mystery_joyful", null));
            menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(useShortStrings ? Rez.Strings.menu_sorrowful_short : Rez.Strings.menu_sorrowful) as String, null, "mystery_sorrowful", null));
            menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(useShortStrings ? Rez.Strings.menu_glorious_short : Rez.Strings.menu_glorious) as String, null, "mystery_glorious", null));
            menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(useShortStrings ? Rez.Strings.menu_luminous_short : Rez.Strings.menu_luminous) as String, null, "mystery_luminous", null));
            
            menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(useShortStrings ? Rez.Strings.menu_meditation_short : Rez.Strings.menu_meditation) as String, null, "meditations", null));
            
            var autoMedLabel = WatchUi.loadResource(Rez.Strings.menu_auto_meditation) as String;
            var autoMedEnabled = model.isAutoMeditationEnabled();
            menu.addItem(new WatchUi.ToggleMenuItem(autoMedLabel, null, "toggle_auto_meditation", autoMedEnabled, null));
            
            WatchUi.pushView(menu, new GarminRosaryMenuDelegate(model), WatchUi.SLIDE_UP);
            return true;
        }
        return false;
    }
}
