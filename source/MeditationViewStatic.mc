import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class MeditationViewStatic extends WatchUi.View {

    private var _mysteryType as Number;
    private var _decade as Number;
    private var _screenWidth as Number = 240;
    private var _screenHeight as Number = 240;
    private var _isRectangular as Boolean = false;
    private var _isInstinct2 as Boolean = false;

    private var _colorBg as Number = 0x001B3A;
    private var _colorGold as Number = 0xFFD700;
    private var _colorTextMain as Number = 0xFFFFFF;
    private var _colorTextDim as Number = 0xA0A0A0;

    private var _scrollOffset as Number = 0;
    private var _totalLines as Number = 0;
    private var _visibleLines as Number = 5;

    function initialize(mysteryType as Number, decade as Number) {
        View.initialize();
        _mysteryType = mysteryType;
        _decade = decade;
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
        
        if (_screenHeight >= 280) {
            _visibleLines = 6;
        } else if (_screenHeight >= 240) {
            _visibleLines = 5;
        } else {
            _visibleLines = 4;
        }
    }

    private function setupMonochromeColors() as Void {
        _colorBg = Graphics.COLOR_BLACK;
        _colorGold = Graphics.COLOR_WHITE;
        _colorTextMain = Graphics.COLOR_WHITE;
        _colorTextDim = Graphics.COLOR_WHITE;
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(_colorBg, _colorBg);
        dc.clear();

        var centerX = _screenWidth / 2;

        var title = getMysteryTitle();
        var fruitLabel = WatchUi.loadResource(Rez.Strings.label_fruit) as String;
        var fruit = fruitLabel + " " + getMysteryFruit();
        var meditation = getMeditationText();

        // --- FONTS ---
        var titleFont = Graphics.FONT_TINY;
        var fruitFont = Graphics.FONT_XTINY;
        var meditFont = Graphics.FONT_XTINY;
        var hintFont = Graphics.FONT_XTINY;

        // --- LAYOUT CONSTANTS ---
        var PAD_TOP_ROUND = 25;
        var PAD_TOP_RECT = 5;
        var PAD_TOP_INSTINCT = 35;
        var PAD_BTM_ROUND = 15;
        var PAD_BTM_INSTINCT = 2;

        var topPadding = _isRectangular ? PAD_TOP_RECT : (_isInstinct2 ? PAD_TOP_INSTINCT : PAD_TOP_ROUND);
        var bottomPadding = _isInstinct2 ? PAD_BTM_INSTINCT : PAD_BTM_ROUND;

        // --- TITLE (sticky at top) ---
        var titleY = topPadding;
        var titleLineHeight = dc.getFontHeight(titleFont);
        var maxTitleWidth = (_screenWidth * 0.65).toNumber();
        var titleLines = wrapTextArray(dc, splitString(title, ' '), maxTitleWidth, titleFont);

        dc.setColor(_colorGold, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < titleLines.size(); i++) {
            dc.drawText(centerX, titleY + (i * titleLineHeight), titleFont, titleLines[i], Graphics.TEXT_JUSTIFY_CENTER);
        }
        var titleBlockHeight = titleLines.size() * titleLineHeight;

        // --- SCROLLABLE CONTENT ---
        var maxFruitWidth = (_screenWidth * 0.75).toNumber();
        var maxMeditWidth = (_screenWidth * 0.80).toNumber();
        var fruitLines = wrapTextArray(dc, splitString(fruit, ' '), maxFruitWidth, fruitFont);
        var meditLines = wrapTextArray(dc, splitString(meditation, ' '), maxMeditWidth, meditFont);

        var separatorIndex = fruitLines.size();
        _totalLines = fruitLines.size() + 1 + meditLines.size();

        var stdLineHeight = dc.getFontHeight(fruitFont);
        var textLineHeight = stdLineHeight + 4;
        var sepItemHeight = _isInstinct2 ? 8 : 10;

        var scrollableTopY = titleY + titleBlockHeight + 2;
        var hintY = _screenHeight - bottomPadding - dc.getFontHeight(hintFont) + 5;
        var scrollableBottomY = hintY - 5;

        // --- STICKY SEPARATOR ---
        var isSticky = (_scrollOffset > separatorIndex);
        var currentY = scrollableTopY;

        if (isSticky) {
            dc.setColor(_colorGold, Graphics.COLOR_TRANSPARENT);
            var lineY = scrollableTopY + (sepItemHeight / 2);
            dc.drawLine(centerX - 40, lineY, centerX + 40, lineY);
            currentY += sepItemHeight;
        }

        // --- DRAW SCROLLABLE ITEMS ---
        var idx = _scrollOffset;
        _visibleLines = 0;

        while (currentY < scrollableBottomY && idx < _totalLines) {
            var itemHeight = textLineHeight;

            if (idx == separatorIndex) {
                itemHeight = sepItemHeight;
                if (currentY + itemHeight <= scrollableBottomY + (itemHeight / 2)) {
                    dc.setColor(_colorGold, Graphics.COLOR_TRANSPARENT);
                    var lineY = currentY + (itemHeight / 2);
                    dc.drawLine(centerX - 40, lineY, centerX + 40, lineY);
                }
            } else if (idx < separatorIndex) {
                if (currentY + textLineHeight <= scrollableBottomY) {
                    dc.setColor(_colorTextDim, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(centerX, currentY, fruitFont, fruitLines[idx], Graphics.TEXT_JUSTIFY_CENTER);
                }
            } else {
                var mIdx = idx - (separatorIndex + 1);
                if (mIdx < meditLines.size() && currentY + textLineHeight <= scrollableBottomY) {
                    dc.setColor(_colorTextMain, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(centerX, currentY, meditFont, meditLines[mIdx], Graphics.TEXT_JUSTIFY_CENTER);
                }
            }

            currentY += itemHeight;
            if (currentY > scrollableBottomY) { break; }
            _visibleLines++;
            idx++;
        }

        // --- HINT ---
        dc.setColor(_colorTextDim, Graphics.COLOR_TRANSPARENT);
        var hint = WatchUi.loadResource(Rez.Strings.hint_tap_close) as String;

        if (_isInstinct2) {
            hint = WatchUi.loadResource(Rez.Strings.hint_back) as String;
        } else if (_totalLines > _visibleLines) {
            var canScrollUp = (_scrollOffset > 0);
            var canScrollDown = (_scrollOffset + _visibleLines < _totalLines);

            if (canScrollDown && canScrollUp) {
                hint = WatchUi.loadResource(Rez.Strings.hint_scroll) as String;
            } else if (canScrollDown) {
                hint = WatchUi.loadResource(Rez.Strings.hint_more) as String;
            } else if (canScrollUp) {
                hint = WatchUi.loadResource(Rez.Strings.hint_up) as String;
            }
        }
        dc.drawText(centerX, hintY, hintFont, hint, Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function wrapTextArray(dc as Dc, words as Array<String>, maxWidth as Number, font as FontType) as Array<String> {
        var lines = [] as Array<String>;
        var currentLine = "";

        for (var i = 0; i < words.size(); i++) {
            var testLine = currentLine.length() == 0 ? words[i] : currentLine + " " + words[i];
            var testWidth = dc.getTextWidthInPixels(testLine, font);

            if (testWidth > maxWidth && currentLine.length() > 0) {
                lines.add(currentLine);
                currentLine = words[i];
            } else {
                currentLine = testLine;
            }
        }
        if (currentLine.length() > 0) {
            lines.add(currentLine);
        }
        return lines;
    }

    function scrollDown() as Boolean {
        if (_scrollOffset + _visibleLines < _totalLines) {
            _scrollOffset++;
            WatchUi.requestUpdate();
            return true;
        }
        return false;
    }

    function scrollUp() as Boolean {
        if (_scrollOffset > 0) {
            _scrollOffset--;
            WatchUi.requestUpdate();
            return true;
        }
        return false;
    }

    private function getMysteryTitle() as String {
        if (_mysteryType == RosaryModel.MYSTERY_JOYFUL) {
            switch (_decade) {
                case 1: return WatchUi.loadResource(Rez.Strings.joyful_1_title) as String;
                case 2: return WatchUi.loadResource(Rez.Strings.joyful_2_title) as String;
                case 3: return WatchUi.loadResource(Rez.Strings.joyful_3_title) as String;
                case 4: return WatchUi.loadResource(Rez.Strings.joyful_4_title) as String;
                case 5: 
                    if (_screenWidth <= 208) {
                        return WatchUi.loadResource(Rez.Strings.joyful_5_title_medium) as String;
                    }
                    return WatchUi.loadResource(Rez.Strings.joyful_5_title) as String;
            }
        } else if (_mysteryType == RosaryModel.MYSTERY_LUMINOUS) {
            switch (_decade) {
                case 1: return WatchUi.loadResource(Rez.Strings.luminous_1_title) as String;
                case 2: return WatchUi.loadResource(Rez.Strings.luminous_2_title) as String;
                case 3: return WatchUi.loadResource(Rez.Strings.luminous_3_title) as String;
                case 4: return WatchUi.loadResource(Rez.Strings.luminous_4_title) as String;
                case 5: return WatchUi.loadResource(Rez.Strings.luminous_5_title) as String;
            }
        } else if (_mysteryType == RosaryModel.MYSTERY_SORROWFUL) {
            switch (_decade) {
                case 1: return WatchUi.loadResource(Rez.Strings.sorrowful_1_title) as String;
                case 2: return WatchUi.loadResource(Rez.Strings.sorrowful_2_title) as String;
                case 3: 
                    if (_screenWidth <= 208) {
                        return WatchUi.loadResource(Rez.Strings.sorrowful_3_title_medium) as String;
                    }
                    return WatchUi.loadResource(Rez.Strings.sorrowful_3_title) as String;
                case 4: return WatchUi.loadResource(Rez.Strings.sorrowful_4_title) as String;
                case 5: return WatchUi.loadResource(Rez.Strings.sorrowful_5_title) as String;
            }
        } else if (_mysteryType == RosaryModel.MYSTERY_GLORIOUS) {
            switch (_decade) {
                case 1: 
                    if (_screenWidth <= 208) {
                        return WatchUi.loadResource(Rez.Strings.glorious_1_title_medium) as String;
                    }
                    return WatchUi.loadResource(Rez.Strings.glorious_1_title_long) as String;
                case 2: 
                    if (_screenWidth <= 208) {
                        return WatchUi.loadResource(Rez.Strings.glorious_2_title_medium) as String;
                    }
                    return WatchUi.loadResource(Rez.Strings.glorious_2_title_long) as String;
                case 3: return WatchUi.loadResource(Rez.Strings.glorious_3_title) as String;
                case 4: return WatchUi.loadResource(Rez.Strings.glorious_4_title) as String;
                case 5: 
                    if (_screenWidth <= 208) {
                        return WatchUi.loadResource(Rez.Strings.glorious_5_title_medium) as String;
                    }
                    return WatchUi.loadResource(Rez.Strings.glorious_5_title) as String;
            }
        }
        return "Mystère";
    }

    private function getMysteryFruit() as String {
        if (_mysteryType == RosaryModel.MYSTERY_JOYFUL) {
            switch (_decade) {
                case 1: return WatchUi.loadResource(Rez.Strings.joyful_1_fruit) as String;
                case 2: return WatchUi.loadResource(Rez.Strings.joyful_2_fruit) as String;
                case 3: return WatchUi.loadResource(Rez.Strings.joyful_3_fruit) as String;
                case 4: return WatchUi.loadResource(Rez.Strings.joyful_4_fruit) as String;
                case 5: return WatchUi.loadResource(Rez.Strings.joyful_5_fruit) as String;
            }
        } else if (_mysteryType == RosaryModel.MYSTERY_LUMINOUS) {
            switch (_decade) {
                case 1: return WatchUi.loadResource(Rez.Strings.luminous_1_fruit) as String;
                case 2: return WatchUi.loadResource(Rez.Strings.luminous_2_fruit) as String;
                case 3: return WatchUi.loadResource(Rez.Strings.luminous_3_fruit) as String;
                case 4: return WatchUi.loadResource(Rez.Strings.luminous_4_fruit) as String;
                case 5: return WatchUi.loadResource(Rez.Strings.luminous_5_fruit) as String;
            }
        } else if (_mysteryType == RosaryModel.MYSTERY_SORROWFUL) {
            switch (_decade) {
                case 1: return WatchUi.loadResource(Rez.Strings.sorrowful_1_fruit) as String;
                case 2: return WatchUi.loadResource(Rez.Strings.sorrowful_2_fruit) as String;
                case 3: return WatchUi.loadResource(Rez.Strings.sorrowful_3_fruit) as String;
                case 4: return WatchUi.loadResource(Rez.Strings.sorrowful_4_fruit) as String;
                case 5: return WatchUi.loadResource(Rez.Strings.sorrowful_5_fruit) as String;
            }
        } else if (_mysteryType == RosaryModel.MYSTERY_GLORIOUS) {
            switch (_decade) {
                case 1: return WatchUi.loadResource(Rez.Strings.glorious_1_fruit) as String;
                case 2: return WatchUi.loadResource(Rez.Strings.glorious_2_fruit) as String;
                case 3: return WatchUi.loadResource(Rez.Strings.glorious_3_fruit) as String;
                case 4: return WatchUi.loadResource(Rez.Strings.glorious_4_fruit) as String;
                case 5: return WatchUi.loadResource(Rez.Strings.glorious_5_fruit) as String;
            }
        }
        return "";
    }

    private function getMeditationText() as String {
        var resourceId = getMeditationResourceId();
        if (resourceId != null) {
            return WatchUi.loadResource(resourceId as ResourceId) as String;
        }
        return "Texte à venir...";
    }

    private function getMeditationResourceId() as ResourceId? {
        if (_mysteryType == RosaryModel.MYSTERY_JOYFUL) {
            switch (_decade) {
                case 1: return Rez.Strings.joyful_1_meditation;
                case 2: return Rez.Strings.joyful_2_meditation;
                case 3: return Rez.Strings.joyful_3_meditation;
                case 4: return Rez.Strings.joyful_4_meditation;
                case 5: return Rez.Strings.joyful_5_meditation;
            }
        } else if (_mysteryType == RosaryModel.MYSTERY_SORROWFUL) {
            switch (_decade) {
                case 1: return Rez.Strings.sorrowful_1_meditation;
                case 2: return Rez.Strings.sorrowful_2_meditation;
                case 3: return Rez.Strings.sorrowful_3_meditation;
                case 4: return Rez.Strings.sorrowful_4_meditation;
                case 5: return Rez.Strings.sorrowful_5_meditation;
            }
        } else if (_mysteryType == RosaryModel.MYSTERY_GLORIOUS) {
            switch (_decade) {
                case 1: return Rez.Strings.glorious_1_meditation;
                case 2: return Rez.Strings.glorious_2_meditation;
                case 3: return Rez.Strings.glorious_3_meditation;
                case 4: return Rez.Strings.glorious_4_meditation;
                case 5: return Rez.Strings.glorious_5_meditation;
            }
        } else if (_mysteryType == RosaryModel.MYSTERY_LUMINOUS) {
            switch (_decade) {
                case 1: return Rez.Strings.luminous_1_meditation;
                case 2: return Rez.Strings.luminous_2_meditation;
                case 3: return Rez.Strings.luminous_3_meditation;
                case 4: return Rez.Strings.luminous_4_meditation;
                case 5: return Rez.Strings.luminous_5_meditation;
            }
        }
        return null;
    }

    private function drawWrappedText(dc as Dc, text as String, x as Number, y as Number, maxWidth as Number, font as FontType) as Void {
        var words = splitString(text, ' ');
        var lines = [] as Array<String>;
        var currentLine = "";

        for (var i = 0; i < words.size(); i++) {
            var testLine = currentLine.length() == 0 ? words[i] : currentLine + " " + words[i];
            var testWidth = dc.getTextWidthInPixels(testLine, font);
            
            if (testWidth > maxWidth && currentLine.length() > 0) {
                lines.add(currentLine);
                currentLine = words[i];
            } else {
                currentLine = testLine;
            }
        }
        if (currentLine.length() > 0) {
            lines.add(currentLine);
        }

        _totalLines = lines.size();
        var lineHeight = dc.getFontHeight(font) + 2;
        
        for (var i = 0; i < _visibleLines && (i + _scrollOffset) < lines.size(); i++) {
            dc.drawText(x, y + (i * lineHeight), font, lines[i + _scrollOffset], Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    private function splitString(str as String, separator as Char) as Array<String> {
        var result = [] as Array<String>;
        var current = str;
        var delim = separator.toString();
        var length = delim.length();
        
        while (true) {
            var index = current.find(delim);
            
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
}
