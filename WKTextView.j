/*
 * WKTextView.j
 * WyzihatKit
 *
 * Created by Alexander Ljungberg, WireLoad LLC.
 *
 */

WKTextViewPaddingTop = 4;
WKTextViewPaddingBottom = 4;
WKTextViewPaddingLeft = 6;
WKTextViewPaddingRight = 6;
WKTextCursorHeightFactor = 0.1;
WKTextViewDefaultFont = "Verdana";

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
    CPString    lastFont;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        shouldFocusAfterAction = YES;
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
    var maybeEditor = [self objectByEvaluatingJavaScriptFromString:"editor"];
    if (maybeEditor && maybeEditor.ready)
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
    editor = anEditor;
    editor.getDocument().body.style.paddingTop = WKTextViewPaddingTop+'px';
    editor.getDocument().body.style.paddingBottom = WKTextViewPaddingBottom+'px';
    editor.getDocument().body.style.paddingLeft = WKTextViewPaddingLeft+'px';
    editor.getDocument().body.style.paddingRight = WKTextViewPaddingRight+'px';
    editor.getDocument().body.style.margin = '0';
    // Without this line Safari may show an inner scrollbar.
    editor.getDocument().body.style.overflow = 'hidden';

    // FIXME execCommand doesn't work well without the view having been focused
    // on at least once.
    editor.focus();
    
    suppressAutoFocus = YES;    
    [self setFont:WKTextViewDefaultFont];
    suppressAutoFocus = NO;
    
    editor.observe("wysihat:change", function() {
        [[CPRunLoop currentRunLoop] performSelector:"_didChange" target:self argument:nil order:0 modes:[CPDefaultRunLoopMode]];
        // The normal run loop doesn't react to iframe events, so force immediate processing.
        [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
    });
    editor.observe("wysihat:cursormove", function() {
        [[CPRunLoop currentRunLoop] performSelector:"_cursorDidMove" target:self argument:nil order:0 modes:[CPDefaultRunLoopMode]];
        // The normal run loop doesn't react to iframe events, so force immediate processing.
        [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
    });
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
}

- (void)_cursorDidMove
{
    // Kind of a hack to figure out the exact cursor position.
    editor.getWindow().scrollTo(0, 0);
    editor.selection.setBookmark();    
    bookmark = editor.getDocument().getElementById('bookmark');
    if (bookmark)
    {
        var offset = bookmark.offsetTop,
            cursorHeight = [_frameView bounds].size.height * WKTextCursorHeightFactor;
        bookmark.parentNode.removeChild(bookmark);
        [_frameView scrollRectToVisible:CGRectMake(0,offset-cursorHeight,1,offset+cursorHeight)];
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
        height = [_scrollView bounds].size.height,
        hscroller = [_scrollView horizontalScroller],
        vscroller = [_scrollView verticalScroller];

    if (vscroller)
        width -= [vscroller bounds].size.width;
    if (hscroller)
        height -= [hscroller bounds].size.height;

    _iframe.setAttribute("width", width);
    
    if (_scrollMode == CPWebViewScrollAppKit && editor !== nil)
    {
        var editorBody = editor.getDocument().body;
        
        // This needs to be before the height calculation so that the right height for the current
        // width can be calculated.
        editorBody.style.width = width-WKTextViewPaddingLeft-WKTextViewPaddingRight+"px";
        
        // editoryBody.scrollHeight is normally correct, except it never becomes smaller once
        // it's gone up. Since here in _resizeWebFrame we don't know if the content became taller 
        // or shorter, we have to do it the hard way in both cases.

        // This method is based on the one implemented in Dojo's TextArea.
        var apparentHeight = editorBody.scrollHeight;
        // If the content isn't truly apparentHeight tall, extra padding will be absorbed into
        // the 'fluff' space. By checking how much padding is absorbed we know the fluff size.
        editorBody.style.paddingBottom = (WKTextViewPaddingBottom + apparentHeight) + "px";
        editorBody.scrollTop = 0;
        var newHeight = editorBody.scrollHeight - apparentHeight;
        //var fluff = apparentHeight - newHeight;
        //console.log("fluff: "+fluff);
        editorBody.style.paddingBottom = WKTextViewPaddingBottom + "px";

        // FIXME Immediately after content changes, Firefox calculates the height of the body
        // to 0 pixels. This code alleviates the symtoms by never making the scrolling area
        // smaller than the height available.
        height = MAX(newHeight, height);
    }

    //console.log("width: "+width+" height: "+height);
    _iframe.setAttribute("height", height);

    [_frameView setFrameSize:CGSizeMake(width, height)];
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

- (CPString)htmlValue
{
    return [self editor].rawContent();
}

- (void)setHtmlValue:(CPString)html
{
    [self editor].setRawContent(html);
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
        [self editor].focus();
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

- (void)setFont:(CPString)font
{
    lastFont = font;
    [self editor].fontSelection(font);
    [self _didPerformAction];
}

- (CPString)font
{
    // fontSelected crashes if the editor is not active, so just return the
    // last seen font.
    var node = editor.selection.getNode();
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
