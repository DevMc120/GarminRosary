import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Math;

//! Vue principale - Design Marial Épuré
class GarminRosaryView extends WatchUi.View {

    private var _model as RosaryModel;
    private var _currentState as Number = RosaryModel.STATE_CROSS;

    // Palette "Mariale"
    private const COLOR_BG = 0x001B3A;          // Bleu Nuit Marial (plus élégant que le noir)
    private const COLOR_GOLD = 0xFFD700;        // Or pour le sacré
    private const COLOR_TEXT_MAIN = 0xFFFFFF;   // Blanc pur
    private const COLOR_TEXT_DIM = 0xA0A0A0;    // Gris clair pour le secondaire
    private const COLOR_ARC_BG = 0x111111;      // Gris très foncé (presque noir) pour fond d'arc discret
    private const COLOR_ARC_ACTIVE = 0x66CCFF;  // Bleu Céleste pour la progression
    private const COLOR_OFF_WHITE = 0xDDDDDD;   // Blanc cassé (plus doux que le blanc pur)

    function initialize(model as RosaryModel) {
        View.initialize();
        _model = model;
    }

    function setCurrentState(state as Number) as Void {
        _currentState = state;
    }

    function onLayout(dc as Dc) as Void {
        // Dessin manuel
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
        } else if (_model.phase == 0) {
            drawIntroScreen(dc, centerX, centerY);
        } else {
            drawDecadeScreen(dc, centerX, centerY);
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
        
        // Si on est en phase finale (phase 6), afficher juste le titre
        if (_model.phase == 6) {
            headerText = mysteryTitle;
        } else {
            // "1e - L'Annonciation"
            headerText = _model.getCurrentDecade() + " - " + mysteryTitle;
        }
        
        var titleY = (centerY * 0.28).toNumber();
        
        // Si phase 6 (Transition finale), on aligne le titre comme l'écran d'intro (plus bas)
        // pour éviter le chevauchement avec l'arc et garder la symétrie.
        if (_model.phase == 6) {
            titleY = (centerY * 0.45).toNumber();
        }

        var titleHeight = drawWrappedText(dc, centerX, titleY, Graphics.FONT_TINY, 
            headerText, 
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        //  Fruit du Mystère (XTINY pour hiérarchie et gain de place)
        var fruit = _model.getCurrentFruit();
        if (fruit.length() > 0) {
            dc.setColor(COLOR_OFF_WHITE, Graphics.COLOR_TRANSPARENT); 
            
            // Calcul dynamique de la position Y
            var fontHeight = dc.getFontHeight(Graphics.FONT_XTINY);
            var titleBottom = titleY + (titleHeight / 2);
            
            // On descend un peu le default (0.58 au lieu de 0.48) pour respirer
            var defaultFruitY = (centerY * 0.58).toNumber(); 
            var minFruitTop = titleBottom + 4; // Padding 4px
            
            var fruitY = defaultFruitY;
            
            // Si le fruit par défaut est trop haut et va toucher le titre
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
            // Chiffre SEUL (sans fond rond moche)
            dc.setColor(COLOR_TEXT_MAIN, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, centerY, Graphics.FONT_NUMBER_HOT, 
                beadNum.toString(), 
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            
            // Petits points de progression (remontés pour ne pas toucher le bord)
            drawBeadDots(dc, centerX, (centerY * 1.6).toNumber(), beadNum);
            
        } else {
            // Notre Père ou Gloria (Texte)
            dc.setColor(COLOR_TEXT_MAIN, Graphics.COLOR_TRANSPARENT);
            var prayer = getPrayerName(_currentState);
            var font = (prayer.length() > 10) ? Graphics.FONT_SYSTEM_SMALL : Graphics.FONT_SYSTEM_MEDIUM;
            
            dc.drawText(centerX, centerY, font, 
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
             // Texte remonté légèrement pour s'éloigner des points du bas
             dc.drawText(centerX, centerY * 1.35, Graphics.FONT_SYSTEM_XTINY, 
                typeText, 
                Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    //! Dessine les points (perles) de la dizaine
    private function drawBeadDots(dc as Dc, x as Number, y as Number, current as Number) as Void {
        var spacing = 12; // Un peu plus espacé que 10
        var startX = x - (spacing * 4.5); 
        
        for (var i = 1; i <= 10; i++) {
            var dotX = startX + (i-1) * spacing;
            if (i <= current) {
                dc.setColor(COLOR_GOLD, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(dotX, y, 3);
            } else {
                // Gris foncé discret pour les points restants (meilleur contraste que le bleu)
                dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(dotX, y, 2);
            }
        }
    }

    //! Écran Final (AMEN)
    private function drawCompleteScreen(dc as Dc, centerX as Number, centerY as Number) as Void {
        // AMEN remonté
        dc.setColor(COLOR_GOLD, Graphics.COLOR_TRANSPARENT);
        var amenText = WatchUi.loadResource(Rez.Strings.text_amen) as String;
        dc.drawText(centerX, centerY * 0.45, Graphics.FONT_SYSTEM_LARGE, 
            amenText, 
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // "Chapelet terminé" sous le AMEN (remplace le ghost Gloire au Père)
        dc.setColor(COLOR_TEXT_MAIN, Graphics.COLOR_TRANSPARENT);
        var finishedText = WatchUi.loadResource(Rez.Strings.text_finished) as String;
        
        // On le descend à 0.85 pour qu'il soit bien sous le AMEN et loin de l'arc du haut
        drawWrappedText(dc, centerX, (centerY * 0.85).toNumber(), Graphics.FONT_SYSTEM_SMALL, 
            finishedText, 
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            
        // Croix plus bas 
        drawVectorCross(dc, centerX, (centerY * 1.55).toNumber());
    }
    
    private function drawVectorCross(dc as Dc, x as Number, y as Number) as Void {
        dc.setColor(COLOR_GOLD, Graphics.COLOR_TRANSPARENT);
        var size = 15; // Taille réduite
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
        // dy est la distance verticale par rapport au centre
        var dy = (y - (height / 2)).abs();
        var availableWidth = width;
        
        if (dy < radius) {
            // Pythagore dans le cercle : r² = x² + y²  => x = sqrt(r² - y²)
            // La corde (largeur dispo) est 2*x
            var halfChord = Math.sqrt(Math.pow(radius, 2) - Math.pow(dy, 2));
            availableWidth = 2 * halfChord;
        }
        
        // On prend 90% de la Corde (largeur réelle à cette hauteur) pour ne pas toucher les bords ronds
        var maxWidth = availableWidth * 0.90; 
        
        // Si le texte tient, on l'affiche direct
        if (dc.getTextWidthInPixels(text, font) <= maxWidth) {
            dc.drawText(x, y, font, text, attr);
            return dc.getFontHeight(font);
        }

        // Sinon on découpe
        var words = stringSplit(text, " ");
        var lines = [""];
        var currentLine = 0;

        for (var i = 0; i < words.size(); i++) {
            var word = words[i];
            var potentialLine = lines[currentLine] + (lines[currentLine].length() > 0 ? " " : "") + word;
            
            if (dc.getTextWidthInPixels(potentialLine, font) <= maxWidth) {
                lines[currentLine] = potentialLine;
            } else {
                // Si le mot seul est trop long, on le garde quand même (pas le choix)
                if (lines[currentLine].length() > 0) {
                    currentLine++;
                    lines.add(word);
                } else {
                     lines[currentLine] = word;
                }
            }
        }

        // Affichage des lignes centrées verticalement autour de Y
        var fontHeight = dc.getFontHeight(font);
        var totalHeight = lines.size() * fontHeight;
        var startY = y - (totalHeight / 2) + (fontHeight / 2);

        for (var i = 0; i < lines.size(); i++) {
            dc.drawText(x, startY + (i * fontHeight), font, lines[i], attr);
        }
        
        return totalHeight;
    }

    // Petit helper maison pour split car Toybox.String ne l'a pas forcément en simple
    private function stringSplit(str as String, delimiter as String) as Array<String> {
        var result = [] as Array<String>;
        var current = "";
        // Conversion basique, une vraie String.toCharArray() n'existe pas, on itère
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
