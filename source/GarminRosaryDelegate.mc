import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Attention;
import Toybox.System;

//! Gère les entrées utilisateur et les vibrations
class GarminRosaryDelegate extends WatchUi.BehaviorDelegate {

    private var _model as RosaryModel;
    private var _view as GarminRosaryView;

    function initialize(model as RosaryModel, view as GarminRosaryView) {
        BehaviorDelegate.initialize();
        _model = model;
        _view = view;
    }

    //! Bouton Select (généralement haut-droite) - Avance d'un grain
    function onSelect() as Boolean {
        advanceBead();
        return true;
    }

    //! Tap sur l'écran tactile - Avance d'un grain
    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        advanceBead();
        return true;
    }

    //! Bouton Haut - Avance d'un grain
    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        
        if (key == WatchUi.KEY_UP || key == WatchUi.KEY_ENTER) {
            advanceBead();
            return true;
        } else if (key == WatchUi.KEY_DOWN) {
            goBack();
            return true;
        }
        
        return false;
    }

    //! Swipe vers le haut - Avance
    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
        var direction = swipeEvent.getDirection();
        
        if (direction == WatchUi.SWIPE_UP || direction == WatchUi.SWIPE_RIGHT) {
            advanceBead();
            return true;
        } else if (direction == WatchUi.SWIPE_DOWN || direction == WatchUi.SWIPE_LEFT) {
            goBack();
            return true;
        }
        
        return false;
    }

    //! Avance d'un grain avec vibration appropriée
    private function advanceBead() as Void {
        var state = _model.next();
        
        // Mise à jour de la vue avec le nouvel état
        _view.setCurrentState(state);
        
        // Vibration selon l'état
        triggerVibration(state);
        
        // Sauvegarde de l'état
        _model.saveState();
        
        // Demande rafraîchissement de l'écran
        WatchUi.requestUpdate();
    }

    //! Recule d'un grain
    private function goBack() as Void {
        _model.previous();
        
        // Mise à jour de la vue avec le nouvel état
        var state = _model.getCurrentState();
        _view.setCurrentState(state);
        
        _model.saveState();
        WatchUi.requestUpdate();
    }

    //! Déclenche la vibration appropriée
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
        // Detect screen size to choose appropriate string length
        var settings = System.getDeviceSettings();
        var screenWidth = settings.screenWidth;
        var screenHeight = settings.screenHeight;
        var isRectangular = (screenHeight > screenWidth * 1.1);
        var useShortStrings = (screenWidth < 220) || isRectangular; // FR55 (small) OR Venu Sq (rectangular)
        
        // On small screens, don't show title (it gets truncated)
        var title = useShortStrings ? null : WatchUi.loadResource(Rez.Strings.AppName) as String;
        var menu = new WatchUi.Menu2({:title=>title});
        
        // Menu Items with conditional string selection
        menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.menu_restart) as String, null, "restart", null));
        menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(useShortStrings ? Rez.Strings.MysteryAuto_short : Rez.Strings.MysteryAuto) as String, null, "mystery_auto", null));
        
        // Nouvelle option : Rosaire Complet (3 mystères)
        menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(useShortStrings ? Rez.Strings.menu_rosary_short : Rez.Strings.menu_rosary) as String, null, "start_rosary", null));
        
        menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(useShortStrings ? Rez.Strings.menu_joyful_short : Rez.Strings.menu_joyful) as String, null, "mystery_joyful", null));
        menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(useShortStrings ? Rez.Strings.menu_sorrowful_short : Rez.Strings.menu_sorrowful) as String, null, "mystery_sorrowful", null));
        menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(useShortStrings ? Rez.Strings.menu_glorious_short : Rez.Strings.menu_glorious) as String, null, "mystery_glorious", null));
        menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(useShortStrings ? Rez.Strings.menu_luminous_short : Rez.Strings.menu_luminous) as String, null, "mystery_luminous", null));
        
        WatchUi.pushView(menu, new GarminRosaryMenuDelegate(_model), WatchUi.SLIDE_UP);
        return true;
    }

    //! Bouton Retour - Confirmation de sortie
    function onBack() as Boolean {
        // Sauvegarde avant de quitter
        _model.saveState();
        return false; // Laisse le comportement par défaut (quitter)
    }
}