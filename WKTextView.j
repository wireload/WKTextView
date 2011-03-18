/*
 * WKTextView.j
 * WyzihatKit
 *
 * Created by Alexander Ljungberg, WireLoad LLC.
 *
 */

@import <AppKit/AppKit.j>
@import <Foundation/CPTimer.j>

@implementation _WKWebView : CPWebView

- (DOMWindow)DOMWindow
{
    var contentWindow = nil;
    try
    {
        contentWindow = [super DOMWindow];
    }
    catch (e)
    {
    //  Do nothing.  When the Web View is not added to the DOM, it booms.
    //  Just ignore the boom because WKTextView checks multiple times.
    }
    return contentWindow;
}

@end

WKTextCursorHeightFactor    = 0.2;
WKTextViewInnerPadding      = 4;
WKTextViewDefaultFont       = "Verdana";

_CancelEvent = function(ev) {
    if (!ev)
        ev = window.event;
    if (ev && ev.stopPropagation)
        ev.stopPropagation();
    else if (ev && ev.cancelBubble)
        ev.cancelBubble = true;
}

_EditorEvents = [
    'onmousedown',
    'onmouseup',
    'onkeypress',
    'onkeydown',
    'onkeyup'
]

/*!
    A closure editor based rich text editor widget.

    Beware of the load times. Wait for the load event.
*/
@implementation WKTextView : _WKWebView
{
    id              delegate @accessors;
    CPTimer         loadTimer;
    Object          editor;
    Object          _scrollDiv;
    BOOL            shouldFocusAfterAction;
    BOOL            suppressAutoFocus;
    BOOL            editable;
    BOOL            enabled;
    BOOL            autohidesScrollers @accessors;

    CPString        lastFont;
    CPString        lastColorString;
    CPColor         lastColor;
    CPDictionary    eventHandlerSwizzler;

    CPScroller      _verticalScroller;
    float           _verticalLineScroll;
    float           _verticalPageScroll;

    boolean         _cursorPlaced;

    boolean         _isTryingToBecomeFirstResponder;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        lastColor = [CPColor blackColor];

        _verticalPageScroll = 10;
        _verticalLineScroll = 10;

        autohidesScrollers = YES;

        [self setDrawsBackground:NO];
        [self setBackgroundColor:[CPColor whiteColor]];

        eventHandlerSwizzler = [[CPDictionary alloc] init];
        shouldFocusAfterAction = YES;
        [self setEditable: YES];
        [self setEnabled: YES];
        [self setScrollMode:CPWebViewScrollNative];
        [self setMainFrameURL:[[CPBundle bundleForClass:[self class]] pathForResource:"WKTextView/editor.html"]];

        _verticalScroller = [[CPScroller alloc] initWithFrame:CGRectMake(0.0, 0.0, [CPScroller scrollerWidth], MAX(CGRectGetHeight([self bounds]), [CPScroller scrollerWidth] + 1))];
        [_verticalScroller setAutoresizingMask:CPViewMinXMargin];
        [_verticalScroller setTarget:self];
        [_verticalScroller setAction:@selector(_verticalScrollerDidScroll:)];

        [self addSubview:_verticalScroller];
        [self _updateScrollbar];

        // Check if the document was loaded immediately. This could happen if we're loaded from
        // a file URL.
        [self checkLoad];
    }
    return self;
}

- (void)_startedLoading
{
    // If the frame reloads for whatever reason, the editor is gone.
    editor = nil;
    _cursorPlaced = NO;
    [super _startedLoading];
}

- (void)viewDidHide
{
    // Editor can't be used at all while hidden due to the iframe unloading.
    editor = nil;
    _cursorPlaced = NO;
}

- (void)viewDidUnhide
{
    if (editor === nil)
        [self checkLoad];
    else
        [self _actualizeEnabledState];
}

- (void)_finishedLoading
{
    [super _finishedLoading];
    [self checkLoad];
}

- (void)checkLoad
{
    // We can't load if hidden. Load checking will be resumed by viewDidUnhide later.
    if ([self isHiddenOrHasHiddenAncestor])
        return;

    // Is the editor ready?
    var maybeEditor = [self objectByEvaluatingJavaScriptFromString:"typeof(__closure_editor) != 'undefined' ? __closure_editor : null"];

    if (maybeEditor)
    {
        _scrollDiv = maybeEditor.__scroll_div;
        [self setEditor:maybeEditor];

        if (loadTimer)
        {
            [loadTimer invalidate];
            loadTimer = nil;
        }

        if (_html != nil)
            [self setHtmlValue:_html];

        if ([delegate respondsToSelector:@selector(textViewDidLoad:)])
            [delegate textViewDidLoad:self];

        return;
    }

    // If we still don't have an editor, check again later.
    if (!loadTimer || ![loadTimer isValid])
        loadTimer = [CPTimer scheduledTimerWithTimeInterval:0.1 target:self selector:"checkLoad" userInfo:nil repeats:NO];
}

- (BOOL)acceptsFirstResponder
{
    return (editor !== nil && [self isEditable] && [self isEnabled]);
}

- (BOOL)becomeFirstResponder
{
    [self _didBeginEditing];
    if (_cursorPlaced)
        editor.focus();
    else
    {
        editor.focusAndPlaceCursorAtStart();
        _cursorPlaced = YES;
    }
    return YES;
}

- (BOOL)resignFirstResponder
{
    window.focus();
    [self _didEndEditing];
    return YES;
}

/*!
    Sets whether or not the receiver text view can be edited.
*/
- (void)setEditable:(BOOL)shouldBeEditable
{
    editable = shouldBeEditable;
}

/*!
    Returns \c YES if the text view is currently editable by the user.
*/
- (BOOL)isEditable
{
    return editable;
}

/*!
    Sets whether or not the receiver text view is enabled.
*/
- (void)setEnabled:(BOOL)shouldBeEnabled
{
    if (enabled === shouldBeEnabled)
        return;

    enabled = shouldBeEnabled;

    [self _actualizeEnabledState];
}

- (void)_actualizeEnabledState
{
    if (editor)
    {
        var isEnabled = !editor.isUneditable();
        if (!isEnabled && enabled)
            editor.makeEditable();
        else if (isEnabled && !enabled)
            editor.makeUneditable();

        // When contentEditable is off we must disable wysihat event handlers
        // or they'll cause errors e.g. if a user clicks a disabled WKTextView.
        /*var t = editor;
        for(var i=0; i<_EditorEvents.length; i++) {
            var ev = _EditorEvents[i];
            if (!enabled && t[ev] !== _CancelEvent)
            {
                [eventHandlerSwizzler setObject:t[ev] forKey:ev];
                t[ev] = _CancelEvent;
            }
            else if (enabled && t[ev] === _CancelEvent)
            {
                t[ev] = [eventHandlerSwizzler objectForKey:ev];
            }
        }*/
    }
}

- (void)setAutohidesScrollers:(BOOL)aFlag
{
    if (autohidesScrollers === aFlag)
        return;

    autohidesScrollers = aFlag;

    [self _updateScrollbar];
}

/*!
    Returns \c YES if the text view is currently enabled.
*/
- (BOOL)isEnabled
{
    return enabled;
}

/*!
    Sets whether the editor should automatically take focus after an action
    method is invoked such as boldSelection or setFont. This is useful when
    binding to a toolbar.
*/
- (void)setShouldFocusAfterAction:(BOOL)aFlag
{
    shouldFocusAfterAction = aFlag;
}

- (BOOL)shouldFocusAfterAction
{
    return shouldFocusAfterAction;
}

- (BOOL)tryToBecomeFirstResponder
{
    if (_isTryingToBecomeFirstResponder)
        return YES;

    var win = [self window];
    if ([win firstResponder] === self)
        return YES;

    // We have to emulate select pieces of CPWindow's event handling
    // here since the iframe bypasses the regular event handling.
    var becameFirst = false;

    _isTryingToBecomeFirstResponder = YES;
    try
    {
        if ([self acceptsFirstResponder])
        {
            becameFirst = [win makeFirstResponder:self];
            if (becameFirst)
            {
                if (![win isKeyWindow])
                    [win makeKeyAndOrderFront:self];
                [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
            }
        }
    } finally
    {
        _isTryingToBecomeFirstResponder = NO;
    }

    return becameFirst;
}

- (void)setEditor:(Object)anEditor
{
    if (editor === anEditor)
        return;

    if (![self DOMWindow])
        return;

    editor = anEditor;
    _iframe.allowTransparency = true;

    [self DOMWindow].document.body.style.backgroundColor = 'transparent';

    // FIXME execCommand doesn't work well without the view having been focused
    // on at least once.
    // editor.focus();

    suppressAutoFocus = YES;
    [self setFontNameForSelection:@"Arial"];
    [self setFontSizeForSelection:14.0];
    suppressAutoFocus = NO;

    if (editor['WKTextView_Installed'] === undefined)
    {
        var win = [self DOMWindow],
            doc = win.document;

        var onmousedown = function(ev) {
            // If selection was successful, allow the event to continue propagate so that the
            // cursor is placed in the right spot.
            return [self tryToBecomeFirstResponder];
        }

        defaultKeydown = doc.onkeydown;
        var onkeydown = function(ev) {
            if (!ev)
                ev = window.event;

            var key = ev.keyCode;
            if (!key)
                key = ev.which;

            // Shift+Tab
            if (ev.shiftKey && key == 9)
            {
                setTimeout(function()
                {
                    [[self window] selectPreviousKeyView:self];
                    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
                }, 0.0);
                return false;
            }
            else
            {
                if (defaultKeydown)
                    return defaultKeydown(ev);
                return true;
            }
        };

        var onscroll = function(ev) {
            if (!ev)
                ev = window.event;

            [self _updateScrollbar];
            [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
            return true;
        }

        if (doc.addEventListener)
        {
            doc.addEventListener('mousedown', onmousedown, true);
            editor.addEventListener('keydown', onkeydown, true);
            doc.body.addEventListener('scroll', onscroll, true);
        }
        else if (doc.attachEvent)
        {
            doc.attachEvent('onmousedown', onmousedown);
            doc.attachEvent('onkeydown', onkeydown);
            doc.body.attachEvent('scroll', onscroll);
        }

        editor.__fieldChangeExternal = function() {
            [self _didChange];
            // The normal run loop doesn't react to iframe events, so force immediate processing.
            [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
        };
        editor.__selectionChangeExternal = function()
        {
            [self _cursorDidMove];

            // Workaround for Firefox not firing our iframe mousedown handler - we have
            // to do the first responder promotion here instead.
            [self tryToBecomeFirstResponder];

            // The normal run loop doesn't react to iframe events, so force immediate processing.
            [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
        };

        editor['WKTextView_Installed'] = true;
    }

    [self _actualizeEnabledState];
    [self _resizeWebFrame];
}

- (JSObject)editor
{
    // editor can never be active while hidden.
    return [self isHiddenOrHasHiddenAncestor] ? nil : editor;
}

- (void)_updateScrollbar
{
    if (!_verticalScroller)
        return;
    
    var scrollTop = 0,
        height = 1,
        frameHeight = CGRectGetHeight([self bounds]),
        scrollerWidth = CGRectGetWidth([_verticalScroller bounds]);

    if (_scrollDiv)
    {
        scrollTop = _scrollDiv.scrollTop;
        height = _scrollDiv.scrollHeight;
    }
    height = MAX(1, height);

    var difference = height - frameHeight,
        proportion = frameHeight / height;

    // Avoid showing the scrollbar when it would nearly fill the bar anyhow.
    // This avoids the bar flickering like crazy when animating the text field
    // growing or shrinking, as could otherwise happen due to the inner height
    // not having updated yet to fit to the outter height when the scroll bar
    // update happens.
    if (proportion > 0.99)
        proportion = 1;

    // Additionally, hide the scroller if there is no need to show one.
    [_verticalScroller setHidden:autohidesScrollers && proportion == 1];

    [_verticalScroller setFloatValue:scrollTop / difference];
    [_verticalScroller setKnobProportion:proportion];
    [_verticalScroller setFrame:CGRectMake(CGRectGetMaxX([self bounds])-scrollerWidth, 0, scrollerWidth, frameHeight)];
}

- (void)_verticalScrollerDidScroll:(CPScroller)aScroller
{
    if (!_scrollDiv)
        return; // Shouldn't happen. No editor means no scrollbar.

    // Based on CPScrollView _verticalScrollerDidScroll
    var scrollTop = _scrollDiv.scrollTop,
        height = _scrollDiv.scrollHeight,
        frameHeight = CGRectGetHeight([self bounds]),
        value = [aScroller floatValue];

    switch ([_verticalScroller hitPart])
    {
        case CPScrollerDecrementLine:   scrollTop -= _verticalLineScroll;
                                        break;

        case CPScrollerIncrementLine:   scrollTop += _verticalLineScroll;
                                        break;

        case CPScrollerDecrementPage:   scrollTop -= frameHeight - _verticalPageScroll;
                                        break;

        case CPScrollerIncrementPage:   scrollTop += frameHeight - _verticalPageScroll;
                                        break;

        case CPScrollerKnobSlot:
        case CPScrollerKnob:
                                        // We want integral bounds!
        default:                        scrollTop = ROUND(value * (height - frameHeight));
    }

    _scrollDiv.scrollTop = scrollTop;
}

- (void)_didChange
{
    // Prevent the did change from firing if the editor is not yet loaded
    if (![self editor])
        return;

    // When the text changes, the height of the content may change.
    [self _updateScrollbar];

    if ([delegate respondsToSelector:@selector(textViewDidChange:)])
    {
        [delegate textViewDidChange:self];
    }

}

- (void)_didBeginEditing
{
    if ([delegate respondsToSelector:@selector(textViewDidBeginEditing:)])
        [delegate textViewDidBeginEditing:self];
}

- (void)_didEndEditing
{
    if ([delegate respondsToSelector:@selector(textViewDidEndEditing:)])
        [delegate textViewDidEndEditing:self];
}

- (void)_cursorDidMove
{
    if (![self DOMWindow])
        return;

    if ([delegate respondsToSelector:@selector(textViewCursorDidMove:)])
    {
        [delegate textViewCursorDidMove:self];
    }
}

- (void)_resizeWebFrame
{
    if (editor && editor.getElement())
//        editor.setMinHeight(CGRectGetHeight([self bounds]) - (2+WKTextViewInnerPadding*2));
        editor.getElement().style.minHeight = (CGRectGetHeight([self bounds])-(2+WKTextViewInnerPadding*2)) + "px";
    [self _updateScrollbar];
}

- (void)_loadMainFrameURL
{
    [self _startedLoading];

    _ignoreLoadStart = YES;
    _ignoreLoadEnd = NO;

    _url = _mainFrameURL;
    _html = null;

    [self _load];
}

- (void)_addKeypressHandler:(Function)aFunction
{
    if ([self editor])
    {
        var doc = [self DOMWindow].document;
        if (doc.addEventListener)
        {
            doc.addEventListener('keypress', aFunction, true);
        }
        else if (doc.attachEvent)
        {
            doc.attachEvent('onkeypress',
                            function() { aFunction([self editor].event) });
            //This needs to be tested in IE. I have no idea if [self editor] will have an event
        }
    }
}

- (CPString)htmlValue
{
    if (![self editor])
        return _html;

    return [self editor].getCleanContents();
}

- (void)setHtmlValue:(CPString)html
{
    if ([self editor] != nil)
        editor.setHtml(false, html, false, false);
    else
        _html = html;

    _cursorPlaced = NO;
    [self _didChange];
}

- (void)_didPerformAction
{
    if (shouldFocusAfterAction && !suppressAutoFocus)
    {
        [self DOMWindow].focus();
        editor.focus();
    }
}

- (@action)clearText:(id)sender
{
    [self setHtmlValue:""];
    [self _didChange];
    [self _didPerformAction];
}

- (void)insertHtml:(CPString)html
{
    [CPException raise:CPUnsupportedMethodException reason:"not available with google-closure editor yet"];

    /*[self editor].insertHTML(html);
    [self _didChange];
    [self _didPerformAction];*/
}

- (@action)boldSelection:(id)sender
{
    editor.execCommand(editor.Command.BOLD, null);
    [self _didPerformAction];
}

- (@action)underlineSelection:(id)sender
{
    editor.execCommand(editor.Command.UNDERLINE, null);
    [self _didPerformAction];
}

- (@action)italicSelection:(id)sender
{
    editor.execCommand(editor.Command.ITALIC, null);
    [self _didPerformAction];
}

- (@action)strikethroughSelection:(id)sender
{
    editor.execCommand(editor.Command.STRIKE_THROUGH, null);
    [self _didPerformAction];
}

- (@action)alignSelectionLeft:(id)sender
{
    editor.execCommand(editor.Command.JUSTIFY_LEFT, null);
    [self _didPerformAction];
}

- (@action)alignSelectionRight:(id)sender
{
    editor.execCommand(editor.Command.JUSTIFY_RIGHT, null);
    [self _didPerformAction];
}

- (@action)alignSelectionCenter:(id)sender
{
    editor.execCommand(editor.Command.JUSTIFY_CENTER, null);
    [self _didPerformAction];
}

- (@action)alignSelectionFull:(id)sender
{
    editor.execCommand(editor.Command.JUSTIFY_FULL, null);
    [self _didPerformAction];
}

- (@action)linkSelection:(id)sender
{
    // TODO Show a sheet asking for a URL to link to.
    editor.execCommand(editor.Command.LINK, "http://www.wireload.net");
    [self _didPerformAction];
}

- (void)linkSelectionToURL:(CPString)aUrl
{
    var appWindow = editor.getAppWindow(),
        prompt = appWindow['prompt'];

    appWindow['prompt'] = function() {
      return aUrl;
    };

    editor.execCommand(editor.Command.LINK, null);
    appWindow['prompt'] = prompt;
    [self _didPerformAction];
}

- (void)unlinkSelection:(id)sender
{
    [self linkSelectionToURL:nil];
}

- (@action)insertOrderedList:(id)sender
{
    editor.execCommand(editor.Command.ORDERED_LIST, null);
    [self _didPerformAction];
}

- (@action)insertUnorderedList:(id)sender
{
    editor.execCommand(editor.Command.UNORDERED_LIST, null);
    [self _didPerformAction];
}

- (@action)insertImage:(id)sender
{
    // TODO Show a sheet asking for an image URL.
}

- (void)insertImageWithURL:(CPString)aUrl
{
    editor.execCommand(editor.Command.IMAGE, aUrl);
    [self _didPerformAction];
}

- (void)setFontNameForSelection:(CPString)aFont
{
    lastFont = aFont;
    editor.execCommand(editor.Command.FONT_FACE, aFont);
    [self _didPerformAction];
}

- (int)fontSizeRaw
{
    try {
        return editor.queryCommandValue(editor.Command.FONT_SIZE);
    } catch(e) {
        return "16px";
    }
}

- (int)fontSize
{
    // Strangely we get font sizes back in pixels.
    var size = parseInt([self fontSizeRaw]),
        sizeMap = { 10:1, 13:2, 16:3, 18:4, 24:5, 32:6, 48:7};
    if (size <= 7)
        return size;
    else if (size in sizeMap)
        return sizeMap[size];
    else
        return 3;
}

/*!
    Set the font size for the selected text. Size is specified
    as a number between 1-6 which corresponds to small through xx-large.
*/
- (void)setFontSizeForSelection:(int)aSize
{
    editor.execCommand(editor.Command.FONT_SIZE, aSize);
    [self _didPerformAction];
}

- (CPString)font
{
    try
    {
        var fontName = editor.queryCommandValue(editor.Command.FONT_FACE);
    } catch(e) {
        return lastFont;
    }

    // The font name may come through with quotes e.g. 'Apple Chancery'
    var format = /'(.*?)'/,
        r = fontName ? fontName.match(new RegExp(format)) : nil;

    if (r && r.length == 2)
        lastFont = r[1];
    else if (fontName)
        lastFont = fontName;

    return lastFont;
}

- (CPColor)color
{
    var colorString;
    try {
        colorString = editor.queryCommandValue(editor.Command.FONT_COLOR);
    } catch(e) {
        CPLog.warning(e);
    }
    // Avoid creating a new Color instance every time the cursor moves by reusing the last
    // instance.
    if (!colorString || colorString == lastColorString)
        return lastColor;
    lastColor = [[CPColor alloc] _initWithCSSString:colorString];
    lastColorString = colorString;
    return lastColor;
}

- (void)setColorForSelection:(CPColor)aColor
{
    editor.execCommand(editor.Command.FONT_COLOR, [aColor hexString]);
    [self _didPerformAction];
}
