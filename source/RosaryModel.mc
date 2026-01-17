import Toybox.Application;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

//! Modèle de données du chapelet complet
//! Structure : Croix -> 1 NP + 3 AM + Gloria -> 5 dizaines (NP + 10 AM + Gloria) -> Salve Regina
class RosaryModel {

    //! États de navigation retournés par next()
    enum {
        STATE_CROSS,           // Signe de croix (début)
        STATE_CREED,           // Je crois en Dieu
        STATE_INTRO_OUR_FATHER,// Notre Père initial
        STATE_INTRO_HAIL_MARY, // 3 Ave Maria initiaux
        STATE_INTRO_GLORY,     // Gloria initial
        STATE_OUR_FATHER,      // Notre Père (gros grain)
        STATE_HAIL_MARY,       // Ave Maria (petit grain)
        STATE_GLORY,           // Gloria (fin de dizaine)
        STATE_SALVE,           // Salve Regina (fin)
        STATE_COMPLETE         // Chapelet terminé
    }

    //! Types de mystères
    enum {
        MYSTERY_JOYFUL,    // Joyeux (Lundi, Samedi)
        MYSTERY_SORROWFUL, // Douloureux (Mardi, Vendredi)
        MYSTERY_GLORIOUS,  // Glorieux (Mercredi, Dimanche)
        MYSTERY_LUMINOUS   // Lumineux (Jeudi)
    }

    // Variables d'état
    var phase as Number = 0;        // Phase globale (0=intro, 1-5=dizaines, 6=fin)
    var beadInPhase as Number = 0;  // Position dans la phase actuelle
    var totalBeads as Number = 0;   // Compteur total de grains
    var mysteryType as Number = MYSTERY_JOYFUL;
    var isComplete as Boolean = false;
    var isManualMystery as Boolean = false; // "Vrai" si l'utilisateur a forcé un mystère

    // Constantes
    const INTRO_BEADS = 6;          // Croix + Credo + NP + 3AM + Gloria
    const DECADE_BEADS = 12;        // NP + 10AM + Gloria
    const TOTAL_DECADES = 5;
    const TOTAL_ROSARY_BEADS = 68;  // 7 intro + 5*12 dizaines + 1 salve = 68

    //! Titres des mystères (chargés depuis JSON)
    var mysteryTitles as Dictionary or Null = null;

    //! Fruits des mystères (chargés depuis JSON)
    var mysteryFruits as Dictionary or Null = null;

    function initialize() {
        mysteryType = getMysteryForToday();
        isManualMystery = false;
        
        // Define Resource IDs directly (Code-based configuration)
        // This avoids JSON parsing issues and ensures usage of Rez.Strings
        mysteryTitles = {
            "joyful" => [Rez.Strings.joyful_1_title, Rez.Strings.joyful_2_title, Rez.Strings.joyful_3_title, Rez.Strings.joyful_4_title, Rez.Strings.joyful_5_title],
            "sorrowful" => [Rez.Strings.sorrowful_1_title, Rez.Strings.sorrowful_2_title, Rez.Strings.sorrowful_3_title, Rez.Strings.sorrowful_4_title, Rez.Strings.sorrowful_5_title],
            "glorious" => [Rez.Strings.glorious_1_title, Rez.Strings.glorious_2_title, Rez.Strings.glorious_3_title, Rez.Strings.glorious_4_title, Rez.Strings.glorious_5_title],
            "luminous" => [Rez.Strings.luminous_1_title, Rez.Strings.luminous_2_title, Rez.Strings.luminous_3_title, Rez.Strings.luminous_4_title, Rez.Strings.luminous_5_title]
        };

        mysteryFruits = {
            "joyful" => [Rez.Strings.joyful_1_fruit, Rez.Strings.joyful_2_fruit, Rez.Strings.joyful_3_fruit, Rez.Strings.joyful_4_fruit, Rez.Strings.joyful_5_fruit],
            "sorrowful" => [Rez.Strings.sorrowful_1_fruit, Rez.Strings.sorrowful_2_fruit, Rez.Strings.sorrowful_3_fruit, Rez.Strings.sorrowful_4_fruit, Rez.Strings.sorrowful_5_fruit],
            "glorious" => [Rez.Strings.glorious_1_fruit, Rez.Strings.glorious_2_fruit, Rez.Strings.glorious_3_fruit, Rez.Strings.glorious_4_fruit, Rez.Strings.glorious_5_fruit],
            "luminous" => [Rez.Strings.luminous_1_fruit, Rez.Strings.luminous_2_fruit, Rez.Strings.luminous_3_fruit, Rez.Strings.luminous_4_fruit, Rez.Strings.luminous_5_fruit]
        };
        
        reset();
    }

    //! Détermine le mystère selon le jour de la semaine
    function getMysteryForToday() as Number {
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var dayOfWeek = today.day_of_week;
        
        // 1=Dim, 2=Lun, 3=Mar, 4=Mer, 5=Jeu, 6=Ven, 7=Sam
        switch (dayOfWeek) {
            case 2: // Lundi
            case 7: // Samedi
                return MYSTERY_JOYFUL;
            case 3: // Mardi
            case 6: // Vendredi
                return MYSTERY_SORROWFUL;
            case 4: // Mercredi
            case 1: // Dimanche
                return MYSTERY_GLORIOUS;
            case 5: // Jeudi
                return MYSTERY_LUMINOUS;
            default:
                return MYSTERY_JOYFUL;
        }
    }

    //! Avance d'un grain et retourne l'état actuel
    function next() as Number {
        if (isComplete) {
            // Si on avance APRES avoir fini => Recommencer
            // Retour au mode Auto si on était en Manuel
            if (isManualMystery) {
                isManualMystery = false;
                mysteryType = getMysteryForToday();
            }
            reset();
            return STATE_CROSS;
        }

        totalBeads++;
        beadInPhase++;

        // Phase 0 : Introduction (6 étapes)
        if (phase == 0) {
            switch (beadInPhase) {
                case 1:
                    return STATE_CROSS;
                case 2:
                    return STATE_CREED;
                case 3:
                    return STATE_INTRO_OUR_FATHER;
                case 4:
                case 5:
                case 6:
                    if (beadInPhase == 6) {
                        // Après le 3ème Ave Maria, préparer Gloria
                        return STATE_INTRO_HAIL_MARY;
                    }
                    return STATE_INTRO_HAIL_MARY;
                case 7:
                    // Gloria puis passage à la première dizaine
                    phase = 1;
                    beadInPhase = 0;
                    return STATE_INTRO_GLORY;
            }
        }

        // Phases 1-5 : Les 5 dizaines
        if (phase >= 1 && phase <= 5) {
            if (beadInPhase == 1) {
                // Gros grain = Notre Père
                return STATE_OUR_FATHER;
            } else if (beadInPhase >= 2 && beadInPhase <= 11) {
                // Petits grains = Ave Maria (10)
                return STATE_HAIL_MARY;
            } else if (beadInPhase == 12) {
                // Gloria et passage à la dizaine suivante
                phase++;
                beadInPhase = 0;
                
                if (phase > 5) {
                    // Fin des dizaines, passage au Salve Regina
                    return STATE_GLORY;
                }
                return STATE_GLORY;
            }
        }

        // Phase 6 : Fin (Salve Regina)
        if (phase == 6) {
            isComplete = true;
            return STATE_COMPLETE;
        }

        return STATE_HAIL_MARY;
    }

    //! Recule d'un grain
    function previous() as Void {
        if (totalBeads > 0) {
            totalBeads--;
        }
        
        if (beadInPhase > 0) {
            beadInPhase--;
        } else if (phase > 0) {
            phase--;
            if (phase == 0) {
                beadInPhase = 6; // Retour à la fin de l'intro
            } else {
                beadInPhase = 11; // Retour au dernier Ave Maria de la dizaine précédente
            }
        }
        
        isComplete = false;
    }

    //! Retourne le titre du mystère actuel
    function getCurrentMysteryTitle() as String {
        var key = getMysteryKey(mysteryType);
        if (key != null && mysteryTitles != null) {
            var titles = mysteryTitles[key] as Array; // Untyped array to avoid ResourceId type casting issues
            if (phase >= 1 && phase <= 5) {
                return WatchUi.loadResource(titles[phase - 1]) as String;
            } else if (phase == 6) {
                return WatchUi.loadResource(Rez.Strings.text_finished) as String;
            }
        }
        return "";
    }

    //! Retourne le fruit du mystère actuel
    function getCurrentFruit() as String {
        var key = getMysteryKey(mysteryType);
        if (key != null && mysteryFruits != null) {
            var fruits = mysteryFruits[key] as Array; // Untyped array
            if (phase >= 1 && phase <= 5) {
                return WatchUi.loadResource(fruits[phase - 1]) as String;
            }
        }
        return "";
    }
    
    //! Helper pour obtenir la clé JSON correspondant au type de mystère
    function getMysteryKey(type as Number) as String or Null {
        switch (type) {
            case MYSTERY_JOYFUL: return "joyful";
            case MYSTERY_SORROWFUL: return "sorrowful";
            case MYSTERY_GLORIOUS: return "glorious";
            case MYSTERY_LUMINOUS: return "luminous";
            default: return null;
        }
    }

    //! Retourne le type de mystère en texte
    function getMysteryTypeName() as String {
        switch (mysteryType) {
            case MYSTERY_JOYFUL:
                return WatchUi.loadResource(Rez.Strings.mystery_joyful) as String;
            case MYSTERY_SORROWFUL:
                return WatchUi.loadResource(Rez.Strings.mystery_sorrowful) as String;
            case MYSTERY_GLORIOUS:
                return WatchUi.loadResource(Rez.Strings.mystery_glorious) as String;
            case MYSTERY_LUMINOUS:
                return WatchUi.loadResource(Rez.Strings.mystery_luminous) as String;
            default:
                return "";
        }
    }

    //! Retourne le numéro de dizaine actuelle (1-5), 5 pour phase finale, ou 0 si intro
    function getCurrentDecade() as Number {
        if (phase >= 1 && phase <= 5) {
            return phase;
        } else if (phase == 6) {
            return 5; // Garde l'affichage 5e dizaine pour la fin
        }
        return 0;
    }

    //! Calcule l'état actuel basé sur phase et beadInPhase
    function getCurrentState() as Number {
        if (isComplete) {
            return STATE_COMPLETE;
        }

        if (phase == 0) {
            if (beadInPhase == 0 || beadInPhase == 1) { return STATE_CROSS; }
            if (beadInPhase == 2) { return STATE_CREED; }
            if (beadInPhase == 3) { return STATE_INTRO_OUR_FATHER; }
            if (beadInPhase >= 4 && beadInPhase <= 6) { return STATE_INTRO_HAIL_MARY; }
            // Cas 7 géré par le passage à phase 1
        }

        if (phase >= 1 && phase <= 5) {
            if (beadInPhase == 0) {
                // Si on est au début d'une phase, c'est qu'on vient de finir la précédente
                return (phase == 1) ? STATE_INTRO_GLORY : STATE_GLORY;
            }
            if (beadInPhase == 1) { return STATE_OUR_FATHER; }
            if (beadInPhase >= 2 && beadInPhase <= 11) { return STATE_HAIL_MARY; }
            // Fin de phase gérée par passage à phase suivante
        }

        if (phase == 6) {
            return STATE_COMPLETE;
        }

        return STATE_CROSS;
    }

    //! Retourne le numéro du grain dans la dizaine (1-10) ou 0
    function getBeadInDecade() as Number {
        if (phase >= 1 && phase <= 5 && beadInPhase >= 2 && beadInPhase <= 11) {
            return beadInPhase - 1;
        }
        return 0;
    }

    //! Pourcentage de progression
    function getProgress() as Float {
        return totalBeads.toFloat() / TOTAL_ROSARY_BEADS.toFloat();
    }

    //! Réinitialise le chapelet
    function reset() as Void {
        phase = 0;
        beadInPhase = 0;
        totalBeads = 0;
        isComplete = false;
    }

    //! Configure un mystère manuellement (mode temporaire)
    function setManualMystery(type as Number) as Void {
        mysteryType = type;
        isManualMystery = true;
        reset();
    }

    //! Configure le mode Automatique (mystère du jour)
    function setAutoMystery() as Void {
        mysteryType = getMysteryForToday();
        isManualMystery = false;
        reset();
    }
    
    //! Reset Utilisateur (via Menu) : Force le retour à l'Auto
    function fullReset() as Void {
        setAutoMystery(); // Reset implicite
    }

    //! Sauvegarde l'état dans le storage
    function saveState() as Void {
        var storage = Application.Storage;
        storage.setValue("phase", phase);
        storage.setValue("beadInPhase", beadInPhase);
        storage.setValue("totalBeads", totalBeads);
        storage.setValue("mysteryType", mysteryType);
        storage.setValue("isManualMystery", isManualMystery);
        storage.setValue("isComplete", isComplete);
    }

    //! Restaure l'état depuis le storage
    function loadState() as Void {
        var storage = Application.Storage;
        var savedPhase = storage.getValue("phase");
        if (savedPhase != null) {
            phase = savedPhase as Number;
            beadInPhase = storage.getValue("beadInPhase") as Number;
            var savedTotalBeads = storage.getValue("totalBeads");
            if (savedTotalBeads != null) { totalBeads = savedTotalBeads as Number; }
        
            var savedMystery = storage.getValue("mysteryType");
            if (savedMystery != null) { mysteryType = savedMystery as Number; }
        
            var savedManual = storage.getValue("isManualMystery");
            if (savedManual != null) { isManualMystery = savedManual as Boolean; }
        
            var savedComplete = storage.getValue("isComplete");
            if (savedComplete != null) {
                isComplete = savedComplete as Boolean;
            }
        }
    }

    //! Efface l'état sauvegardé
    function clearSavedState() as Void {
        Application.Storage.clearValues();
    }
}
