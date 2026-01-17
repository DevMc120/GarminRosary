import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

//! Application principale du chapelet
class GarminRosaryApp extends Application.AppBase {

    private var _model as RosaryModel?;

    function initialize() {
        AppBase.initialize();
    }

    //! Appelé au démarrage de l'application
    function onStart(state as Dictionary?) as Void {
        // Initialisation du modèle
        _model = new RosaryModel();
    }

    //! Appelé à l'arrêt de l'application
    function onStop(state as Dictionary?) as Void {
        // Sauvegarde de l'état
        if (_model != null) {
            _model.saveState();
        }
    }

    //! Retourne la vue initiale
    function getInitialView() as [Views] or [Views, InputDelegates] {
        if (_model == null) {
            _model = new RosaryModel();
        }
        
        var view = new GarminRosaryView(_model);
        var delegate = new GarminRosaryDelegate(_model, view);
        
        return [view, delegate];
    }
}

//! Fonction globale pour accéder à l'application
function getApp() as GarminRosaryApp {
    return Application.getApp() as GarminRosaryApp;
}