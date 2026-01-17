import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Math;

//! Vue principale
class GarminRosaryView extends WatchUi.View {

    private var _model as RosaryModel;
    private var _currentState as Number = RosaryModel.STATE_CROSS;

    // Palette
    private const COLOR_BG = 0x001B3A;          // Bleu Nuit Marial
    private const COLOR_GOLD = 0xFFD700;        // Or
    private const COLOR_TEXT_MAIN = 0xFFFFFF;   // Blanc pur
    private const COLOR_TEXT_DIM = 0xA0A0A0;    // Gris clair pour le secondaire
    private const COLOR_ARC_BG = 0x111111;      // Gris très foncé (presque noir) pour fond d'arc
    private const COLOR_ARC_ACTIVE = 0x66CCFF;  // Bleu Céleste pour la progression
    private const COLOR_OFF_WHITE = 0xDDDDDD;   // Blanc cassé

    function initialize(model as RosaryModel) {
        View.initialize();
        _model = model;
    }

    function setCurrentState(state as Number) as Void {
        _currentState = state;
    }

    function onLayout(dc as Dc) as Void {
    }

    function onShow() as Void {
        _model.loadState();
        // Force la mise à jour de l'état visuel (ex: après un reset depuis le menu)
        _currentState = _model.getCurrentState();
    }

    function onUpdate(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var centerY = height / 2;

        dc.setColor(COLOR_BG, COLOR_BG);
        dc.clear();

        drawProgressArc(dc, centerX, centerY, width);

        if (_model.isComplete) {
            drawCompleteScreen(dc, centerX, centerY);
        } else if (_model.pendingMysteryTransition) {
            drawTransitionScreen(dc, centerX, centerY);
        } else if (_model.phase == 0) {
            drawIntroScreen(dc, centerX, centerY);
        } else {
            drawDecadeScreen(dc, centerX, centerY);
        }
    }
    
    //! Écran de Transition entre Mystères (Full Rosary)
    private function drawTransitionScreen(dc as Dc, centerX as Number, centerY as Number) as Void {
        // Croix dorée en haut
        drawVectorCross(dc, centerX, (centerY * 0.35).toNumber());
        
        // Nom du prochain Mystère (en or, gros)
        dc.setColor(COLOR_GOLD, Graphics.COLOR_TRANSPARENT);
        var nextMysteryName = getNextMysteryTypeName();
        drawWrappedText(dc, centerX, (centerY * 0.65).toNumber(), Graphics.FONT_SYSTEM_MEDIUM, 
            nextMysteryName, 
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        
        // Instruction (en bas)
        dc.setColor(COLOR_TEXT_DIM, Graphics.COLOR_TRANSPARENT);
        var tapText = WatchUi.loadResource(Rez.Strings.text_intro) as String; // "Tap pour continuer"
        dc.drawText(centerX, centerY * 1.45, Graphics.FONT_SYSTEM_XTINY, 
            tapText, 
            Graphics.TEXT_JUSTIFY_CENTER);
    }
    
    //! Retourne le nom du prochain mystère (pour l'écran de transition) 
    private function getNextMysteryTypeName() as String {
        switch (_model.nextMysteryType) {
            case RosaryModel.MYSTERY_JOYFUL:
                return WatchUi.loadResource(Rez.Strings.mystery_joyful) as String;
            case RosaryModel.MYSTERY_SORROWFUL:
                return WatchUi.loadResource(Rez.Strings.mystery_sorrowful) as String;
            case RosaryModel.MYSTERY_GLORIOUS:
                return WatchUi.loadResource(Rez.Strings.mystery_glorious) as String;
            case RosaryModel.MYSTERY_LUMINOUS:
                return WatchUi.loadResource(Rez.Strings.mystery_luminous) as String;
            default:
                return "";
        }
    }

    private function drawProgressArc(dc as Dc, x as Number, y as Number, width as Number) as Void {
        var radius = (width / 2) - 8;
        var penWidth = 6;
        
        // Fond de l'arc
        dc.setPenWidth(penWidth);
        dc.setColor(COLOR_ARC_BG, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(x, y, radius, Graphics.ARC_CLOCKWISE, 90, 90); 

        // Arc de progression
        var progress = _model.getProgress();
        if (progress > 0) {
            var angle = 90 - (progress * 360);
            dc.setColor(COLOR_ARC_ACTIVE, Graphics.COLOR_TRANSPARENT);
            dc.drawArc(x, y, radius, Graphics.ARC_CLOCKWISE, 90, angle.toNumber());
        }
        
        // Ajout des séparateurs (fins de dizaines)
        drawSeparators(dc, x, y, radius, penWidth);
    }
    
    // Dessine des petites coupures dans l'arc pour marquer les étapes
    private function drawSeparators(dc as Dc, cx as Number, cy as Number, radius as Number, arcWidth as Number) as Void {
        dc.setColor(COLOR_BG, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        
        // Marqueurs aux grains clés (Fin Intro + Fins de dizaines/mystères)
        var markers = [] as Array<Number>;
        var total = 68.0; // Défaut : Chapelet simple
        
        if (_model.isFullRosary) {
            // Rosaire Complet : 7 intro + 3 mystères * 5 dizaines * 12 grains
            // Marqueurs : Fin Intro (7), Fin M1D1(19)...M1D5(67), Fin M2D1...M2D5(127), Fin M3D1...M3D5(187)
            // Simplifié : Marqueurs aux transitions de mystères (67, 127) + fin intro.
            total = 187.0;
            // Fin Intro, Fin Joyeux (5 diz), Fin Douloureux (10 diz)
            markers = [7, 67, 127]; // Les 3 big separators
        } else {
            // Chapelet simple : Intro: 7, Dizaines: 19, 31, 43, 55
            markers = [7, 19, 31, 43, 55];
        }
        
        for (var i = 0; i < markers.size(); i++) {
             // 90 degrés = Haut (Midi). On tourne dans le sens horaire (décrémente)
             var angleDeg = 90 - (markers[i] / total * 360);
             drawRadialTick(dc, cx, cy, radius, arcWidth, angleDeg);
        }
    }

    private function drawRadialTick(dc as Dc, cx as Number, cy as Number, radius as Number, width as Number, angleDeg as Float) as Void {
        // Conversion Degrés -> Radians
        var rad = angleDeg * Math.PI / 180.0;
        
        var cosA = Math.cos(rad);
        var sinA = Math.sin(rad);

        // On dessine un trait qui dépasse un peu de l'épaisseur de l'arc
        var innerR = radius - (width / 2); 
        var outerR = radius + (width / 2);

        var x1 = cx + innerR * cosA;
        var y1 = cy - innerR * sinA;
        var x2 = cx + outerR * cosA;
        var y2 = cy - outerR * sinA;
        
        dc.drawLine(x1, y1, x2, y2);
    }

    private function drawIntroScreen(dc as Dc, centerX as Number, centerY as Number) as Void {
        // Titre du Mystère
        dc.setColor(COLOR_GOLD, Graphics.COLOR_TRANSPARENT);
        drawWrappedText(dc, centerX, (centerY * 0.45).toNumber(), Graphics.FONT_TINY, 
            _model.getMysteryTypeName(), 
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Nom de la prière
        dc.setColor(COLOR_TEXT_MAIN, Graphics.COLOR_TRANSPARENT);
        var prayerName = getPrayerName(_currentState);

        if (_currentState == RosaryModel.STATE_CROSS && _model.beadInPhase == 0) {
            // État initial (Appartion) : Juste la croix dorée
            drawVectorCross(dc, centerX, centerY);
        } else {
            // Premier grain ou autres prières : Texte centré blanc
            dc.drawText(centerX, centerY, Graphics.FONT_SYSTEM_MEDIUM, 
                prayerName, 
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // Instruction
        dc.setColor(COLOR_TEXT_DIM, Graphics.COLOR_TRANSPARENT);
        var introText = WatchUi.loadResource(Rez.Strings.text_intro) as String;
        dc.drawText(centerX, centerY * 1.55, Graphics.FONT_SYSTEM_XTINY, 
            introText, 
            Graphics.TEXT_JUSTIFY_CENTER);
    }
    //! Écran Dizaine
    private function drawDecadeScreen(dc as Dc, centerX as Number, centerY as Number) as Void {
        // Titre du Mystère avec numéro de dizaine
        dc.setColor(COLOR_GOLD, Graphics.COLOR_TRANSPARENT);
        var mysteryTitle = _model.getCurrentMysteryTitle();
        var headerText = "";
        var titleY = 0;
        var titleHeight = 0;

        // Si on est en phase finale (phase 6), afficher juste le titre
        if (_model.phase == 6) {
            headerText = mysteryTitle;
            // Mode "Titre Seul" (comme Intro ou Fin)
            titleY = (centerY * 0.45).toNumber();
            titleHeight = drawWrappedText(dc, centerX, titleY, Graphics.FONT_TINY, 
                headerText, 
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                
        } else {
            // Mode "Dizaine" : Nombre au-dessus, Titre en-dessous
            var decadeNum = _model.getCurrentDecade();
            
            // Calculer si le titre va tenir sur 1 ou 2 lignes
            var titleFont = Graphics.FONT_TINY;
            var maxWidth = (centerX * 1.6).toNumber(); // Largeur max pour le texte
            var textWidth = dc.getTextWidthInPixels(mysteryTitle, titleFont);
            var willWrap = textWidth > maxWidth;
            
            // Position du numéro : plus bas si le titre est court (1 ligne)
            var numY = willWrap ? (centerY * 0.18).toNumber() : (centerY * 0.28).toNumber();
            
            // 1. Le Numéro (Petit, Doré)
            dc.setColor(COLOR_GOLD, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, numY, Graphics.FONT_SYSTEM_SMALL, 
                decadeNum.toString(), 
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                
            // 2. Le Titre (Position ajustée selon longueur)
            titleY = willWrap ? (centerY * 0.48).toNumber() : (centerY * 0.52).toNumber();
            titleHeight = drawWrappedText(dc, centerX, titleY, titleFont, 
                mysteryTitle, 
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        //  Fruit du Mystère
        var fruit = _model.getCurrentFruit();
        if (fruit.length() > 0) {
            dc.setColor(COLOR_OFF_WHITE, Graphics.COLOR_TRANSPARENT); 
            
            // Calcul dynamique de la position Y
            var fontHeight = dc.getFontHeight(Graphics.FONT_XTINY);
            // Le bas du titre réel
            var titleBottom = titleY + (titleHeight / 2);
            
            var defaultFruitY = (centerY * 0.76).toNumber(); 
            var minFruitTop = titleBottom + 2;
            
            var fruitY = defaultFruitY;
            
            if ((fruitY - (fontHeight / 2)) < minFruitTop) {
                 fruitY = minFruitTop + (fontHeight / 2);
            }
            
            drawWrappedText(dc, centerX, fruitY, Graphics.FONT_XTINY, 
                fruit, 
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // Compteur de grains (Centre)
        var beadNum = _model.getBeadInDecade();
        
        if (beadNum > 0) {
            dc.setColor(COLOR_TEXT_MAIN, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, centerY * 1.25, Graphics.FONT_NUMBER_HOT, 
                beadNum.toString(), 
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            
            
        } else {
            // Notre Père ou Gloria (Texte)
            dc.setColor(COLOR_TEXT_MAIN, Graphics.COLOR_TRANSPARENT);
            var prayer = getPrayerName(_currentState);
            var font = (prayer.length() > 10) ? Graphics.FONT_SYSTEM_SMALL : Graphics.FONT_SYSTEM_MEDIUM;
            
            dc.drawText(centerX, centerY * 1.25, font, 
                prayer, 
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }


        // Type de grain (sous le chiffre)
        dc.setColor(COLOR_TEXT_DIM, Graphics.COLOR_TRANSPARENT);
        var typeText = "";
        if (_currentState == RosaryModel.STATE_HAIL_MARY) { typeText = WatchUi.loadResource(Rez.Strings.prayer_ave) as String; }
        else if (_currentState == RosaryModel.STATE_OUR_FATHER) { typeText = WatchUi.loadResource(Rez.Strings.prayer_pater) as String; }
        else if (_currentState == RosaryModel.STATE_GLORY) { typeText = WatchUi.loadResource(Rez.Strings.prayer_gloria) as String; }
        
        if (beadNum > 0) { 
             // Texte "Ave Maria" collé tout en bas (1.55 -> 1.62)
             dc.drawText(centerX, centerY * 1.62, Graphics.FONT_SYSTEM_XTINY, 
                typeText, 
                Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    //! Écran Final (AMEN)
    private function drawCompleteScreen(dc as Dc, centerX as Number, centerY as Number) as Void {
        dc.setColor(COLOR_GOLD, Graphics.COLOR_TRANSPARENT);
        var amenText = WatchUi.loadResource(Rez.Strings.text_amen) as String;
        dc.drawText(centerX, centerY * 0.45, Graphics.FONT_SYSTEM_LARGE, 
            amenText, 
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(COLOR_TEXT_MAIN, Graphics.COLOR_TRANSPARENT);
        var finishedText = "";
        if (_model.isFullRosary) {
            finishedText = WatchUi.loadResource(Rez.Strings.text_finished_rosary) as String;
        } else {
            finishedText = WatchUi.loadResource(Rez.Strings.text_finished) as String;
        }
        
        drawWrappedText(dc, centerX, (centerY * 0.85).toNumber(), Graphics.FONT_SYSTEM_SMALL, 
            finishedText, 
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            
        drawVectorCross(dc, centerX, (centerY * 1.55).toNumber());
    }
    
    private function drawVectorCross(dc as Dc, x as Number, y as Number) as Void {
        dc.setColor(COLOR_GOLD, Graphics.COLOR_TRANSPARENT);
        var size = 15; 
        var thickness = 3;
        dc.fillRectangle(x - thickness/2, y - size, thickness, size * 2);
        dc.fillRectangle(x - size * 0.7, y - size * 0.3, size * 1.4, thickness);
    }

    private function getPrayerName(state as Number) as String {
        switch (state) {
            case RosaryModel.STATE_CROSS: return WatchUi.loadResource(Rez.Strings.prayer_cross) as String;
            case RosaryModel.STATE_CREED: return WatchUi.loadResource(Rez.Strings.prayer_creed) as String;
            case RosaryModel.STATE_INTRO_OUR_FATHER:
            case RosaryModel.STATE_OUR_FATHER: return WatchUi.loadResource(Rez.Strings.prayer_pater) as String;
            case RosaryModel.STATE_INTRO_HAIL_MARY:
            case RosaryModel.STATE_HAIL_MARY: return WatchUi.loadResource(Rez.Strings.prayer_ave) as String;
            case RosaryModel.STATE_INTRO_GLORY:
            case RosaryModel.STATE_GLORY: return WatchUi.loadResource(Rez.Strings.prayer_gloria) as String;
            case RosaryModel.STATE_SALVE: return WatchUi.loadResource(Rez.Strings.prayer_salve) as String;
            default: return "";
        }
    }

    // Helper pour dessiner du texte sur plusieurs lignes si trop long
    // Retourne la hauteur totale en pixels
    private function drawWrappedText(dc as Dc, x as Number, y as Number, font as FontType, text as String, attr as Number) as Number {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var radius = width / 2;
        
        // Calcul géométrique de la largeur disponible à cette hauteur Y (corde du cercle)
        var dy = (y - (height / 2)).abs();
        var availableWidth = width;
        
        if (dy < radius) {
            var halfChord = Math.sqrt(Math.pow(radius, 2) - Math.pow(dy, 2));
            availableWidth = 2 * halfChord;
        }
        
        var maxWidth = availableWidth * 0.90; 
        
        // --- LOGIQUE DE RETOUR À LA LIGNE ---
        
        // 1. Si tout tient sur une ligne, on affiche direct.
        if (dc.getTextWidthInPixels(text, font) <= maxWidth) {
            dc.drawText(x, y, font, text, attr);
            return dc.getFontHeight(font);
        }

        var words = stringSplit(text, " ");
        var lines = [] as Array<String>;
        
        // 2. Stratégie "Équilibrée" pour 2 lignes
        var totalWords = words.size();
        if (totalWords >= 2) {
             var middleIndex = totalWords / 2;
             
             var part1 = "";
             var part2 = "";
             
             for (var i = 0; i < totalWords; i++) {
                if (i < middleIndex) {
                    part1 = part1 + (part1.length() > 0 ? " " : "") + words[i];
                } else {
                    part2 = part2 + (part2.length() > 0 ? " " : "") + words[i];
                }
             }
             
             if (dc.getTextWidthInPixels(part1, font) <= maxWidth && 
                 dc.getTextWidthInPixels(part2, font) <= maxWidth) {
                 lines.add(part1);
                 lines.add(part2);
             } else {
                 lines = getGreedyLines(dc, font, words, maxWidth);
             }
        } else {
             lines = getGreedyLines(dc, font, words, maxWidth);
        }

        var fontHeight = dc.getFontHeight(font);
        var totalHeight = lines.size() * fontHeight;
        var startY = y - (totalHeight / 2) + (fontHeight / 2);

        for (var i = 0; i < lines.size(); i++) {
            dc.drawText(x, startY + (i * fontHeight), font, lines[i], attr);
        }
        
        return totalHeight;
    }
    
    // Algorithme classique qui remplit chaque ligne au max
    private function getGreedyLines(dc as Dc, font as FontType, words as Array<String>, maxWidth as Float) as Array<String> {
        var lines = [""];
        var currentLine = 0;
        
        for (var i = 0; i < words.size(); i++) {
            var word = words[i];
            var potentialLine = lines[currentLine] + (lines[currentLine].length() > 0 ? " " : "") + word;
            
            if (dc.getTextWidthInPixels(potentialLine, font) <= maxWidth) {
                lines[currentLine] = potentialLine;
            } else {
                if (lines[currentLine].length() > 0) {
                    currentLine++;
                    lines.add(word);
                } else {
                     lines[currentLine] = word;
                }
            }
        }
        return lines;
    }

    private function stringSplit(str as String, delimiter as String) as Array<String> {
        var result = [] as Array<String>;
        var current = "";
        var charArray = str.toCharArray();
        
        for (var i = 0; i < charArray.size(); i++) {
            var char = charArray[i];
            if (char == ' ') {
                if (current.length() > 0) {
                    result.add(current);
                    current = "";
                }
            } else {
                current = current + char;
            }
        }
        if (current.length() > 0) {
            result.add(current);
        }
        return result;
    }

    function onHide() as Void {
        // Sauvegarde quand on quitte la vue
        _model.saveState();
    }
}
