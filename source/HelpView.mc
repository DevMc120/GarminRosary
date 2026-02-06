import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class HelpView extends WatchUi.View {

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
    private var _cachedRenderLines as Array<String> = [];
    private var _cachedTitleLines as Array<String> = [];
    private var _cachedTitleBlockHeight as Number = 0;

    // Layout Constants
    
    // Padding Logic
    private const PAD_TOP_ROUND = 25;
    private const PAD_BTM_ROUND = 15;
    private const PAD_TOP_RECT = 5;
    private const PAD_TOP_INSTINCT = 35;
    private const PAD_BTM_INSTINCT = 2;

    function initialize() {
        View.initialize();
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
        
        // Lines visible
        if (_screenHeight >= 280) {
            _visibleLines = 6;
        } else if (_screenHeight >= 240) {
            _visibleLines = 5;
        } else {
            _visibleLines = 4;
        }

        // --- CACHE CALCULATIONS ---
        var title = WatchUi.loadResource(Rez.Strings.menu_help) as String;
        var content = WatchUi.loadResource(Rez.Strings.help_text) as String;

        // Fonts
        var titleFont = _isInstinct2 ? Graphics.FONT_TINY : Graphics.FONT_MEDIUM;
        var textFont = _isInstinct2 ? Graphics.FONT_XTINY : Graphics.FONT_TINY;

        // Title
        var ratio = _isRectangular ? 0.85 : 0.65;
        if (_isInstinct2) { ratio = 0.75; }
        
        var maxTitleWidth = (_screenWidth * ratio).toNumber();
        var titleLines = splitString(title, ' ');
        _cachedTitleLines = wrapText(dc, titleLines, maxTitleWidth, titleFont);
        _cachedTitleBlockHeight = _cachedTitleLines.size() * dc.getFontHeight(titleFont);
        
        // Content
        var textRatio = _isRectangular ? 0.85 : 0.75;
        if (_isInstinct2) { textRatio = 0.80; } 
        
        var maxWidth = (_screenWidth * textRatio).toNumber();
        _cachedRenderLines = wrapContent(dc, content, maxWidth, textFont);
        
        _totalLines = _cachedRenderLines.size();
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

        // Fonts
        var titleFont = _isInstinct2 ? Graphics.FONT_TINY : Graphics.FONT_MEDIUM;
        var textFont = _isInstinct2 ? Graphics.FONT_XTINY : Graphics.FONT_TINY;
        var hintFont = Graphics.FONT_XTINY;

        var titleLineHeight = dc.getFontHeight(titleFont);
        
        // --- LAYOUT ---
        var topPadding = _isRectangular ? PAD_TOP_RECT : (_isInstinct2 ? PAD_TOP_INSTINCT : PAD_TOP_ROUND); 
        var titleY = topPadding;
        
        dc.setColor(_colorGold, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < _cachedTitleLines.size(); i++) {
            dc.drawText(centerX, titleY + (i * titleLineHeight), titleFont, _cachedTitleLines[i], Graphics.TEXT_JUSTIFY_CENTER);
        }
        var titleBlockHeight = _cachedTitleBlockHeight;

        var scrollableTopBaseY = titleY + titleBlockHeight + 5; 
        
        var bottomPadding = _isInstinct2 ? PAD_BTM_INSTINCT : PAD_BTM_ROUND;
        var hintY = _screenHeight - bottomPadding - dc.getFontHeight(hintFont) + 5; 
        var scrollableBottomY = hintY - 5;
        
        var currentY = scrollableTopBaseY;
        var idx = _scrollOffset;
        var linesDrawn = 0;
        
        var textLineHeight = dc.getFontHeight(textFont);

        // Draw Content
        dc.setColor(_colorTextMain, Graphics.COLOR_TRANSPARENT);
        while (idx < _cachedRenderLines.size()) {
            if (currentY + textLineHeight <= scrollableBottomY) {
                 var line = _cachedRenderLines[idx];
                 if (line.length() > 0 && line.substring(0, 1).equals("[")) {
                     dc.setColor(_colorGold, Graphics.COLOR_TRANSPARENT);
                 } else {
                     dc.setColor(_colorTextMain, Graphics.COLOR_TRANSPARENT);
                 }
                 
                 dc.drawText(centerX, currentY, textFont, line, Graphics.TEXT_JUSTIFY_CENTER);
            }
            
            currentY += textLineHeight;
            if (currentY > scrollableBottomY) {
                break;
            }
            linesDrawn++;
            idx++;
        }

        drawScrollHints(dc, hintY, hintFont);
    }
    
    private function drawScrollHints(dc as Dc, hintY as Number, hintFont as FontType) as Void {
        dc.setColor(_colorTextDim, Graphics.COLOR_TRANSPARENT);
        var hint = WatchUi.loadResource(Rez.Strings.hint_back) as String; 
        // Draw arrows if scrollable
        dc.setColor(_colorGold, Graphics.COLOR_TRANSPARENT);
        
        if (_scrollOffset > 0) {
            // Draw UP arrow at top center
            dc.fillPolygon([
                [_screenWidth / 2, 5],
                [_screenWidth / 2 - 5, 10],
                [_screenWidth / 2 + 5, 10]
            ]);
        }
        
        if (_scrollOffset + _visibleLines < _totalLines) {
            // Draw DOWN arrow at bottom center
            dc.fillPolygon([
                [_screenWidth / 2, _screenHeight - 5],
                [_screenWidth / 2 - 5, _screenHeight - 10],
                [_screenWidth / 2 + 5, _screenHeight - 10]
            ]);
        }
        if (_isInstinct2) { hint = WatchUi.loadResource(Rez.Strings.hint_back) as String; }

        var centerX = _screenWidth / 2;
        dc.drawText(centerX, hintY, hintFont, hint, Graphics.TEXT_JUSTIFY_CENTER);
        
    }
    
    
    private function wrapContent(dc as Dc, text as String, maxWidth as Number, font as FontType) as Array<String> {
        var paragraphs = splitString(text, '\n');
        var finalLines = [] as Array<String>;
        
        for (var i = 0; i < paragraphs.size(); i++) {
            var words = splitString(paragraphs[i], ' ');
            var wrapped = wrapText(dc, words, maxWidth, font);
            finalLines.addAll(wrapped);
        }
        return finalLines;
    }

    private function wrapText(dc as Dc, words as Array<String>, maxWidth as Number, font as FontType) as Array<String> {
        var lines = [] as Array<String>;
        var currentLine = "";

        for (var i = 0; i < words.size(); i++) {
            var val = words[i];
            
            var testLine = currentLine.length() == 0 ? val : currentLine + " " + val;
            var testWidth = dc.getTextWidthInPixels(testLine, font);
            
            if (testWidth > maxWidth && currentLine.length() > 0) {
                lines.add(currentLine);
                currentLine = val;
            } else {
                currentLine = testLine;
            }
        }
        if (currentLine.length() > 0) {
            lines.add(currentLine);
        }
        return lines;
    }

    private function splitString(str as String, delimiter as Char) as Array<String> {
        var result = [] as Array<String>;
        var current = "";
        var chars = str.toCharArray();
        
        for (var i = 0; i < chars.size(); i++) {
            if (chars[i] == delimiter) {
                result.add(current);
                current = "";
            } else {
                current = current + chars[i];
            }
        }
        result.add(current);
        return result;
    }
    
    // Scroll Control
    function scrollUp() as Void {
        if (_scrollOffset > 0) {
            _scrollOffset -= 1;
            WatchUi.requestUpdate();
        }
    }

    function scrollDown() as Void {
        if (_scrollOffset + _visibleLines < _totalLines + 2) { 
             _scrollOffset += 1;
             WatchUi.requestUpdate();
        }
    }
}
