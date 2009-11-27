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
        [self _didChange];
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

    // This needs to be before the height calculation.
    _iframe.setAttribute("width", width);
    
    if (_scrollMode == CPWebViewScrollAppKit && editor !== nil)
    {
        // ... until we have an editor to match.
        height = editor.getDocument().body.scrollHeight;         
    }

    _iframe.setAttribute("height", height);

    console.log("width: "+width+" height: "+height);

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
