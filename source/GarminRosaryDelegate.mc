import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Attention;
import Toybox.System;

//! Gère les entrées utilisateur et les vibrations
class GarminRosaryDelegate extends WatchUi.BehaviorDelegate {

    private var _model as RosaryModel;
    private var _view as GarminRosaryView;
    
    private var _selectPressTime as Number = 0;
    private var _isKeyPressed as Boolean = false; 
    private const LONG_PRESS_THRESHOLD = 1000; 

    function initialize(model as RosaryModel, view as GarminRosaryView) {
        BehaviorDelegate.initialize();
        _model = model;
        _view = view;
    }



    //! Détection de l'appui sur un bouton (pour Long Press)
    function onKeyPressed(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        
        if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
            _selectPressTime = System.getTimer();
            _isKeyPressed = true; 
            return true; 
        }
        
        return false;
    }

    //! Détection du relâchement d'un bouton (pour différencier court/long)
    function onKeyReleased(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        
        if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
            if (!_isKeyPressed) {
                return false;
            }
            _isKeyPressed = false; 

            var pressDuration = System.getTimer() - _selectPressTime;
            
            if (pressDuration >= LONG_PRESS_THRESHOLD) {
                openMeditationView();
            } else {
                advanceBead();
            }
            return true;
        }
        
        return false;
    }

    //! Tap sur l'écran tactile - Avance d'un grain
    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        advanceBead();
        return true;
    }

    //! Bouton Haut - Avance d'un grain
    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        
        if (key == WatchUi.KEY_UP) {
            advanceBead();
            return true;
        } else if (key == WatchUi.KEY_DOWN) {
            goBack();
            return true;
        }
        
        return false;
    }

    //! Swipe - Navigation verticale
    //! TAP = avancer (principal), SWIPE_UP = méditation, SWIPE_DOWN = reculer
    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
        var direction = swipeEvent.getDirection();
        
        if (direction == WatchUi.SWIPE_UP) {
            openMeditationView();
            return true;
        } else if (direction == WatchUi.SWIPE_DOWN) {
            goBack();
            return true;
        }
        
        return false;
    }

    //! Ouvre la vue de méditation
    private function openMeditationView() as Void {
        if (_model.phase < 1 || _model.phase > 5) {
            return;
        }

        var meditationView = new MeditationView(_model);
        var meditationDelegate = new MeditationDelegate(meditationView);
        WatchUi.pushView(meditationView, meditationDelegate, WatchUi.SLIDE_LEFT);
    }

    //! Avance d'un grain avec vibration appropriée
    private function advanceBead() as Void {
        var previousPhase = _model.phase;
        
        var state = _model.next();
        
        _view.setCurrentState(state);
        
        triggerVibration(state);
        
        _model.saveState();
        
        if (_model.isAutoMeditationEnabled()) {
            var currentPhase = _model.phase;
            if (currentPhase >= 1 && currentPhase <= 5 && _model.beadInPhase == 1 && 
                previousPhase != currentPhase) {
                openMeditationView();
            }
        }
        
        WatchUi.requestUpdate();
    }

    //! Recule d'un grain
    private function goBack() as Void {
        _model.previous();
        
        var state = _model.getCurrentState();
        _view.setCurrentState(state);
        
        _model.saveState();
        WatchUi.requestUpdate();
    }

    private function triggerVibration(state as Number) as Void {
        if (!(Attention has :vibrate)) {
            return;
        }

        var vibeData = null;

        switch (state) {
            // Vibration courte pour les grains normaux
            case RosaryModel.STATE_HAIL_MARY:
            case RosaryModel.STATE_INTRO_HAIL_MARY:
                vibeData = [new Attention.VibeProfile(25, 50)];
                break;

            // Vibration moyenne pour Notre Père
            case RosaryModel.STATE_OUR_FATHER:
            case RosaryModel.STATE_INTRO_OUR_FATHER:
                vibeData = [new Attention.VibeProfile(50, 150)];
                break;

            // Vibration longue pour Gloria (fin de dizaine)
            case RosaryModel.STATE_GLORY:
            case RosaryModel.STATE_INTRO_GLORY:
                vibeData = [
                    new Attention.VibeProfile(50, 200),
                    new Attention.VibeProfile(0, 100),
                    new Attention.VibeProfile(50, 200)
                ];
                break;

            // Vibration spéciale pour le début
            case RosaryModel.STATE_CROSS:
            case RosaryModel.STATE_CREED:
                vibeData = [new Attention.VibeProfile(30, 100)];
                break;

            // Vibration de victoire pour la fin
            case RosaryModel.STATE_COMPLETE:
            case RosaryModel.STATE_SALVE:
                vibeData = [
                    new Attention.VibeProfile(50, 200),
                    new Attention.VibeProfile(0, 150),
                    new Attention.VibeProfile(75, 300),
                    new Attention.VibeProfile(0, 150),
                    new Attention.VibeProfile(100, 500)
                ];
                break;
            
            // Vibration de transition entre mystères (Full Rosary)
            case RosaryModel.STATE_MYSTERY_TRANSITION:
                vibeData = [
                    new Attention.VibeProfile(75, 300),
                    new Attention.VibeProfile(0, 200),
                    new Attention.VibeProfile(75, 300),
                    new Attention.VibeProfile(0, 200),
                    new Attention.VibeProfile(75, 300)
                ];
                break;
        }

        if (vibeData != null) {
            Attention.vibrate(vibeData);
        }
    }

    //! Bouton Menu - Affiche le menu
    function onMenu() as Boolean {
        var settings = System.getDeviceSettings();
        var screenWidth = settings.screenWidth;
        var screenHeight = settings.screenHeight;
        var isRectangular = (screenHeight > screenWidth * 1.1);
        var useShortStrings = (screenWidth < 240) || isRectangular;
        
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
        var autoMedEnabled = _model.isAutoMeditationEnabled();
        menu.addItem(new WatchUi.ToggleMenuItem(autoMedLabel, null, "toggle_auto_meditation", autoMedEnabled, null));
        
        menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.menu_help) as String, null, "help", null));
        
        WatchUi.pushView(menu, new GarminRosaryMenuDelegate(_model), WatchUi.SLIDE_UP);
        return true;
    }

    //! Bouton Retour - Confirmation de sortie
    function onBack() as Boolean {
        _model.saveState();
        return false;
    }
}
