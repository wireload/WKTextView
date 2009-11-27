/*
 * WKTextView.j
 * WyzihatKit
 *
 * Created by Alexander Ljungberg, WireLoad LLC.
 *
 */

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
        [self setMainFrameURL:[[CPBundle mainBundle] pathForResource:"WKTextView/editor.html"]];
        [self setScrollMode:CPWebViewScrollAppKit];
        // Check if the document was loaded immediately. This could happen if we're loaded from
        // a file URL.
        [self checkLoad];
    }
    return self;
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
    editor.getDocument().body.style.marginTop = 0;
    editor.getDocument().body.style.marginBottom = 0;
    // Without this line Safari may show an inner scrollbar.
    editor.getDocument().body.style.overflow = 'hidden';
    editor.observe("wysihat:change", function() {
        [[CPRunLoop mainRunLoop] performSelector:"_didChange" target:self argument:nil order:0 modes:[CPDefaultRunLoopMode]];
    });
    editor.observe("wysihat:cursormove", function() {
        [[CPRunLoop mainRunLoop] performSelector:"_cursorDidMove" target:self argument:nil order:0 modes:[CPDefaultRunLoopMode]];
    });
}

- (JSObject)editor
{
    return editor;
}

- (void)_didChange
{
    // When the text changes, the height of the content may change.
    oldHeight = _iframe.getAttribute("height");
    [self _resizeWebFrame];
    newHeight = _iframe.getAttribute("height");
    scrollAmount = newHeight - oldHeight;

    console.log("oldHeight: "+oldHeight+" newHeight: "+newHeight);
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
    console.log([_frameView frame]);
    // None of this works.
    /*[_scrollView setHasVerticalScroller:NO];
    [_scrollView setHasVerticalScroller:YES];
    
    [_scrollView reflectScrolledClipView:[_scrollView contentView]];
    
    var scroller = [_scrollView verticalScroller];
    
    [scroller setNeedsDisplay:YES];
    [scroller setNeedsLayout];
        
    scroller = [_scrollView horizontalScroller];
    
    [scroller setNeedsDisplay:YES];
    [scroller setNeedsLayout];

    [self setNeedsDisplay:YES];
    [[self superview] setNeedsLayout];*/
    //[_scrollView setDocumentView:_frameView];
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

    // This needs to be before the height calculation so that the right height for the current
    // width can be calculated.
    _iframe.setAttribute("width", width);
    
    if (_scrollMode == CPWebViewScrollAppKit && editor !== nil)
    {
        var editorBody = editor.getDocument().body;

        
        // editoryBody.scrollHeight is normally correct, except it never becomes smaller even
        // if the content does. Since in _resizeWebFrame we don't know if the content became
        // taller or shorter, we have to do it the hard way.
        height = 0;
        var children = editorBody.childNodes;
        for(i=0; i<children.length; i++)
            height += children[i].scrollHeight;
    }

    console.log("height: "+height);
    _iframe.setAttribute("height", height);

    [_frameView setFrameSize:CGSizeMake(width, height)];
} 
 
- (CPString)htmlValue
{
    return [self editor].content();
}
 
- (void)setHtmlValue:(CPString)content
{
    [self editor].setContent(content);
    [self editor].save();
    [self _resizeWebFrame];
}
 
- (@action)boldSelection:(id)sender
{
    [self editor].boldSelection();
}
