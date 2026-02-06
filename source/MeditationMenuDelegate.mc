import Toybox.Lang;
import Toybox.WatchUi;

class MeditationMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _model as RosaryModel;

    function initialize(model as RosaryModel) {
        Menu2InputDelegate.initialize();
        _model = model;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        
        if (id != null) {
            var idStr = id.toString();
            
            if (idStr.equals("cat_joyful")) {
                openMysteryMenu(RosaryModel.MYSTERY_JOYFUL);
            } else if (idStr.equals("cat_luminous")) {
                openMysteryMenu(RosaryModel.MYSTERY_LUMINOUS);
            } else if (idStr.equals("cat_sorrowful")) {
                openMysteryMenu(RosaryModel.MYSTERY_SORROWFUL);
            } else if (idStr.equals("cat_glorious")) {
                openMysteryMenu(RosaryModel.MYSTERY_GLORIOUS);
            }
            else if (idStr.find("mystery_") == 0) {
                var parts = splitId(idStr);
                if (parts.size() >= 3) {
                    var category = parts[1].toNumber();
                    var decade = parts[2].toNumber();
                    if (category != null && decade != null) {
                        openMeditationForMystery(category, decade);
                    }
                }
            }
        }
    }

    private function openMysteryMenu(mysteryType as Number) as Void {
        var menu = new WatchUi.Menu2({:title => getCategoryTitle(mysteryType)});
        
        for (var i = 1; i <= 5; i++) {
            var title = getMysteryTitle(mysteryType, i);
            var subtitle = getMysteryFruit(mysteryType, i);
            var id = "mystery_" + mysteryType + "_" + i;
            menu.addItem(new WatchUi.MenuItem(title, subtitle, id, null));
        }
        
        WatchUi.pushView(menu, new MeditationMenuDelegate(_model), WatchUi.SLIDE_LEFT);
    }

    private function openMeditationForMystery(mysteryType as Number, decade as Number) as Void {
        var meditationView = new MeditationViewStatic(mysteryType, decade);
        var meditationDelegate = new MeditationDelegate(meditationView);
        WatchUi.pushView(meditationView, meditationDelegate, WatchUi.SLIDE_LEFT);
    }

    private function getCategoryTitle(mysteryType as Number) as String {
        switch (mysteryType) {
            case RosaryModel.MYSTERY_JOYFUL:
                return WatchUi.loadResource(Rez.Strings.mystery_joyful) as String;
            case RosaryModel.MYSTERY_LUMINOUS:
                return WatchUi.loadResource(Rez.Strings.mystery_luminous) as String;
            case RosaryModel.MYSTERY_SORROWFUL:
                return WatchUi.loadResource(Rez.Strings.mystery_sorrowful) as String;
            case RosaryModel.MYSTERY_GLORIOUS:
                return WatchUi.loadResource(Rez.Strings.mystery_glorious) as String;
            default:
                return "Mystères";
        }
    }

    private function getMysteryTitle(mysteryType as Number, decade as Number) as String {
        // Joyful
        if (mysteryType == RosaryModel.MYSTERY_JOYFUL) {
            switch (decade) {
                case 1: return WatchUi.loadResource(Rez.Strings.joyful_1_title) as String;
                case 2: return WatchUi.loadResource(Rez.Strings.joyful_2_title) as String;
                case 3: return WatchUi.loadResource(Rez.Strings.joyful_3_title) as String;
                case 4: return WatchUi.loadResource(Rez.Strings.joyful_4_title) as String;
                case 5: return WatchUi.loadResource(Rez.Strings.joyful_5_title) as String;
            }
        }
        // Luminous
        else if (mysteryType == RosaryModel.MYSTERY_LUMINOUS) {
            switch (decade) {
                case 1: return WatchUi.loadResource(Rez.Strings.luminous_1_title) as String;
                case 2: return WatchUi.loadResource(Rez.Strings.luminous_2_title) as String;
                case 3: return WatchUi.loadResource(Rez.Strings.luminous_3_title) as String;
                case 4: return WatchUi.loadResource(Rez.Strings.luminous_4_title) as String;
                case 5: return WatchUi.loadResource(Rez.Strings.luminous_5_title) as String;
            }
        }
        // Sorrowful
        else if (mysteryType == RosaryModel.MYSTERY_SORROWFUL) {
            switch (decade) {
                case 1: return WatchUi.loadResource(Rez.Strings.sorrowful_1_title) as String;
                case 2: return WatchUi.loadResource(Rez.Strings.sorrowful_2_title) as String;
                case 3: return WatchUi.loadResource(Rez.Strings.sorrowful_3_title) as String;
                case 4: return WatchUi.loadResource(Rez.Strings.sorrowful_4_title) as String;
                case 5: return WatchUi.loadResource(Rez.Strings.sorrowful_5_title) as String;
            }
        }
        // Glorious
        else if (mysteryType == RosaryModel.MYSTERY_GLORIOUS) {
            switch (decade) {
                case 1: return WatchUi.loadResource(Rez.Strings.glorious_1_title) as String;
                case 2: return WatchUi.loadResource(Rez.Strings.glorious_2_title) as String;
                case 3: return WatchUi.loadResource(Rez.Strings.glorious_3_title) as String;
                case 4: return WatchUi.loadResource(Rez.Strings.glorious_4_title) as String;
                case 5: return WatchUi.loadResource(Rez.Strings.glorious_5_title) as String;
            }
        }
        return "Mystère " + decade;
    }

    //! Retourne le fruit d'un mystère spécifique
    private function getMysteryFruit(mysteryType as Number, decade as Number) as String {
        // Joyful
        if (mysteryType == RosaryModel.MYSTERY_JOYFUL) {
            switch (decade) {
                case 1: return WatchUi.loadResource(Rez.Strings.joyful_1_fruit) as String;
                case 2: return WatchUi.loadResource(Rez.Strings.joyful_2_fruit) as String;
                case 3: return WatchUi.loadResource(Rez.Strings.joyful_3_fruit) as String;
                case 4: return WatchUi.loadResource(Rez.Strings.joyful_4_fruit) as String;
                case 5: return WatchUi.loadResource(Rez.Strings.joyful_5_fruit) as String;
            }
        }
        // Luminous
        else if (mysteryType == RosaryModel.MYSTERY_LUMINOUS) {
            switch (decade) {
                case 1: return WatchUi.loadResource(Rez.Strings.luminous_1_fruit) as String;
                case 2: return WatchUi.loadResource(Rez.Strings.luminous_2_fruit) as String;
                case 3: return WatchUi.loadResource(Rez.Strings.luminous_3_fruit) as String;
                case 4: return WatchUi.loadResource(Rez.Strings.luminous_4_fruit) as String;
                case 5: return WatchUi.loadResource(Rez.Strings.luminous_5_fruit) as String;
            }
        }
        // Sorrowful
        else if (mysteryType == RosaryModel.MYSTERY_SORROWFUL) {
            switch (decade) {
                case 1: return WatchUi.loadResource(Rez.Strings.sorrowful_1_fruit) as String;
                case 2: return WatchUi.loadResource(Rez.Strings.sorrowful_2_fruit) as String;
                case 3: return WatchUi.loadResource(Rez.Strings.sorrowful_3_fruit) as String;
                case 4: return WatchUi.loadResource(Rez.Strings.sorrowful_4_fruit) as String;
                case 5: return WatchUi.loadResource(Rez.Strings.sorrowful_5_fruit) as String;
            }
        }
        // Glorious
        else if (mysteryType == RosaryModel.MYSTERY_GLORIOUS) {
            switch (decade) {
                case 1: return WatchUi.loadResource(Rez.Strings.glorious_1_fruit) as String;
                case 2: return WatchUi.loadResource(Rez.Strings.glorious_2_fruit) as String;
                case 3: return WatchUi.loadResource(Rez.Strings.glorious_3_fruit) as String;
                case 4: return WatchUi.loadResource(Rez.Strings.glorious_4_fruit) as String;
                case 5: return WatchUi.loadResource(Rez.Strings.glorious_5_fruit) as String;
            }
        }
        return "";
    }

    private function splitId(str as String) as Array<String> {
        var result = [] as Array<String>;
        var current = str;
        var separator = "_";
        var length = separator.length();
        
        while (true) {
            var index = current.find(separator);
            
            if (index != null) {
                var part = current.substring(0, index);
                if (part.length() > 0) {
                    result.add(part);
                }
                
                if (index + length < current.length()) {
                    current = current.substring(index + length, current.length());
                } else {
                    current = "";
                    break;
                }
            } else {
                break;
            }
        }
        
        if (current.length() > 0) {
            result.add(current);
        }
        return result;
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
