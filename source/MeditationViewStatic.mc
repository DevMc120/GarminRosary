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
        var fruit = getMysteryFruit();
        var meditation = getMeditationText();

        var titleY = _isRectangular ? 5 : (_isInstinct2 ? 25 : 10);
        var fruitY = titleY + 30;
        var meditationY = fruitY + 20;

        dc.setColor(_colorGold, Graphics.COLOR_TRANSPARENT);
        var titleFont = _isInstinct2 ? Graphics.FONT_SMALL : Graphics.FONT_MEDIUM;
        dc.drawText(centerX, titleY, titleFont, title, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(_colorTextMain, Graphics.COLOR_TRANSPARENT);
        var fruitFont = _isInstinct2 ? Graphics.FONT_XTINY : Graphics.FONT_SMALL;
        var fruitLabel = WatchUi.loadResource(Rez.Strings.label_fruit) as String;
        dc.drawText(centerX, fruitY, fruitFont, fruitLabel + " " + fruit, Graphics.TEXT_JUSTIFY_CENTER);
        if (!_isInstinct2) {
            dc.setColor(_colorTextDim, Graphics.COLOR_TRANSPARENT);
            var meditFont = Graphics.FONT_TINY;
            var maxWidth = _screenWidth - 40;
            drawWrappedText(dc, meditation, centerX, meditationY, maxWidth, meditFont);
        }

        var bottomY = _screenHeight - (_isInstinct2 ? 20 : 30);
        dc.setColor(_colorTextDim, Graphics.COLOR_TRANSPARENT);
        var hintFont = Graphics.FONT_XTINY;
        
        var hint;
        if (_isInstinct2) {
            hint = WatchUi.loadResource(Rez.Strings.hint_back) as String;
        } else if (_totalLines > _visibleLines) {
            var strTapClose = WatchUi.loadResource(Rez.Strings.hint_tap_close) as String;
            if (_scrollOffset > 0 && _scrollOffset + _visibleLines < _totalLines) {
                var strScroll = WatchUi.loadResource(Rez.Strings.hint_scroll) as String;
                hint = "↑↓ " + strScroll + " | " + strTapClose;
            } else if (_scrollOffset == 0) {
                var strMore = WatchUi.loadResource(Rez.Strings.hint_more) as String;
                hint = "↓ " + strMore + " | " + strTapClose;
            } else {
                var strBack = WatchUi.loadResource(Rez.Strings.hint_back) as String;
                hint = "↑ " + strBack + " | " + strTapClose;
            }
        } else {
            hint = WatchUi.loadResource(Rez.Strings.hint_close) as String;
        }
        dc.drawText(centerX, bottomY, hintFont, hint, Graphics.TEXT_JUSTIFY_CENTER);
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
