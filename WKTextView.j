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
        // FIXME Scrolling doesn't work right.
        [self setScrollMode:CPWebViewScrollNative];
        [self setMainFrameURL:[[CPBundle mainBundle] pathForResource:"WKTextView/editor.html"]];
    }
    return self;
}

- (void)_finishedLoading
{
    [super _finishedLoading];   
    // FIXME Polling to check if the editor has loaded is inefficient. Unfortunately, _finishedLoading seems to fire
    // too early.
     
    [self checkLoad];
}

- (void)checkLoad
{
    var maybeEditor = [self objectByEvaluatingJavaScriptFromString:"editor"];
    if (maybeEditor)
    {
        editor = maybeEditor;
        if (loadTimer)
        {
            [loadTimer invalidate];
            loadTimer = nil;            
         }
        
        if ([delegate respondsToSelector:@selector(richTextEditorDidLoad:)])
        {
            [delegate richTextEditorDidLoad:self];
        }
    }
    else
    {
        if (!loadTimer)
            loadTimer = [CPTimer scheduledTimerWithTimeInterval:0.1 target:self selector:"checkLoad" userInfo:nil repeats:YES];        
    }
}

- (JSObject)editor
{
    return editor;
}
 
- (CPString)htmlValue
{
    return [self editor].content();
}
 
- (void)setHtmlValue:(CPString)content
{
    [self editor].setContent(content);
    [self editor].save();
}
 
- (@action)boldSelection:(id)sender
{
    [self editor].boldSelection();
}

/*
    From http://github.com/280north/cappuccino/issuesearch?state=open&q=CPWebView#issue/190
*/
- (BOOL)_resizeWebFrame {
    var width = [self bounds].size.width,
        height = [self bounds].size.height;

    _iframe.setAttribute("width", width);
    _iframe.setAttribute("height", height);

    [_frameView setFrameSize:CGSizeMake(width, height)];
}