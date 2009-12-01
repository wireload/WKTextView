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

/*!
    A WYSIHAT based rich text editor widget.
    
    Beware of the load times. Wait for the load event.
*/
@implementation WKTextView : CPWebView
{
    id          delegate @accessors;
    CPTimer     loadTimer;
    JSObject    editor;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
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
    [self _updateScrollers];
}

- (void)_cursorDidMove
{
    
/*    n = editor.selection.getNode();
    
    // If the cursor goes outside of the scrollview, try to center it.
    if (n) {
        [_frameView scrollRectToVisible:CGRectMake(n.offsetLeft,n.offsetTop,n.scrollWidth,n.scrollHeight)];
        [self _updateScrollers];
    }*/
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
    return [self editor].content();
}
 
- (void)setHtmlValue:(CPString)content
{   
    [self editor].textarea.value = content;
    [self editor].load();
    [self _didChange];    
}

- (@action)clearText:(id)sender
{
    [self setHtmlValue:""];
}
 
- (@action)boldSelection:(id)sender
{
    [self editor].boldSelection();
}

- (@action)underlineSelection:(id)sender
{
    [self editor].underlineSelection();
}

- (@action)italicSelection:(id)sender
{
    [self editor].italicSelection();
}

- (@action)strikethroughSelection:(id)sender
{
    [self editor].strikethroughSelection();
}

- (@action)alignSelectionLeft:(id)sender
{
    [self editor].alignSelection('left');
}

- (@action)alignSelectionRight:(id)sender
{
    [self editor].alignSelection('right');
}

- (@action)alignSelectionCenter:(id)sender
{
    [self editor].alignSelection('center');
}

- (@action)alignSelectionFull:(id)sender
{
    [self editor].alignSelection('full');
}

- (@action)linkSelection:(id)sender
{
    // TODO Show a sheet asking for a URL to link to.
}

- (void)linkSelectionToURL:(CPString)aUrl
{
    [self editor].linkSelection(aUrl);
}

- (void)unlinkSelection:(id)sender
{
    [self editor].unlinkSelection();
}

- (@action)insertOrderedList:(id)sender
{
    [self editor].insertOrderedList();
}

- (@action)insertUnorderedList:(id)sender
{
    [self editor].insertUnorderedList();
}

- (@action)insertImage:(id)sender
{
    // TODO Show a sheet asking for an image URL.
}

- (void)insertImageWithURL:(CPString)aUrl
{
    [self editor].insertImage(aUrl);
}

- (void)fontSelection:(CPString)font
{
    [self editor].fontSelection(font);
}
