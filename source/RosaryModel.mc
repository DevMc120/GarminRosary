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
        STATE_MYSTERY_TRANSITION, // Écran de transition entre mystères (Full Rosary)
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
    var phase as Number = 0;        
    var beadInPhase as Number = 0;  
    var totalBeads as Number = 0;   
    var mysteryType as Number = MYSTERY_JOYFUL;
    var isComplete as Boolean = false;
    var isManualMystery as Boolean = false;
    var isFullRosary as Boolean = false;    
    var pendingMysteryTransition as Boolean = false; 
    var nextMysteryType as Number = MYSTERY_JOYFUL; 

    const INTRO_BEADS = 6;          
    const DECADE_BEADS = 12;        
    const TOTAL_DECADES = 5;
    const TOTAL_ROSARY_BEADS = 68;  

    var mysteryTitles as Dictionary or Null = null;
    var mysteryFruits as Dictionary or Null = null;

    function initialize() {
        mysteryType = getMysteryForToday();
        isManualMystery = false;
        
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

    function next() as Number {
        if (isComplete) {
            if (isManualMystery) {
                isManualMystery = false;
                mysteryType = getMysteryForToday();
            }
            reset();
            return STATE_CROSS;
        }

        totalBeads++;
        beadInPhase++;
        
        saveState();

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
                        return STATE_INTRO_HAIL_MARY;
                    }
                    return STATE_INTRO_HAIL_MARY;
                case 7:
                    return STATE_INTRO_GLORY;
                case 8:
                    phase = 1;
                    beadInPhase = 1;
                    return STATE_OUR_FATHER;
            }
        }

        if (phase >= 1 && phase <= 5) {
            if (beadInPhase == 1) {
                return STATE_OUR_FATHER;
            } else if (beadInPhase >= 2 && beadInPhase <= 11) {
                return STATE_HAIL_MARY;
            } else if (beadInPhase == 12) {
                return STATE_GLORY;
                
            } else if (beadInPhase > 12) {
                phase++;
                beadInPhase = 1; 
                
                if (phase > 5) {
                    
                    
                    if (isFullRosary) {
                        if (pendingMysteryTransition) {
                            pendingMysteryTransition = false;
                            mysteryType = nextMysteryType;
                            phase = 1;
                            beadInPhase = 1;
                            totalBeads--; 
                            return STATE_OUR_FATHER;
                        }
                        
                        if (mysteryType == MYSTERY_JOYFUL) {
                            nextMysteryType = MYSTERY_SORROWFUL;
                            pendingMysteryTransition = true;
                            phase = 5;
                            beadInPhase = 13;
                            totalBeads--;
                            return STATE_MYSTERY_TRANSITION;
                            
                        } else if (mysteryType == MYSTERY_SORROWFUL) {
                            nextMysteryType = MYSTERY_GLORIOUS;
                            pendingMysteryTransition = true;
                            phase = 5;
                            beadInPhase = 13;
                            totalBeads--;
                            return STATE_MYSTERY_TRANSITION;
                        } 
                    }
                    
                    phase = 6;
                    isComplete = true;
                    return STATE_COMPLETE;
                }
                return STATE_OUR_FATHER;
            }
        }

        if (phase == 6) {
            isComplete = true;
            return STATE_COMPLETE;
        }

        return STATE_HAIL_MARY;
    }

    function previous() as Void {
        if (pendingMysteryTransition) {
            pendingMysteryTransition = false;
            phase = 5;
            beadInPhase = 12;
            if (totalBeads > 0) {
                totalBeads--;
            }
            isComplete = false;
            saveState();
            return;
        }
        
        if (totalBeads > 0) {
            totalBeads--;
        }
        
        if (beadInPhase > 0) {
            beadInPhase--;
        }
        
        saveState();
        
        if (beadInPhase == 0) {
            
            if (isFullRosary && phase == 1) {
                if (mysteryType == MYSTERY_SORROWFUL) {
                    mysteryType = MYSTERY_JOYFUL;
                    phase = 5;
                    beadInPhase = 12;
                    return;
                } else if (mysteryType == MYSTERY_GLORIOUS) {
                    mysteryType = MYSTERY_SORROWFUL;
                    phase = 5;
                    beadInPhase = 12;
                    return;
                } else if (mysteryType == MYSTERY_LUMINOUS) {
                    mysteryType = MYSTERY_JOYFUL;
                    phase = 5;
                    beadInPhase = 12;
                    return;
                }
            }
            
            if (phase > 0) {
                phase--;
                if (phase == 0) {
                    beadInPhase = 7;
                } else {
                    beadInPhase = 12;
                }
            } else {
                beadInPhase = 0;
            }
        }
        
        isComplete = false;
    }

    function getCurrentMysteryTitle() as String {
        var key = getMysteryKey(mysteryType);
        if (key != null && mysteryTitles != null) {
            var titles = mysteryTitles[key] as Array;
            if (phase >= 1 && phase <= 5) {
                return WatchUi.loadResource(titles[phase - 1]) as String;
            } else if (phase == 6) {
                return getMysteryTypeName();
            }
        }
        return "";
    }

    function getCurrentFruit() as String {
        var key = getMysteryKey(mysteryType);
        if (key != null && mysteryFruits != null) {
            var fruits = mysteryFruits[key] as Array;
            if (phase >= 1 && phase <= 5) {
                return WatchUi.loadResource(fruits[phase - 1]) as String;
            }
        }
        return "";
    }
    
    function getMysteryKey(type as Number) as String or Null {
        switch (type) {
            case MYSTERY_JOYFUL: return "joyful";
            case MYSTERY_SORROWFUL: return "sorrowful";
            case MYSTERY_GLORIOUS: return "glorious";
            case MYSTERY_LUMINOUS: return "luminous";
            default: return null;
        }
    }

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

    function getCurrentDecade() as Number {
        if (phase >= 1 && phase <= 5) {
            return phase;
        } else if (phase == 6) {
            return 5;
        }
        return 0;
    }

    function getCurrentState() as Number {
        if (isComplete) {
            return STATE_COMPLETE;
        }

        if (phase == 0) {
            if (beadInPhase == 0 || beadInPhase == 1) { return STATE_CROSS; }
            if (beadInPhase == 2) { return STATE_CREED; }
            if (beadInPhase == 3) { return STATE_INTRO_OUR_FATHER; }
            if (beadInPhase >= 4 && beadInPhase <= 6) { return STATE_INTRO_HAIL_MARY; }
            if (beadInPhase == 7) { return STATE_INTRO_GLORY; }
        }

        if (phase >= 1 && phase <= 5) {
            if (beadInPhase == 0) {
                return (phase == 1) ? STATE_INTRO_GLORY : STATE_GLORY;
            }
            if (beadInPhase == 1) { return STATE_OUR_FATHER; }
            if (beadInPhase >= 2 && beadInPhase <= 11) { return STATE_HAIL_MARY; }
            if (beadInPhase == 12) { return STATE_GLORY; }
        }

        if (phase == 6) {
            return STATE_GLORY;
        }

        return STATE_CROSS;
    }

    function getBeadInDecade() as Number {
        if (phase >= 1 && phase <= 5 && beadInPhase >= 2 && beadInPhase <= 11) {
            return beadInPhase - 1;
        }
        return 0;
    }

    function getProgress() as Float {
        var totalExpected = TOTAL_ROSARY_BEADS;
        if (isFullRosary) {
            totalExpected = 7 + (3 * 5 * 12);
        }
        return totalBeads.toFloat() / totalExpected.toFloat();
    }

    function reset() as Void {
        phase = 0;
        beadInPhase = 0;
        totalBeads = 0;
        isComplete = false;
        pendingMysteryTransition = false;
        
        if (isFullRosary) {
            mysteryType = MYSTERY_JOYFUL;
            isManualMystery = true;
        }
    }
    
    function setManualMystery(type as Number) as Void {
        mysteryType = type;
        isManualMystery = true;
        isFullRosary = false;
        reset();
        saveState();
    }

    function setAutoMystery() as Void {
        mysteryType = getMysteryForToday();
        isManualMystery = false;
        isFullRosary = false;
        reset();
        saveState();
    }
    
    function startFullRosary() as Void {
        isFullRosary = true;
        isManualMystery = true;
        mysteryType = MYSTERY_JOYFUL;
        reset();
        saveState();
    }
    
    function fullReset() as Void {
        setAutoMystery();
    }

    function saveState() as Void {
        var storage = Application.Storage;
        storage.setValue("phase", phase);
        storage.setValue("beadInPhase", beadInPhase);
        storage.setValue("totalBeads", totalBeads);
        storage.setValue("mysteryType", mysteryType);
        storage.setValue("isManualMystery", isManualMystery);
        storage.setValue("isFullRosary", isFullRosary);
        storage.setValue("isComplete", isComplete);
        storage.setValue("pendingMysteryTransition", pendingMysteryTransition);
        storage.setValue("nextMysteryType", nextMysteryType);
    }

    function loadState() as Void {
        var storage = Application.Storage;
        var savedPhase = storage.getValue("phase");
        if (savedPhase != null) {
            phase = savedPhase as Number;
            var savedBead = storage.getValue("beadInPhase");
            if (savedBead != null) { beadInPhase = savedBead as Number; }
            else { beadInPhase = 0; }
            var savedTotalBeads = storage.getValue("totalBeads");
            if (savedTotalBeads != null) { totalBeads = savedTotalBeads as Number; }
        
            var savedMystery = storage.getValue("mysteryType");
            if (savedMystery != null) { mysteryType = savedMystery as Number; }
        
            var savedManual = storage.getValue("isManualMystery");
            if (savedManual != null) { isManualMystery = savedManual as Boolean; }

            var savedFull = storage.getValue("isFullRosary");
            if (savedFull != null) { isFullRosary = savedFull as Boolean; }
        
            var savedComplete = storage.getValue("isComplete");
            if (savedComplete != null) {
                isComplete = savedComplete as Boolean;
            }
            
            var savedPending = storage.getValue("pendingMysteryTransition");
            if (savedPending != null) { pendingMysteryTransition = savedPending as Boolean; }
            
            var savedNextMystery = storage.getValue("nextMysteryType");
            if (savedNextMystery != null) { nextMysteryType = savedNextMystery as Number; }
            
            if (!isManualMystery && phase == 0) {
                mysteryType = getMysteryForToday();
            }
        }
    }

    function clearSavedState() as Void {
        var storage = Application.Storage;
        storage.deleteValue("phase");
        storage.deleteValue("beadInPhase");
        storage.deleteValue("totalBeads");
        storage.deleteValue("mysteryType");
        storage.deleteValue("isManualMystery");
        storage.deleteValue("isFullRosary");
        storage.deleteValue("isComplete");
        storage.deleteValue("pendingMysteryTransition");
        storage.deleteValue("nextMysteryType");
    }

    function isAutoMeditationEnabled() as Boolean {
        var storage = Application.Storage;
        var value = storage.getValue("autoMeditation");
        if (value != null) {
            return value as Boolean;
        }
        return false;
    }

    function setAutoMeditation(enabled as Boolean) as Void {
        Application.Storage.setValue("autoMeditation", enabled);
    }
}
