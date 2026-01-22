import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Math;

//! Vue principale
class GarminRosaryView extends WatchUi.View {

    private var _model as RosaryModel;
    private var _currentState as Number = RosaryModel.STATE_CROSS;
    private var _screenWidth as Number = 240; // Default, will be set in onLayout
    private var _screenHeight as Number = 240; // Default, will be set in onLayout
    private var _isRectangular as Boolean = false; // True for Venu Sq 2 and similar
    private var _isInstinct2 as Boolean = false; // True for Instinct 2 (monochrome + small screen)

    // Palette (Variables instead of Consts to allow color changing)
    private var _colorBg as Number = 0x001B3A;          // Bleu Nuit Marial
    private var _colorGold as Number = 0xFFD700;        // Or
    private var _colorTextMain as Number = 0xFFFFFF;   // Blanc pur
    private var _colorTextDim as Number = 0xA0A0A0;    // Gris clair pour le secondaire
    private var _colorArcBg as Number = 0x111111;      // Gris très foncé (presque noir) pour fond d'arc
    private var _colorArcActive as Number = 0x66CCFF;  // Bleu Céleste pour la progression
    private var _colorOffWhite as Number = 0xDDDDDD;   // Blanc cassé

    function initialize(model as RosaryModel) {
        View.initialize();
        _model = model;
    }

    function setCurrentState(state as Number) as Void {
        _currentState = state;
    }

    function onLayout(dc as Dc) as Void {
        _screenWidth = dc.getWidth();
        _screenHeight = dc.getHeight();
        _isRectangular = (_screenHeight > _screenWidth * 1.1); // Venu Sq 2: 320x360
        
        // Detect Instinct 2 by screen size (176x176 is unique to Instinct 2 series)
        // This is more reliable than getColorDepth() which may not work in simulators
        if (_screenWidth <= 176 && _screenHeight <= 176) {
            _isInstinct2 = true;
            setupMonochromeColors(); // Instinct 2 is monochrome
        } else if (dc has :getColorDepth) {
            // Fallback: Detect other monochrome devices by color depth
            if (dc.getColorDepth() <= 2) { 
                 setupMonochromeColors();
            }
        }
    }
    
    private function setupMonochromeColors() as Void {
        _colorBg = Graphics.COLOR_BLACK; // Fond Noir
        _colorGold = Graphics.COLOR_WHITE; // Or -> Blanc (Haut contraste)
        _colorTextMain = Graphics.COLOR_WHITE; // Texte Blanc
        _colorTextDim = Graphics.COLOR_WHITE; // Dimensions -> Blanc (pas de gris sur 1-bit)
        _colorArcBg = Graphics.COLOR_WHITE; // Arc fond -> Blanc (sera dessiné en trait fin ou pointillé si possible, sinon blanc)
        // Note: Sur un arc plein, blanc sur blanc ne marche pas.
        // On va tricher : Arc BG en NOIR (donc invisible) ou BLANC .
        // Si fond Noir, ArcBG doit être différent... 
        // Sur Instinct, COLOR_DK_GRAY existe parfois ou on utilise des patterns.
        // Simplification : Fond Arc = Noir (Invisible), Active = Blanc.
        _colorArcBg = Graphics.COLOR_BLACK; 
        
        _colorArcActive = Graphics.COLOR_WHITE;
        _colorOffWhite = Graphics.COLOR_WHITE;
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
        
        // On rectangular screens, adjust content center to use vertical space better
        if (_isRectangular) {
            centerY = (height * 0.52).toNumber();
        }
        
        // On Instinct 2, DON'T shift centerX - we'll handle overlap by moving title down
        // if (_isInstinct2) { centerX = ... } // REMOVED - bad strategy

        dc.setColor(_colorBg, _colorBg);


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
        // Croix dorée en haut (remontée pour laisser plus d'espace)
        drawVectorCross(dc, centerX, (centerY * 0.45).toNumber());
        
        // Nom du prochain Mystère (en or, gros)
        dc.setColor(_colorGold, Graphics.COLOR_TRANSPARENT);
        var nextMysteryName = getNextMysteryTypeName();
        drawWrappedText(dc, centerX, (centerY * 1.0).toNumber(), Graphics.FONT_SYSTEM_MEDIUM, 
            nextMysteryName, 
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        
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
        // Detect rectangular screens (like Venu Sq 2: 320x360)
        var height = dc.getHeight();
        var isRectangular = (height > width * 1.1);
        
        // Adjust arc radius and center for rectangular screens
        var radius = (width / 2) - 8;
        var centerY = y;
        
        if (isRectangular) {
            // On rectangular screens, use a smaller radius to fit width
            // and move center up to better use vertical space
            radius = (width / 2) - 12; // Slightly smaller to add margin
            centerY = (height * 0.45).toNumber(); // Move up from center
        }
        
        if (_isInstinct2) {
             radius = (width / 2) - 13; // Smaller radius to stay clear of text
        }
        
        var penWidth = 6;
        if (_isInstinct2) { penWidth = 1; } // Super thin arc specifically to avoid covering text
        
        // Fond de l'arc
        dc.setPenWidth(penWidth);
        dc.setColor(_colorArcBg, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(x, centerY, radius, Graphics.ARC_CLOCKWISE, 90, 90); 

        // Arc de progression
        var progress = _model.getProgress();
        if (progress > 0) {
            var angle = 90 - (progress * 360);
            dc.setColor(_colorArcActive, Graphics.COLOR_TRANSPARENT);
            dc.drawArc(x, centerY, radius, Graphics.ARC_CLOCKWISE, 90, angle.toNumber());
        }
        
        // Ajout des séparateurs (fins de dizaines)
        if (!_isInstinct2) {
             drawSeparators(dc, x, centerY, radius, penWidth);
        }
    }
    
    // Dessine des petites coupures dans l'arc pour marquer les étapes
    private function drawSeparators(dc as Dc, cx as Number, cy as Number, radius as Number, arcWidth as Number) as Void {
        dc.setColor(_colorBg, Graphics.COLOR_TRANSPARENT);
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
        dc.setColor(_colorGold, Graphics.COLOR_TRANSPARENT);
        var titleFont = _isInstinct2 ? Graphics.FONT_XTINY : Graphics.FONT_TINY;
        var mysteryTitleY = _isInstinct2 ? (centerY * 0.70).toNumber() : (centerY * 0.45).toNumber();
        drawWrappedText(dc, centerX, mysteryTitleY, titleFont, 
            _model.getMysteryTypeName(), 
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Nom de la prière
        dc.setColor(_colorTextMain, Graphics.COLOR_TRANSPARENT);
        var prayerName = getPrayerName(_currentState);

        if (_currentState == RosaryModel.STATE_CROSS && _model.beadInPhase == 0) {
            // État initial (Appartion) : Juste la croix dorée
            var crossY = _isInstinct2 ? (centerY * 1.15).toNumber() : centerY;
            drawVectorCross(dc, centerX, crossY);
        } else {
            // Premier grain ou autres prières : Texte centré blanc
            var prayerY = centerY;
            var prayerFont = Graphics.FONT_SYSTEM_MEDIUM;
            
            // On rectangular screens, lower the prayer text and use smaller font
            if (_isRectangular) {
                prayerY = (_screenHeight * 0.55).toNumber(); // 55% from top
                prayerFont = Graphics.FONT_SYSTEM_SMALL; // Smaller font on rectangular
            }
            
            dc.drawText(centerX, prayerY, prayerFont, 
                prayerName, 
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // Instruction
        dc.setColor(_colorTextDim, Graphics.COLOR_TRANSPARENT);
        var introText = WatchUi.loadResource(Rez.Strings.text_intro) as String;
        var introY = centerY * 1.55;
        
        // On rectangular screens, lower the intro text
        if (_isRectangular) {
            introY = (_screenHeight * 0.72).toNumber(); // 72% from top
        }
        
        dc.drawText(centerX, introY, Graphics.FONT_SYSTEM_XTINY, 
            introText, 
            Graphics.TEXT_JUSTIFY_CENTER);
    }
    //! Écran Dizaine
    private function drawDecadeScreen(dc as Dc, centerX as Number, centerY as Number) as Void {
        // Titre du Mystère avec numéro de dizaine
        dc.setColor(_colorGold, Graphics.COLOR_TRANSPARENT);
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
            
            // Responsive font selection based on screen size
            var titleFont = Graphics.FONT_TINY;
            if (_screenWidth < 220) {
                // Small screens (FR55): use smaller font for titles
                titleFont = Graphics.FONT_XTINY;
            }
            
            // On rectangular screens, combine number and title on one line
            if (_isRectangular) {
                // Format: "3 - Le Couronnement"
                var combinedText = decadeNum.toString() + " - " + mysteryTitle;
                titleY = (_screenHeight * 0.18).toNumber(); // Single line at top
                titleHeight = drawWrappedText(dc, centerX, titleY, Graphics.FONT_SYSTEM_XTINY, 
                    combinedText, 
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            } else if (_isInstinct2) {
                // INSTINCT 2: LEFT ALIGNED Layout (Avoid right side circle)
                // All text left-aligned with 40% max width to stay in safe left zone
                
                dc.setColor(_colorGold, Graphics.COLOR_TRANSPARENT);
                var combinedText = decadeNum.toString() + " - " + mysteryTitle;
                
                // LEFT side anchor (10% from left edge)
                var leftX = (_screenWidth * 0.10).toNumber();
                
                // Max width: 40% of screen (very strict to avoid circle)
                var safeWidth = _screenWidth * 0.40; 
                
                var fontToUse = Graphics.FONT_XTINY;
                var textWidth = dc.getTextWidthInPixels(combinedText, fontToUse);
                
                if (textWidth <= safeWidth) {
                    // Fits on 1 line! Draw left-aligned at Y=0.70 (lowered for Instinct 2)
                    titleY = (centerY * 0.70).toNumber(); 
                    titleHeight = dc.getFontHeight(fontToUse);
                    dc.drawText(leftX, titleY, fontToUse, 
                        combinedText, 
                        Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
                } else {
                    // Too long -> Smart Split: Fill Line 1 as much as possible
                    var words = stringSplit(combinedText, " ");
                    var line1 = "";
                    var line2 = "";
                    var i = 0;
                    
                    // Build Line 1 until it would overflow
                    while (i < words.size()) {
                        var testLine = (line1.length() == 0) ? words[i] : line1 + " " + words[i];
                        if (dc.getTextWidthInPixels(testLine, fontToUse) <= safeWidth) {
                            line1 = testLine;
                            i++;
                        } else {
                            break;
                        }
                    }
                    
                    // Rest goes to Line 2
                    while (i < words.size()) {
                        line2 = (line2.length() == 0) ? words[i] : line2 + " " + words[i];
                        i++;
                    }
                    
                    var fontHeight = dc.getFontHeight(fontToUse);
                    
                    // Line 1: Top left (Y=0.65) - lowered for Instinct 2
                    var line1Y = (centerY * 0.65).toNumber();
                    dc.drawText(leftX, line1Y, fontToUse, 
                        line1, 
                        Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
                    
                    // Line 2: Below line 1 (Y=0.83) - lowered for Instinct 2
                    if (line2.length() > 0) {
                        var line2Y = (centerY * 0.83).toNumber();
                        dc.drawText(leftX, line2Y, fontToUse, 
                            line2, 
                            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
                        titleHeight = (line2Y - line1Y) + fontHeight;
                        titleY = line1Y;
                    } else {
                        titleHeight = fontHeight;
                        titleY = line1Y;
                    }
                }
            } else {
                // Original layout for round screens
                // Calculer si le titre va tenir sur 1 ou 2 lignes
                var maxWidth = (centerX * 1.6).toNumber(); // Largeur max pour le texte
                var textWidth = dc.getTextWidthInPixels(mysteryTitle, titleFont);
                var willWrap = textWidth > maxWidth;
                
                // Position du numéro : plus bas si le titre est court (1 ligne)
                var numY = willWrap ? (centerY * 0.18).toNumber() : (centerY * 0.28).toNumber();
                
                // 1. Le Numéro (Petit, Doré)
                dc.setColor(_colorGold, Graphics.COLOR_TRANSPARENT);
                dc.drawText(centerX, numY, Graphics.FONT_SYSTEM_SMALL, 
                    decadeNum.toString(), 
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                    
                // 2. Le Titre (Position ajustée selon longueur)
                titleY = willWrap ? (centerY * 0.48).toNumber() : (centerY * 0.52).toNumber();
                
                titleHeight = drawWrappedText(dc, centerX, titleY, titleFont, 
                    mysteryTitle, 
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }

        //  Fruit du Mystère
        var fruit = _model.getCurrentFruit();
        if (!_isInstinct2 && fruit.length() > 0) {
            dc.setColor(_colorOffWhite, Graphics.COLOR_TRANSPARENT); 
            
            // Responsive fruit font selection
            var fruitFont = Graphics.FONT_XTINY;
            
            // On rectangular screens, use even smaller font for fruit
            if (_isRectangular) {
                fruitFont = Graphics.FONT_SYSTEM_XTINY;
            }
            
            // Calcul dynamique de la position Y
            var fontHeight = dc.getFontHeight(fruitFont);
            // Le bas du titre réel
            var titleBottom = titleY + (titleHeight / 2);
            
            // On small screens, add more margin between title and fruit
            var extraMargin = (_screenWidth < 220) ? 4 : 2;
            var defaultFruitY = (centerY * 0.76).toNumber(); 
            var minFruitTop = titleBottom + extraMargin;
            
            var fruitY = defaultFruitY;
            
            // On rectangular screens, fruit can be lower
            if (_isRectangular) {
                fruitY = (_screenHeight * 0.45).toNumber(); // 45% from top - compact with title
                minFruitTop = titleBottom + 3; // Smaller margin to compress
            }
            
            if ((fruitY - (fontHeight / 2)) < minFruitTop) {
                 fruitY = minFruitTop + (fontHeight / 2);
            }
            
            drawWrappedText(dc, centerX, fruitY, fruitFont, 
                fruit, 
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // Compteur de grains (Centre)
        var beadNum = _model.getBeadInDecade();
        
        if (beadNum > 0) {
            dc.setColor(_colorTextMain, Graphics.COLOR_TRANSPARENT);
            
            // Responsive number font: FONT_NUMBER_MEDIUM provides best balance on small screens
            var numberFont = (_screenWidth < 220) ? Graphics.FONT_NUMBER_MEDIUM : Graphics.FONT_NUMBER_HOT;
            var numberY = centerY * 1.25;
            
            // On rectangular screens, use smaller font and position lower
            if (_isRectangular) {
                numberFont = Graphics.FONT_NUMBER_MEDIUM; // Smaller on rectangular
                numberY = (_screenHeight * 0.68).toNumber(); // 68% from top (around 245px)
            }
            
            dc.drawText(centerX, numberY, numberFont, 
                beadNum.toString(), 
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            
            
        } else {
            // Notre Père ou Gloria (Texte)
            dc.setColor(_colorTextMain, Graphics.COLOR_TRANSPARENT);
            var prayer = getPrayerName(_currentState);
            var font = (prayer.length() > 10) ? Graphics.FONT_SYSTEM_SMALL : Graphics.FONT_SYSTEM_MEDIUM;
            var prayerY = centerY * 1.25;
            
            // On rectangular screens, use much smaller font and adjust position
            if (_isRectangular) {
                font = Graphics.FONT_SYSTEM_XTINY; // Much smaller on rectangular
                prayerY = (_screenHeight * 0.68).toNumber(); // Same as bead counter position
            }
            
            dc.drawText(centerX, prayerY, font, 
                prayer, 
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }


        // Type de grain (sous le chiffre)
        dc.setColor(_colorTextDim, Graphics.COLOR_TRANSPARENT);
        var typeText = "";
        if (_currentState == RosaryModel.STATE_HAIL_MARY) { typeText = WatchUi.loadResource(Rez.Strings.prayer_ave) as String; }
        else if (_currentState == RosaryModel.STATE_OUR_FATHER) { typeText = WatchUi.loadResource(Rez.Strings.prayer_pater) as String; }
        else if (_currentState == RosaryModel.STATE_GLORY) { typeText = WatchUi.loadResource(Rez.Strings.prayer_gloria) as String; }
        
        if (beadNum > 0) { 
             // Texte "Ave Maria" coll\u00e9 tout en bas (1.55 -> 1.62)
             var typeTextY = centerY * 1.62;
             
             // On rectangular screens, move much lower to use vertical space
             if (_isRectangular) {
                 typeTextY = (_screenHeight * 0.88).toNumber(); // 88% from top - optimal balance
             } else if (_isInstinct2) {
                 typeTextY = (centerY * 1.50).toNumber(); // Raise to 1.50 (was 1.64) - clearly above arc bottom
             }
             
             dc.drawText(centerX, typeTextY, Graphics.FONT_SYSTEM_XTINY, 
                typeText, 
                Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    //! Écran Final (AMEN)
    private function drawCompleteScreen(dc as Dc, centerX as Number, centerY as Number) as Void {
        dc.setColor(_colorGold, Graphics.COLOR_TRANSPARENT);
        var amenText = WatchUi.loadResource(Rez.Strings.text_amen) as String;
        var amenFont = _isInstinct2 ? Graphics.FONT_SYSTEM_MEDIUM : Graphics.FONT_SYSTEM_LARGE;
        
        dc.drawText(centerX, centerY * 0.45, amenFont, 
            amenText, 
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(_colorTextMain, Graphics.COLOR_TRANSPARENT);
        var finishedText = "";
        if (_model.isFullRosary) {
            finishedText = WatchUi.loadResource(Rez.Strings.text_finished_rosary) as String;
        } else {
            finishedText = WatchUi.loadResource(Rez.Strings.text_finished) as String;
        }
        
        var finishedY = (centerY * 0.85).toNumber();
        var crossY = (centerY * 1.55).toNumber();
        var finishedFont = Graphics.FONT_SYSTEM_SMALL;
        
        // Venu Sq 2 Specific Adjustments
        if (_isRectangular) {
            // 1. Text too big -> Use smaller font
            finishedFont = Graphics.FONT_SYSTEM_TINY; // Smaller than SMALL
            // 2. Cross too low -> Raise it up
            // On rectangular, the bottom is tighter. Move cross up.
            crossY = (centerY * 1.35).toNumber(); 
        }
        
        drawWrappedText(dc, centerX, finishedY, finishedFont, 
            finishedText, 
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            
        drawVectorCross(dc, centerX, crossY);
    }
    
    private function drawVectorCross(dc as Dc, x as Number, y as Number) as Void {
        dc.setColor(_colorGold, Graphics.COLOR_TRANSPARENT);
        
        // Make cross size proportional to screen width (10% of screen width)
        var screenWidth = dc.getWidth();
        var size = (screenWidth * 0.10).toNumber(); 
        var thickness = (size * 0.2).toNumber(); // 20% of cross size
        
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
        
        // INSTINCT 2: Force max width to 40% of screen (left half only)
        if (_isInstinct2) {
            maxWidth = width * 0.40;
        } 
        
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
