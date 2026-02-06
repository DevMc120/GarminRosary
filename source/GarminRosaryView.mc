import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Math;

class GarminRosaryView extends WatchUi.View {

    private var _model as RosaryModel;
    private var _currentState as Number = RosaryModel.STATE_CROSS;
    private var _screenWidth as Number = 240; 
    private var _screenHeight as Number = 240;
    private var _isRectangular as Boolean = false; 
    private var _isInstinct2 as Boolean = false; 

    private var _colorBg as Number = 0x001B3A;          
    private var _colorGold as Number = 0xFFD700;        
    private var _colorTextMain as Number = 0xFFFFFF;   
    private var _colorTextDim as Number = 0xA0A0A0;    
    private var _colorArcBg as Number = 0x111111;      
    private var _colorArcActive as Number = 0x66CCFF;  
    private var _colorOffWhite as Number = 0xDDDDDD;   

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
        _isRectangular = (_screenHeight > _screenWidth * 1.1); 
        
        if (_screenWidth <= 176 && _screenHeight <= 176) {
            _isInstinct2 = true;
            setupMonochromeColors();
        } else if (dc has :getColorDepth) {
            if (dc.getColorDepth() <= 2) { 
                 setupMonochromeColors();
            }
        }
    }
    
    private function setupMonochromeColors() as Void {
        _colorBg = Graphics.COLOR_BLACK; 
        _colorGold = Graphics.COLOR_WHITE; 
        _colorTextMain = Graphics.COLOR_WHITE; 
        _colorTextDim = Graphics.COLOR_WHITE; 
        _colorArcBg = Graphics.COLOR_BLACK; 
        _colorArcActive = Graphics.COLOR_WHITE;
        _colorOffWhite = Graphics.COLOR_WHITE;
    }

    function onShow() as Void {
        _model.loadState();
        _currentState = _model.getCurrentState();
    }

    function onUpdate(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var centerY = height / 2;
        
        if (_isRectangular) {
            centerY = (height * 0.52).toNumber();
        }
        

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
    
    private function drawTransitionScreen(dc as Dc, centerX as Number, centerY as Number) as Void {
        drawVectorCross(dc, centerX, (centerY * 0.45).toNumber());
        
        dc.setColor(_colorGold, Graphics.COLOR_TRANSPARENT);
        var nextMysteryName = getNextMysteryTypeName();
        drawWrappedText(dc, centerX, (centerY * 1.0).toNumber(), Graphics.FONT_SYSTEM_MEDIUM, 
            nextMysteryName, 
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        
    }
    
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
        var height = dc.getHeight();
        var isRectangular = (height > width * 1.1);
        
        var radius = (width / 2) - 8;
        var centerY = y;
        
        if (isRectangular) {
            radius = (width / 2) - 12; 
            centerY = (height * 0.45).toNumber(); 
        }
        
        if (_isInstinct2) {
            radius = (width / 2) - 13; 
        }
        
        var penWidth = 6;
        if (_isInstinct2) { penWidth = 1; } 
        
        dc.setPenWidth(penWidth);
        dc.setColor(_colorArcBg, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(x, centerY, radius, Graphics.ARC_CLOCKWISE, 90, 90); 

        var progress = _model.getProgress();
        if (progress > 0) {
            var angle = 90 - (progress * 360);
            dc.setColor(_colorArcActive, Graphics.COLOR_TRANSPARENT);
            dc.drawArc(x, centerY, radius, Graphics.ARC_CLOCKWISE, 90, angle.toNumber());
        }
        
        if (!_isInstinct2) {
             drawSeparators(dc, x, centerY, radius, penWidth);
        }
    }
    
    private function drawSeparators(dc as Dc, cx as Number, cy as Number, radius as Number, arcWidth as Number) as Void {
        dc.setColor(_colorBg, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        
        var markers = [] as Array<Number>;
        var total = 68.0; 
        
        if (_model.isFullRosary) {
            total = 187.0;
            markers = [7, 67, 127];
        } else {
            markers = [7, 19, 31, 43, 55];
        }
        
        for (var i = 0; i < markers.size(); i++) {
             var angleDeg = 90 - (markers[i] / total * 360);
             drawRadialTick(dc, cx, cy, radius, arcWidth, angleDeg);
        }
    }

    private function drawRadialTick(dc as Dc, cx as Number, cy as Number, radius as Number, width as Number, angleDeg as Float) as Void {
        var rad = angleDeg * Math.PI / 180.0;
        
        var cosA = Math.cos(rad);
        var sinA = Math.sin(rad);

        var innerR = radius - (width / 2); 
        var outerR = radius + (width / 2);

        var x1 = cx + innerR * cosA;
        var y1 = cy - innerR * sinA;
        var x2 = cx + outerR * cosA;
        var y2 = cy - outerR * sinA;
        
        dc.drawLine(x1, y1, x2, y2);
    }

    private function drawIntroScreen(dc as Dc, centerX as Number, centerY as Number) as Void {
        dc.setColor(_colorGold, Graphics.COLOR_TRANSPARENT);
        var titleFont = _isInstinct2 ? Graphics.FONT_XTINY : Graphics.FONT_TINY;
        var mysteryTitleY = _isInstinct2 ? (centerY * 0.70).toNumber() : (centerY * 0.45).toNumber();
        drawWrappedText(dc, centerX, mysteryTitleY, titleFont, 
            _model.getMysteryTypeName(), 
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(_colorTextMain, Graphics.COLOR_TRANSPARENT);
        var prayerName = getPrayerName(_currentState);

        if (_currentState == RosaryModel.STATE_CROSS && _model.beadInPhase == 0) {
            var crossY = _isInstinct2 ? (centerY * 1.15).toNumber() : centerY;
            drawVectorCross(dc, centerX, crossY);
        } else {
            var prayerY = centerY;
            var prayerFont = Graphics.FONT_SYSTEM_MEDIUM;
            
            if (_isRectangular) {
                prayerY = (_screenHeight * 0.55).toNumber(); 
                prayerFont = Graphics.FONT_SYSTEM_SMALL; 
            }
            
            dc.drawText(centerX, prayerY, prayerFont, 
                prayerName, 
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        dc.setColor(_colorTextDim, Graphics.COLOR_TRANSPARENT);
        var introText = WatchUi.loadResource(Rez.Strings.text_intro) as String;
        var introY = centerY * 1.55;
        
        if (_isRectangular) {
            introY = (_screenHeight * 0.72).toNumber(); 
        }
        
        dc.drawText(centerX, introY, Graphics.FONT_SYSTEM_XTINY, 
            introText, 
            Graphics.TEXT_JUSTIFY_CENTER);
    }
    //! Écran Dizaine
    private function drawDecadeScreen(dc as Dc, centerX as Number, centerY as Number) as Void {
        dc.setColor(_colorGold, Graphics.COLOR_TRANSPARENT);
        var mysteryTitle = _model.getCurrentMysteryTitle();
        var headerText = "";
        var titleY = 0;
        var titleHeight = 0;

        if (_model.phase == 6) {
            headerText = mysteryTitle;
            titleY = (centerY * 0.45).toNumber();
            titleHeight = drawWrappedText(dc, centerX, titleY, Graphics.FONT_TINY, 
                headerText, 
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                
        } else {
            var decadeNum = _model.getCurrentDecade();
            
            var titleFont = Graphics.FONT_TINY;
            if (_screenWidth < 220) {
                titleFont = Graphics.FONT_XTINY;
            }
            
            if (_isRectangular) {
                var combinedText = decadeNum.toString() + " - " + mysteryTitle;
                titleY = (_screenHeight * 0.18).toNumber(); 
                titleHeight = drawWrappedText(dc, centerX, titleY, Graphics.FONT_SYSTEM_XTINY, 
                    combinedText, 
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            } else if (_isInstinct2) {
                dc.setColor(_colorGold, Graphics.COLOR_TRANSPARENT);
                var combinedText = decadeNum.toString() + " - " + mysteryTitle;
                
                var leftX = (_screenWidth * 0.10).toNumber();
                
                var safeWidth = _screenWidth * 0.40; 
                
                var fontToUse = Graphics.FONT_XTINY;
                var textWidth = dc.getTextWidthInPixels(combinedText, fontToUse);
                
                if (textWidth <= safeWidth) {
                    titleY = (centerY * 0.70).toNumber(); 
                    titleHeight = dc.getFontHeight(fontToUse);
                    dc.drawText(leftX, titleY, fontToUse, 
                        combinedText, 
                        Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
                } else {
                    var words = stringSplit(combinedText, " ");
                    var line1 = "";
                    var line2 = "";
                    var i = 0;
                    
                    while (i < words.size()) {
                        var testLine = (line1.length() == 0) ? words[i] : line1 + " " + words[i];
                        if (dc.getTextWidthInPixels(testLine, fontToUse) <= safeWidth) {
                            line1 = testLine;
                            i++;
                        } else {
                            break;
                        }
                    }
                    
                    while (i < words.size()) {
                        line2 = (line2.length() == 0) ? words[i] : line2 + " " + words[i];
                        i++;
                    }
                    
                    var fontHeight = dc.getFontHeight(fontToUse);
                    
                    var line1Y = (centerY * 0.65).toNumber();
                    dc.drawText(leftX, line1Y, fontToUse, 
                        line1, 
                        Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
                    
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
                var maxWidth = (centerX * 1.6).toNumber(); 
                var textWidth = dc.getTextWidthInPixels(mysteryTitle, titleFont);
                var willWrap = textWidth > maxWidth;
                
                var numY = willWrap ? (centerY * 0.18).toNumber() : (centerY * 0.28).toNumber();
                
                dc.setColor(_colorGold, Graphics.COLOR_TRANSPARENT);
                dc.drawText(centerX, numY, Graphics.FONT_SYSTEM_SMALL, 
                    decadeNum.toString(), 
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                    
                titleY = willWrap ? (centerY * 0.48).toNumber() : (centerY * 0.52).toNumber();
                
                titleHeight = drawWrappedText(dc, centerX, titleY, titleFont, 
                    mysteryTitle, 
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }

        var fruit = _model.getCurrentFruit();
        if (!_isInstinct2 && fruit.length() > 0) {
            dc.setColor(_colorOffWhite, Graphics.COLOR_TRANSPARENT); 
            
            var fruitFont = Graphics.FONT_XTINY;
            
            if (_isRectangular) {
                fruitFont = Graphics.FONT_SYSTEM_XTINY;
            }
            
            var fontHeight = dc.getFontHeight(fruitFont);
            var titleBottom = titleY + (titleHeight / 2);
            
            var extraMargin = (_screenWidth < 220) ? 4 : 2;
            var defaultFruitY = (centerY * 0.76).toNumber(); 
            var minFruitTop = titleBottom + extraMargin;
            
            var fruitY = defaultFruitY;
            
            if (_isRectangular) {
                fruitY = (_screenHeight * 0.45).toNumber(); 
                minFruitTop = titleBottom + 3; 
            }
            
            if ((fruitY - (fontHeight / 2)) < minFruitTop) {
                 fruitY = minFruitTop + (fontHeight / 2);
            }
            
            drawWrappedText(dc, centerX, fruitY, fruitFont, 
                fruit, 
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        var beadNum = _model.getBeadInDecade();
        
        if (beadNum > 0) {
            dc.setColor(_colorTextMain, Graphics.COLOR_TRANSPARENT);
            
            var numberFont = (_screenWidth < 220) ? Graphics.FONT_NUMBER_MEDIUM : Graphics.FONT_NUMBER_HOT;
            var numberY = centerY * 1.25;
            
            if (_isRectangular) {
                numberFont = Graphics.FONT_NUMBER_MEDIUM; 
                numberY = (_screenHeight * 0.68).toNumber(); 
            }
            
            dc.drawText(centerX, numberY, numberFont, 
                beadNum.toString(), 
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            
            
        } else {
            dc.setColor(_colorTextMain, Graphics.COLOR_TRANSPARENT);
            var prayer = getPrayerName(_currentState);
            var font = (prayer.length() > 10) ? Graphics.FONT_SYSTEM_SMALL : Graphics.FONT_SYSTEM_MEDIUM;
            var prayerY = centerY * 1.25;
            
            if (_isRectangular) {
                font = Graphics.FONT_SYSTEM_XTINY; 
                prayerY = (_screenHeight * 0.68).toNumber(); 
            }
            
            dc.drawText(centerX, prayerY, font, 
                prayer, 
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }


        dc.setColor(_colorTextDim, Graphics.COLOR_TRANSPARENT);
        var typeText = "";
        if (_currentState == RosaryModel.STATE_HAIL_MARY) { typeText = WatchUi.loadResource(Rez.Strings.prayer_ave) as String; }
        else if (_currentState == RosaryModel.STATE_OUR_FATHER) { typeText = WatchUi.loadResource(Rez.Strings.prayer_pater) as String; }
        else if (_currentState == RosaryModel.STATE_GLORY) { typeText = WatchUi.loadResource(Rez.Strings.prayer_gloria) as String; }
        
        if (beadNum > 0) { 
             var typeTextY = centerY * 1.62;
             
             if (_isRectangular) {
                 typeTextY = (_screenHeight * 0.88).toNumber(); 
             } else if (_isInstinct2) {
                 typeTextY = (centerY * 1.50).toNumber(); 
             }
             
             dc.drawText(centerX, typeTextY, Graphics.FONT_SYSTEM_XTINY, 
                typeText, 
                Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

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
        
        if (_isRectangular) {
            finishedFont = Graphics.FONT_SYSTEM_TINY;
            crossY = (centerY * 1.35).toNumber(); 
        }
        
        drawWrappedText(dc, centerX, finishedY, finishedFont, 
            finishedText, 
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            
        drawVectorCross(dc, centerX, crossY);
    }
    
    private function drawVectorCross(dc as Dc, x as Number, y as Number) as Void {
        dc.setColor(_colorGold, Graphics.COLOR_TRANSPARENT);
        
        var screenWidth = dc.getWidth();
        var size = (screenWidth * 0.10).toNumber(); 
        var thickness = (size * 0.2).toNumber(); 
        
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

    private function drawWrappedText(dc as Dc, x as Number, y as Number, font as FontType, text as String, attr as Number) as Number {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var radius = width / 2;
        
        var dy = (y - (height / 2)).abs();
        var availableWidth = width;
        
        if (dy < radius) {
            var halfChord = Math.sqrt(Math.pow(radius, 2) - Math.pow(dy, 2));
            availableWidth = 2 * halfChord;
        }
        
        var maxWidth = availableWidth * 0.90; 
        
        if (_isInstinct2) {
            maxWidth = width * 0.40;
        } 
        
        if (dc.getTextWidthInPixels(text, font) <= maxWidth) {
            dc.drawText(x, y, font, text, attr);
            return dc.getFontHeight(font);
        }

        var words = stringSplit(text, " ");
        var lines = [] as Array<String>;
        
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
        var current = str;
        var length = delimiter.length();
        
        while (true) {
            var index = current.find(delimiter);
            
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

    function onHide() as Void {
        _model.saveState();
    }
}
