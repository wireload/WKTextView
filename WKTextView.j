/*
 * WKTextView.j
 * WyzihatKit
 *
 * Created by Alexander Ljungberg, WireLoad LLC.
 *
 */

WKTextCursorHeightFactor = 0.2;
WKTextViewDefaultFont = "Verdana";

_CancelEvent = function(ev) {
    if (!ev)
        ev = window.event;
    if (ev && ev.stopPropagation)
        ev.stopPropagation();
    else
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
    A WYSIHAT based rich text editor widget.

    Beware of the load times. Wait for the load event.
*/
@implementation WKTextView : CPWebView
{
    id          delegate @accessors;
    CPTimer     loadTimer;
    JSObject    editor;
    BOOL        shouldFocusAfterAction;
    BOOL        suppressAutoFocus;
    BOOL        editable;
    BOOL        enabled;
    CPString    lastFont;
    CPDictionary    eventHandlerSwizzler;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        eventHandlerSwizzler = [[CPDictionary alloc] init];
        shouldFocusAfterAction = YES;
        [self setEditable: YES];
        [self setEnabled: YES];
        [self setScrollMode:CPWebViewScrollAppKit];
        [self setMainFrameURL:[[CPBundle mainBundle] pathForResource:"WKTextView/editor.html"]];
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
    [super _startedLoading];
}

- (void)_finishedLoading
{
    [super _finishedLoading];
    [self checkLoad];
}

- (void)checkLoad
{
    // Is the editor ready?
    var maybeEditor = [self objectByEvaluatingJavaScriptFromString:"typeof(__wysihat_editor) != 'undefined' ? __wysihat_editor : null"];
    if (maybeEditor)
    {
        [self setEditor:maybeEditor];
        if (loadTimer)
        {
            [loadTimer invalidate];
            loadTimer = nil;
         }

        if ([delegate respondsToSelector:@selector(textViewDidLoad:)])
        {
            [delegate textViewDidLoad:self];
        }
    }
    else
    {
        if (!loadTimer)
            loadTimer = [CPTimer scheduledTimerWithTimeInterval:0.1 target:self selector:"checkLoad" userInfo:nil repeats:YES];
    }
}

- (BOOL)acceptsFirstResponder
{
    return (editor !== nil && [self isEditable] && [self isEnabled]);
}

- (BOOL)becomeFirstResponder
{
    editor.focus();
    return YES;
}

- (BOOL)resignFirstResponder
{
    window.focus();
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
    enabled = shouldBeEnabled;
    if (editor) {
        editor.contentEditable = enabled ? 'true' : 'false';
        // When designMode is off we must disable wysihat event handlers
        // or they'll cause errors e.g. if a user clicks a disabled WKTextView.
        var t = editor;
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
        }
    }
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

- (void)setEditor:anEditor
{
    if (editor === anEditor)
        return;
    
    if (![self DOMWindow])
        return;

    editor = anEditor;
    _iframe.allowTransparency = true;
    _iframe.scrolling = "no";

    [self DOMWindow].document.body.style.padding = '0';
    [self DOMWindow].document.body.style.backgroundColor = 'transparent';

    [self DOMWindow].document.body.style.margin = '0';
    // Without this line Safari may show an inner scrollbar.
    [self DOMWindow].document.body.style.overflow = 'hidden';

    // Disable automatic resizing - we'll handle this manually in _resizeWebFrame.
    [_frameView setAutoresizingMask:0];

    // FIXME execCommand doesn't work well without the view having been focused
    // on at least once.
    // editor.focus();

    suppressAutoFocus = YES;
    [self setFontNameForSelection:WKTextViewDefaultFont];
    suppressAutoFocus = NO;

    if (editor['WKTextView_Installed'] === undefined)
    {
        var doc = [self DOMWindow].document;

        var onmousedown = function(ev) {
            if (!ev)
                ev = window.event;
            var win = [self window];
            if ([win firstResponder] === self)
                return YES;
            // We have to emulate select pieces of CPWindow's event handling
            // here since the iframe bypasses the regular event handling.
            var becameFirst = false;
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
            // If selection was successful, allow the event to continue propagate so that the
            // cursor is placed in the right spot.
            return becameFirst;
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

        if (doc.addEventListener)
        {
            doc.addEventListener('mousedown', onmousedown, true);
            doc.addEventListener('keydown', onkeydown, true);
        }
        else if(doc.attachEvent)
        {
            doc.attachEvent('onmousedown', onmousedown);
            doc.attachEvent('onkeydown', onkeydown);
        }

        editor.observe("field:change", function() {
            [[CPRunLoop currentRunLoop] performSelector:"_didChange" target:self argument:nil order:0 modes:[CPDefaultRunLoopMode]];
            // The normal run loop doesn't react to iframe events, so force immediate processing.
            [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
        });
        editor.observe("selection:change", function() {
            [[CPRunLoop currentRunLoop] performSelector:"_cursorDidMove" target:self argument:nil order:0 modes:[CPDefaultRunLoopMode]];
            // The normal run loop doesn't react to iframe events, so force immediate processing.
            [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
        });

        editor['WKTextView_Installed'] = true;
    }

    [self _resizeWebFrame];
    [self _cursorDidMove];
    [self _updateScrollers];

    [self setEnabled:enabled];
}

- (JSObject)editor
{
    return editor;
}

- (void)_didChange
{
    // When the text changes, the height of the content may change.
    [self _resizeWebFrame];
    [self _cursorDidMove];
    [self _updateScrollers];

    if ([delegate respondsToSelector:@selector(textViewDidChange:)])
    {
        [delegate textViewDidChange:self];
    }

}

+ (INT)_countCharacters: aNode
{
    if (aNode.nodeType == 3)
    {
        return aNode.length;
    }
    else
    {
        var r=0;
        for (var c=aNode.firstChild; c != null; c = c.nextSibling)
        {
            r += [WKTextView _countCharacters:c];
        }
        return r;
    }
}

- (void)_cursorDidMove
{
    //[self DOMWindow].scrollTo(0, 0);
    /*
        It's possible to get the exact cursor position by inserting a div with a known
        id and gettings its offset before removing it again. Unfortunately this causes
        a ton of bugs like selections being lost, text paragraphs being reflowed and
        spaces appearing and sticking in Opera. We use an estimate instead based on the
        current span the cursor is in.
    */
    if(![self DOMWindow])
        return;

    var selection = [self DOMWindow].getSelection(),
        n = selection.getNode();
    if (n)
    {
        var top = n.offsetTop,
            height = n.offsetHeight,
            cursorHeight = [self bounds].size.height * WKTextCursorHeightFactor,
            position = selection.getRangeAt(0).startOffset,
            characters = [WKTextView _countCharacters:n],
            advance = 0;

        if (characters > 0)
            advance = position / characters;

        //console.log("range.startOffset: "+editor.selection.getRange().startOffset+" range.endOffset: "+editor.selection.getRange().endOffset);
        //console.log("top: "+top+" height:"+height+" position: "+position+" characters:"+ characters + " advance: "+advance);

        var offset = FLOOR(top + advance * height),
            scrollTop = MAX(0, offset-cursorHeight),
            scollHeight = 2*cursorHeight;
        //console.log("scrollTop: "+scrollTop+"scrollHeight: "+scollHeight);
        [_frameView scrollRectToVisible:CGRectMake(0,offset-cursorHeight,1,2*cursorHeight)];
        [self _updateScrollers];
    }

    if ([delegate respondsToSelector:@selector(textViewCursorDidMove:)])
    {
        [delegate textViewCursorDidMove:self];
    }
}

- (void)_updateScrollers
{
    [_scrollView setNeedsDisplay:YES];
}

- (BOOL)_resizeWebFrame
{
    // We override because we don't care about the content height of the iframe but
    // rather the content height of the editor's iframe.

    // By default just match the iframe to available size.
    var width = [_scrollView bounds].size.width,
        desiredHeight = [self _setWidthAndCalculateHeight:width],
        vscroller = [_scrollView verticalScroller];

    // If the desired height will result in a vertical scrollbar we
    // have to do it over again with the scrollbar in mind.
    if (desiredHeight > [_scrollView bounds].size.height)
        width -= [vscroller bounds].size.width;

    var height = [self _setWidthAndCalculateHeight:width];

    // Never make the iframe any shorter than the total available height.
    height = MAX([self bounds].size.height, height);
    _iframe.setAttribute("height", height);
    [_frameView setFrameSize:CGSizeMake(width, height)];
}

- (int)_setWidthAndCalculateHeight: (int)width
{
    var height = [self bounds].size.height,
        naturalHeight = height;

    _iframe.setAttribute("width", width);

    if (_scrollMode == CPWebViewScrollAppKit && editor !== nil && [self DOMWindow])
    {
        var body = [self DOMWindow].document.body;

        // This needs to be before the height calculation so that the right height for the current
        // width can be calculated.
        body.style.width = width+"px";

        // By default we keep the content div one view height taller than its natural content. This
        // has two advantages: the text doesn't momentarily scroll up when you enter a new row until
        // we have adjusted the size, and you can click anywhere to edit.

        editor.style.height = 'auto';
        naturalHeight = editor.scrollHeight;
        editor.style.height = naturalHeight+height+'px';
        //console.log("height: "+naturalHeight);
    }

    return naturalHeight;
}

- (void)_loadMainFrameURL
{
    // Exactly like super, minus
    // [self _setScrollMode:CPWebViewScrollNative];
    [self _startedLoading];

    _ignoreLoadStart = YES;
    _ignoreLoadEnd = NO;

    _url = _mainFrameURL;
    _html = null;

    [self _load];
}

- (void)_addKeypressHandler:(Function)aFunction
{

    if([self editor]){
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
    return [self editor].innerHTML;
}

- (void)setHtmlValue:(CPString)html
{
    [self editor].innerHTML = html;
    [self _didChange];
}

- (CPString)textValue
{
    return [self editor].content();
}

- (void)setTextValue:(CPString)content
{
    [self editor].setContent(content);
    [self _didChange];
}

- (void)_didPerformAction
{
    if (shouldFocusAfterAction && !suppressAutoFocus) {
        [self DOMWindow].focus();
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
    [self editor].insertHTML(html);
    [self _didChange];
    [self _didPerformAction];
}

- (@action)boldSelection:(id)sender
{
    [self editor].boldSelection();
    [self _didPerformAction];
}

- (@action)underlineSelection:(id)sender
{
    [self editor].underlineSelection();
    [self _didPerformAction];
}

- (@action)italicSelection:(id)sender
{
    [self editor].italicSelection();
    [self _didPerformAction];
}

- (@action)strikethroughSelection:(id)sender
{
    [self editor].strikethroughSelection();
    [self _didPerformAction];
}

- (@action)alignSelectionLeft:(id)sender
{
    [self editor].alignSelection('left');
    [self _didPerformAction];
}

- (@action)alignSelectionRight:(id)sender
{
    [self editor].alignSelection('right');
    [self _didPerformAction];
}

- (@action)alignSelectionCenter:(id)sender
{
    [self editor].alignSelection('center');
    [self _didPerformAction];
}

- (@action)alignSelectionFull:(id)sender
{
    [self editor].alignSelection('full');
    [self _didPerformAction];
}

- (@action)linkSelection:(id)sender
{
    // TODO Show a sheet asking for a URL to link to.
}

- (void)linkSelectionToURL:(CPString)aUrl
{
    [self editor].linkSelection(aUrl);
    [self _didPerformAction];
}

- (void)unlinkSelection:(id)sender
{
    [self editor].unlinkSelection();
    [self _didPerformAction];
}

- (@action)insertOrderedList:(id)sender
{
    [self editor].insertOrderedList();
    [self _didPerformAction];
}

- (@action)insertUnorderedList:(id)sender
{
    [self editor].insertUnorderedList();
    [self _didPerformAction];
}

- (@action)insertImage:(id)sender
{
    // TODO Show a sheet asking for an image URL.
}

- (void)insertImageWithURL:(CPString)aUrl
{
    [self editor].insertImage(aUrl);
    [self _didPerformAction];
}

- (void)setFontNameForSelection:(CPString)font
{
    lastFont = font;
    [self editor].fontSelection(font);
    [self _didPerformAction];
}

/*!
    Set the font size for the selected text. Size is specified
    as a number between 1-6 which corresponds to small through xx-large.
*/
- (void)setFontSizeForSelection:(int)size
{
    [self editor].fontSizeSelection(size);
    [self _didPerformAction];
}

- (CPString)font
{
    // fontSelected crashes if the editor is not active, so just return the
    // last seen font.
    var node = editor.selection ? editor.selection.getNode() : null;
    if (node)
    {
        var fontName = [self editor].getSelectedStyles().get('fontname');

        // The font name may come through with quotes e.g. 'Apple Chancery'
        var format = /'(.*?)'/,
            r = fontName.match(new RegExp(format));

        if (r && r.length == 2) {
            lastFont = r[1];
        }
        else if (fontName)
        {
            lastFont = fontName;
        }

    }

    return lastFont;
}

- (void)setColorForSelection:(CPColor)aColor
{
    [self editor].colorSelection([aColor hexString]);
    [self _didPerformAction];
}
