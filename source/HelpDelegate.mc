import Toybox.WatchUi;
import Toybox.System;
import Toybox.Lang;

class HelpDelegate extends WatchUi.BehaviorDelegate {
    
    private var _view as HelpView;
    
    function initialize(view as HelpView) {
        BehaviorDelegate.initialize();
        _view = view;
    }
    
    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
    
    // Scroll Buttons
    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_DOWN) {
            _view.scrollDown();
            return true;
        } else if (key == WatchUi.KEY_UP) {
            _view.scrollUp();
            return true;
        } else if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
            _view.scrollDown();
            return true;
        }
        return false;
    }
    
    // Touch Scroll
    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
        var direction = swipeEvent.getDirection();
        if (direction == WatchUi.SWIPE_UP) {
            _view.scrollDown(); 
            return true;
        } else if (direction == WatchUi.SWIPE_DOWN) {
            _view.scrollUp();
            return true;
        }
        return false;
    }
    
    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var coords = clickEvent.getCoordinates();
        var y = coords[1];
        var settings = System.getDeviceSettings();
        var height = settings.screenHeight;
        
        if (y > height / 2) {
             _view.scrollDown();
        } else {
             _view.scrollUp();
        }
        return true;
    }
}
