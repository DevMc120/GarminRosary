import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class MeditationView extends WatchUi.View {

    private var _model as RosaryModel;
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

    // Cache
    private var _cachedTitleLines as Array<String> = [];
    private var _cachedFruitRenderLines as Array<String> = [];
    private var _cachedMeditRenderLines as Array<String> = [];
    private var _cachedTitleBlockHeight as Number = 0;

    // Layout Constants
    private const TITLE_MAX_WIDTH_RATIO = 0.65;
    private const FRUIT_MAX_WIDTH_RATIO = 0.75;
    private const MEDIT_MAX_WIDTH_RATIO = 0.80;
    
    // Padding Logic
    private const PAD_TOP_ROUND = 25;
    private const PAD_BTM_ROUND = 15;
    private const PAD_TOP_RECT = 5;
    private const PAD_TOP_INSTINCT = 35;
    private const PAD_BTM_INSTINCT = 2;

    function initialize(model as RosaryModel) {
        View.initialize();
        _model = model;
    }

    function getModel() as RosaryModel {
        return _model;
    }

    function onShow() as Void {
        var phase = _model.phase;
        if (phase < 1 || phase > 5) {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        }
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
            _visibleLines = 5;
        } else if (_screenHeight >= 240) {
            _visibleLines = 4;
        } else {
            _visibleLines = 3;
        }

        // --- CACHE CALCULATIONS (Performance) ---
        // Load data once
        var titleLongId = getMeditationTitleResourceId(_model.mysteryType, _model.getCurrentDecade());
        var title = (titleLongId != null) ? WatchUi.loadResource(titleLongId) as String : _model.getCurrentMysteryTitle();
        var fruitLongId = getMeditationFruitResourceId(_model.mysteryType, _model.getCurrentDecade());
        var fruit = (fruitLongId != null) ? WatchUi.loadResource(fruitLongId) as String : _model.getCurrentFruit();
        var meditation = getMeditationText();

        // Fonts
        var titleFont = Graphics.FONT_TINY; 
            // Note: In onUpdate we set this. Logic was: 
            // _isInstinct2 ? Graphics.FONT_SMALL : Graphics.FONT_MEDIUM (Wait, check onUpdate)
            // onUpdate: var titleFont = Graphics.FONT_TINY; (It was hardcoded to TINY in 90-140 view!)
            // I should match onUpdate exactly.
            // onUpdate lines 100-103:
            // var titleFont = Graphics.FONT_TINY; 
            // var fruitFont = Graphics.FONT_XTINY;
            // var meditFont = Graphics.FONT_XTINY;
            
        var fruitFont = Graphics.FONT_XTINY;
        var meditFont = Graphics.FONT_XTINY;

        // Title
        var maxTitleWidth = (_screenWidth * TITLE_MAX_WIDTH_RATIO).toNumber();
        var titleLines = splitString(title, ' ');
        // NOTE: wrappedText logic requires DC. 
        _cachedTitleLines = wrapText(dc, titleLines, maxTitleWidth, titleFont);
        _cachedTitleBlockHeight = _cachedTitleLines.size() * dc.getFontHeight(titleFont);
        
        // Fruit
        var maxFruitWidth = (_screenWidth * FRUIT_MAX_WIDTH_RATIO).toNumber();
        var fruitLabel = WatchUi.loadResource(Rez.Strings.label_fruit) as String;
        _cachedFruitRenderLines = wrapText(dc, splitString(fruitLabel + " " + fruit, ' '), maxFruitWidth, fruitFont);
        
        // Meditation
        var maxMeditationWidth = (_screenWidth * MEDIT_MAX_WIDTH_RATIO).toNumber();
        _cachedMeditRenderLines = wrapText(dc, splitString(meditation, ' '), maxMeditationWidth, meditFont);
        
        // Total Lines
        _totalLines = _cachedFruitRenderLines.size() + 1 + _cachedMeditRenderLines.size();
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

        // --- DONNEES (CACHED) ---
        // On récupère juste les fonts pour le padding/dessin
        var titleFont = Graphics.FONT_TINY; 
        var fruitFont = Graphics.FONT_XTINY;
        var meditFont = Graphics.FONT_XTINY;
        var hintFont = Graphics.FONT_XTINY;

        var titleLineHeight = dc.getFontHeight(titleFont);
        
        // --- LAYOUT ---
        var topPadding = _isRectangular ? PAD_TOP_RECT : (_isInstinct2 ? PAD_TOP_INSTINCT : PAD_TOP_ROUND); 
        var titleY = topPadding;
        
        dc.setColor(_colorGold, Graphics.COLOR_TRANSPARENT);
        // USE CACHE
        for (var i = 0; i < _cachedTitleLines.size(); i++) {
            dc.drawText(centerX, titleY + (i * titleLineHeight), titleFont, _cachedTitleLines[i], Graphics.TEXT_JUSTIFY_CENTER);
        }
        var titleBlockHeight = _cachedTitleBlockHeight;

        
        // USE CACHE
        var fruitRenderLines = _cachedFruitRenderLines;
        var meditRenderLines = _cachedMeditRenderLines;
        
        // _totalLines is already set in onLayout (and cached)

        
        var stdLineHeight = dc.getFontHeight(fruitFont);
        var textLineHeight = stdLineHeight + 4;
        
        var sepItemHeight = _isInstinct2 ? 8 : 10;
        
        var scrollableTopBaseY = titleY + titleBlockHeight + 2; 
        
        var bottomPadding = _isInstinct2 ? PAD_BTM_INSTINCT : PAD_BTM_ROUND;
        var hintY = _screenHeight - bottomPadding - dc.getFontHeight(hintFont) + 5; 
        var scrollableBottomY = hintY - 5;
        
        // -- LOGIQUE STICKY --
        // sticky si on a dépassé le séparateur (fruit.size())
        var separatorLimitIndex = fruitRenderLines.size();
        var isSticky = (_scrollOffset > separatorLimitIndex);
        
        var currentY = scrollableTopBaseY;
        
        if (isSticky) {
            dc.setColor(_colorGold, Graphics.COLOR_TRANSPARENT);
            var lineY = scrollableTopBaseY + (sepItemHeight / 2); 
            dc.drawLine(centerX - 40, lineY, centerX + 40, lineY);
            
            currentY += sepItemHeight; 
        }

        var idx = _scrollOffset;
        _visibleLines = 0; 
        
        while (currentY < scrollableBottomY && idx < _totalLines) {
            var itemHeight = textLineHeight; 
            
            if (idx == separatorLimitIndex) {
                itemHeight = sepItemHeight; 
                
                if (currentY + itemHeight <= scrollableBottomY + (itemHeight/2)) {
                     dc.setColor(_colorGold, Graphics.COLOR_TRANSPARENT);
                     var lineY = currentY + (itemHeight / 2);
                     dc.drawLine(centerX - 40, lineY, centerX + 40, lineY);
                }
            } else if (idx < separatorLimitIndex) {
                if (currentY + textLineHeight <= scrollableBottomY) {
                    dc.setColor(_colorTextDim, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(centerX, currentY, fruitFont, fruitRenderLines[idx], Graphics.TEXT_JUSTIFY_CENTER);
                }
            } else {
                var mIdx = idx - (separatorLimitIndex + 1);
                if (mIdx < meditRenderLines.size()) {
                    if (currentY + textLineHeight <= scrollableBottomY) {
                        dc.setColor(_colorTextMain, Graphics.COLOR_TRANSPARENT);
                        dc.drawText(centerX, currentY, meditFont, meditRenderLines[mIdx], Graphics.TEXT_JUSTIFY_CENTER);
                    }
                }
            }
            
            currentY += itemHeight;
            
            if (currentY > scrollableBottomY) {
                break;
            }
            
            _visibleLines++; 
            idx++;
        }

        dc.setColor(_colorTextDim, Graphics.COLOR_TRANSPARENT);
        var hint = WatchUi.loadResource(Rez.Strings.hint_tap_close) as String;
        var showArrowUp = false;
        var showArrowDown = false;

        if (_isInstinct2) {
            hint = WatchUi.loadResource(Rez.Strings.hint_back) as String;
        } else if (_totalLines > _visibleLines) {
            var canScrollUp = (_scrollOffset > 0);
            var canScrollDown = (_scrollOffset + _visibleLines < _totalLines);
            
            if (canScrollDown && canScrollUp) { 
                hint = WatchUi.loadResource(Rez.Strings.hint_scroll) as String; 
                showArrowUp = true; 
                showArrowDown = true;
            } else if (canScrollDown) { 
                hint = WatchUi.loadResource(Rez.Strings.hint_more) as String; 
                showArrowDown = true;
            } else if (canScrollUp) { 
                hint = WatchUi.loadResource(Rez.Strings.hint_up) as String; 
                showArrowUp = true;
            }
        }
        
        var textWidth = dc.getTextWidthInPixels(hint, hintFont);
        var arrowBlockWidth = 0;
        var arrowSpacing = 10; 
        var arrowInnerSpacing = 12; 
        var arrowWidth = 8;
        
        if (showArrowUp || showArrowDown) {
             arrowBlockWidth = arrowSpacing + arrowWidth;
             if (showArrowUp && showArrowDown) {
                 arrowBlockWidth += arrowInnerSpacing + arrowWidth;
             }
        }
        
        var totalWidth = textWidth + arrowBlockWidth;
        var startX = centerX - (totalWidth / 2);
        
        dc.drawText(startX, hintY, hintFont, hint, Graphics.TEXT_JUSTIFY_LEFT);
        
        if (showArrowUp || showArrowDown) {
            var arrowY = hintY + (dc.getFontHeight(hintFont) / 2);
            var currentArrowX = startX + textWidth + arrowSpacing + (arrowWidth / 2); 
            
            if (showArrowUp) {
                drawTriangle(dc, currentArrowX, arrowY, true);
                currentArrowX += arrowWidth + arrowInnerSpacing;
            }
            if (showArrowDown) {
                drawTriangle(dc, currentArrowX, arrowY, false);
            }
        }
    }

    private function wrapText(dc as Dc, words as Array<String>, maxWidth as Number, font as FontType) as Array<String> {
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

    private function drawTriangle(dc as Dc, x as Number, centerY as Number, pointingUp as Boolean) as Void {
        var halfSize = 4;
        
        var pt1 = [x - halfSize, centerY + (pointingUp ? halfSize : -halfSize)];
        var pt2 = [x + halfSize, centerY + (pointingUp ? halfSize : -halfSize)];
        var pt3 = [x, centerY + (pointingUp ? -halfSize : halfSize)];
        
        dc.fillPolygon([pt1, pt2, pt3]);
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

    private function getMeditationText() as String {
        var mysteryType = _model.mysteryType;
        var decade = _model.getCurrentDecade();
        
        var resourceId = getMeditationResourceId(mysteryType, decade);
        if (resourceId != null) {
            return WatchUi.loadResource(resourceId as ResourceId) as String;
        }
        return "Texte à venir...";
    }

    private function getMeditationResourceId(mysteryType as Number, decade as Number) as ResourceId? {
        if (mysteryType == RosaryModel.MYSTERY_JOYFUL) {
            switch (decade) {
                case 1: return Rez.Strings.joyful_1_meditation;
                case 2: return Rez.Strings.joyful_2_meditation;
                case 3: return Rez.Strings.joyful_3_meditation;
                case 4: return Rez.Strings.joyful_4_meditation;
                case 5: return Rez.Strings.joyful_5_meditation;
            }
        }
        else if (mysteryType == RosaryModel.MYSTERY_SORROWFUL) {
            switch (decade) {
                case 1: return Rez.Strings.sorrowful_1_meditation;
                case 2: return Rez.Strings.sorrowful_2_meditation;
                case 3: return Rez.Strings.sorrowful_3_meditation;
                case 4: return Rez.Strings.sorrowful_4_meditation;
                case 5: return Rez.Strings.sorrowful_5_meditation;
            }
        }
        else if (mysteryType == RosaryModel.MYSTERY_GLORIOUS) {
            switch (decade) {
                case 1: return Rez.Strings.glorious_1_meditation;
                case 2: return Rez.Strings.glorious_2_meditation;
                case 3: return Rez.Strings.glorious_3_meditation;
                case 4: return Rez.Strings.glorious_4_meditation;
                case 5: return Rez.Strings.glorious_5_meditation;
            }
        }
        else if (mysteryType == RosaryModel.MYSTERY_LUMINOUS) {
            switch (decade) {
                case 1: return Rez.Strings.luminous_1_meditation;
                case 2: return Rez.Strings.luminous_2_meditation;
                case 3: return Rez.Strings.luminous_3_meditation;
                case 4: return Rez.Strings.luminous_4_meditation;
                case 5: return Rez.Strings.luminous_5_meditation;
            }
        }
        return null;
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

    private function getMeditationFruitResourceId(mysteryType as Number, decade as Number) as ResourceId? {
        if (mysteryType == RosaryModel.MYSTERY_JOYFUL) {
            switch (decade) {
                case 1: return Rez.Strings.joyful_1_fruit_long;
                case 2: return Rez.Strings.joyful_2_fruit_long;
                case 3: return Rez.Strings.joyful_3_fruit_long;
                case 4: return Rez.Strings.joyful_4_fruit_long;
                case 5: return Rez.Strings.joyful_5_fruit_long;
            }
        }
        else if (mysteryType == RosaryModel.MYSTERY_SORROWFUL) {
            switch (decade) {
                case 1: return Rez.Strings.sorrowful_1_fruit_long;
                case 2: return Rez.Strings.sorrowful_2_fruit_long;
                case 3: return Rez.Strings.sorrowful_3_fruit_long;
                case 4: return Rez.Strings.sorrowful_4_fruit_long;
                case 5: return Rez.Strings.sorrowful_5_fruit_long;
            }
        }
        else if (mysteryType == RosaryModel.MYSTERY_GLORIOUS) {
            switch (decade) {
                case 1: return Rez.Strings.glorious_1_fruit_long;
                case 2: return Rez.Strings.glorious_2_fruit_long;
                case 3: return Rez.Strings.glorious_3_fruit_long;
                case 4: return Rez.Strings.glorious_4_fruit_long;
                case 5: return Rez.Strings.glorious_5_fruit_long;
            }
        }
        else if (mysteryType == RosaryModel.MYSTERY_LUMINOUS) {
            switch (decade) {
                case 1: return Rez.Strings.luminous_1_fruit_long;
                case 2: return Rez.Strings.luminous_2_fruit_long;
                case 3: return Rez.Strings.luminous_3_fruit_long;
                case 4: return Rez.Strings.luminous_4_fruit_long;
                case 5: return Rez.Strings.luminous_5_fruit_long;
            }
        }
        return null;
    }

    private function getMeditationTitleResourceId(mysteryType as Number, decade as Number) as ResourceId? {
        var useShort = (_screenWidth <= 240);

        if (mysteryType == RosaryModel.MYSTERY_JOYFUL) {
            switch (decade) {
                case 1: return useShort ? Rez.Strings.joyful_1_title_short : Rez.Strings.joyful_1_title_long;
                case 2: return useShort ? Rez.Strings.joyful_2_title_short : Rez.Strings.joyful_2_title_long;
                case 3: return useShort ? Rez.Strings.joyful_3_title_short : Rez.Strings.joyful_3_title_long;
                case 4: return useShort ? Rez.Strings.joyful_4_title_short : Rez.Strings.joyful_4_title_long;
                case 5: return useShort ? Rez.Strings.joyful_5_title_short : Rez.Strings.joyful_5_title_long;
            }
        }
        else if (mysteryType == RosaryModel.MYSTERY_SORROWFUL) {
            switch (decade) {
                case 1: return useShort ? Rez.Strings.sorrowful_1_title_short : Rez.Strings.sorrowful_1_title_long;
                case 2: return useShort ? Rez.Strings.sorrowful_2_title_short : Rez.Strings.sorrowful_2_title_long;
                case 3: return useShort ? Rez.Strings.sorrowful_3_title_short : Rez.Strings.sorrowful_3_title_long;
                case 4: return useShort ? Rez.Strings.sorrowful_4_title_short : Rez.Strings.sorrowful_4_title_long;
                case 5: return useShort ? Rez.Strings.sorrowful_5_title_short : Rez.Strings.sorrowful_5_title_long;
            }
        }
        else if (mysteryType == RosaryModel.MYSTERY_GLORIOUS) {
             switch (decade) {
                case 1: return useShort ? Rez.Strings.glorious_1_title_short : Rez.Strings.glorious_1_title_long;
                case 2: return useShort ? Rez.Strings.glorious_2_title_short : Rez.Strings.glorious_2_title_long;
                case 3: return useShort ? Rez.Strings.glorious_3_title_short : Rez.Strings.glorious_3_title_long;
                case 4: return useShort ? Rez.Strings.glorious_4_title_short : Rez.Strings.glorious_4_title_long;
                case 5: return useShort ? Rez.Strings.glorious_5_title_short : Rez.Strings.glorious_5_title_long;
             }
        }
        else if (mysteryType == RosaryModel.MYSTERY_LUMINOUS) {
            switch (decade) {
                case 1: return useShort ? Rez.Strings.luminous_1_title_short : Rez.Strings.luminous_1_title_long;
                case 2: return useShort ? Rez.Strings.luminous_2_title_short : Rez.Strings.luminous_2_title_long;
                case 3: return useShort ? Rez.Strings.luminous_3_title_short : Rez.Strings.luminous_3_title_long;
                case 4: return useShort ? Rez.Strings.luminous_4_title_short : Rez.Strings.luminous_4_title_long;
                case 5: return useShort ? Rez.Strings.luminous_5_title_short : Rez.Strings.luminous_5_title_long;
            }
        }
        return null;
    }
}
