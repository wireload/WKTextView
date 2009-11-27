/*
 * AppController.j
 * sample
 *
 * Created by Alexander Ljungberg on November 26, 2009.
 * Copyright 2009, WireLoad, LLC All rights reserved.
 */

@import <Foundation/CPObject.j>
@import <WyzihatKit/WKTextView.j>

var NewToolbarItemIdentifier = "NewToolbarItemIdentifier",
    BoldToolbarItemIdentifier = "BoldToolbarItemIdentifier",
    ItalicsToolbarItemIdentifier = "ItalicsToolbarItemIdentifier",
    UnderlineToolbarItemIdentifier = "UnderlineToolbarItemIdentifier",
    RandomTextToolbarItemIdentifier = "RandomTextToolbarItemIdentifier";


@implementation AppController : CPObject
{
    WKTextView editorView;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    editorView = [[WKTextView alloc] initWithFrame:[theWindow frame]];
    [editorView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];    
    [editorView setDelegate:self];
    [contentView addSubview:editorView];

    var toolbar = [[CPToolbar alloc] initWithIdentifier:"Styling"];
    [toolbar setDelegate:self];
    [toolbar setVisible:YES];
    [theWindow setToolbar:toolbar];

    [theWindow orderFront:self];
}

// Return an array of toolbar item identifier (all the toolbar items that may be present in the toolbar)
- (CPArray)toolbarAllowedItemIdentifiers:(CPToolbar)aToolbar
{
    return [CPToolbarFlexibleSpaceItemIdentifier, BoldToolbarItemIdentifier, ItalicsToolbarItemIdentifier, UnderlineToolbarItemIdentifier, RandomTextToolbarItemIdentifier, NewToolbarItemIdentifier];
}

// Return an array of toolbar item identifier (the default toolbar items that are present in the toolbar)
- (CPArray)toolbarDefaultItemIdentifiers:(CPToolbar)aToolbar
{
    return [NewToolbarItemIdentifier, BoldToolbarItemIdentifier, ItalicsToolbarItemIdentifier, UnderlineToolbarItemIdentifier, CPToolbarFlexibleSpaceItemIdentifier, RandomTextToolbarItemIdentifier];
}

// Create the toolbar item that is requested by the toolbar.
- (CPToolbarItem)toolbar:(CPToolbar)aToolbar itemForItemIdentifier:(CPString)anItemIdentifier willBeInsertedIntoToolbar:(BOOL)aFlag
{
	// Create the toolbar item and associate it with its identifier
    var toolbarItem = [[CPToolbarItem alloc] initWithItemIdentifier:anItemIdentifier];

	var mainBundle = [CPBundle mainBundle];

    if (anItemIdentifier == NewToolbarItemIdentifier)
    {
    	var image = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"tango/document-new.png"] size:CPSizeMake(32, 32)];
    	[toolbarItem setImage:image];

        [toolbarItem setTarget:editorView];
        [toolbarItem setAction:@selector(clearText:)];
        [toolbarItem setLabel:"New"];

        [toolbarItem setMinSize:CGSizeMake(32, 32)];
        [toolbarItem setMaxSize:CGSizeMake(32, 32)];
    }
    else if (anItemIdentifier == BoldToolbarItemIdentifier)
    {
    	var image = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"tango/format-text-bold.png"] size:CPSizeMake(32, 32)];
    	[toolbarItem setImage:image];

        [toolbarItem setTarget:editorView];
        [toolbarItem setAction:@selector(boldSelection:)];
        [toolbarItem setLabel:"Bold"];

        [toolbarItem setMinSize:CGSizeMake(32, 32)];
        [toolbarItem setMaxSize:CGSizeMake(32, 32)];
    }
    else if (anItemIdentifier == ItalicsToolbarItemIdentifier)
    {
        var image = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"tango/format-text-italic.png"] size:CPSizeMake(32, 32)];
    	[toolbarItem setImage:image];
    	
        [toolbarItem setTarget:editorView];
        [toolbarItem setAction:@selector(italicSelection:)];
        [toolbarItem setLabel:"Italics"];

        [toolbarItem setMinSize:CGSizeMake(32, 32)];
        [toolbarItem setMaxSize:CGSizeMake(32, 32)];
    }
    else if (anItemIdentifier == UnderlineToolbarItemIdentifier)
    {
        var image = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"tango/format-text-underline.png"] size:CPSizeMake(32, 32)];
    	[toolbarItem setImage:image];

        [toolbarItem setTarget:editorView];
        [toolbarItem setAction:@selector(underlineSelection:)];
        [toolbarItem setLabel:"Underline"];

        [toolbarItem setMinSize:CGSizeMake(32, 32)];
        [toolbarItem setMaxSize:CGSizeMake(32, 32)];
    }
    else if (anItemIdentifier == RandomTextToolbarItemIdentifier)
    {
        var image = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"tango/format-justify-fill.png"] size:CPSizeMake(32, 32)];
    	[toolbarItem setImage:image];

        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(setRandomText:)];
        [toolbarItem setLabel:"Lorem ipsum"];

        [toolbarItem setMinSize:CGSizeMake(32, 32)];
        [toolbarItem setMaxSize:CGSizeMake(32, 32)];
    }

    
    return toolbarItem;
}

- (@action)setRandomText:sender 
{
    [editorView setHtmlValue:"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut est urna, vulputate sed viverra dignissim, consequat vitae eros. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Suspendisse ut sapien enim, et pellentesque elit. In commodo facilisis est, et tempus lacus aliquam vitae. Maecenas quam nulla, elementum ut tristique quis, cursus a nisi. Duis mollis risus vel velit molestie convallis nec a purus. Donec neque arcu, suscipit sit amet mattis eu, fringilla ac sapien. Ut lorem nibh, mollis in tincidunt at, volutpat ut turpis. Maecenas nulla est, tincidunt pharetra consectetur vel, laoreet sed nibh. Pellentesque tempor diam vel elit commodo aliquet. Donec congue fringilla eros a tincidunt. Praesent accumsan mi tincidunt arcu ultricies nec pellentesque dolor faucibus. Mauris sed nisl in ligula porta congue et quis turpis. Suspendisse in lorem at felis tempus semper. In porta enim a ipsum aliquet consectetur.\n\nMauris ac tellus orci. Aenean egestas porta ornare. Cras nisl lorem, vulputate ac pellentesque eu, aliquet ac leo. Proin eros libero, tincidunt sed sodales eget, elementum non augue. Praesent convallis auctor venenatis. Suspendisse id urna quam. Aliquam sagittis, leo commodo laoreet interdum, arcu felis dictum velit, a sodales justo tortor a erat. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis nibh magna, consequat et congue eu, bibendum id nisi. Cras gravida risus in nulla pharetra sagittis. Cras neque eros, consectetur nec bibendum eget, bibendum dictum libero. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Nam rutrum dictum neque vel eleifend. Vivamus tempus, lorem vel ultricies ullamcorper, ante risus imperdiet massa, nec aliquam orci ipsum ut nisl. Aliquam id justo eu lorem dapibus tincidunt. Donec suscipit consequat metus, sed venenatis lorem malesuada sit amet. Ut at risus ut ligula vulputate auctor. Vivamus rutrum elementum porttitor. Fusce quam arcu, tristique eget consectetur eu, iaculis in urna.\n\nDonec a metus ac elit faucibus sagittis non a ligula. In aliquet, lectus sed pulvinar bibendum, justo ligula faucibus sem, vestibulum eleifend lacus augue a eros. Suspendisse potenti. Phasellus vehicula blandit ultrices. Donec tortor nulla, fermentum nec viverra id, consequat non metus. Fusce nunc urna, aliquet sit amet varius ut, dapibus a sem. Aliquam erat volutpat. Vestibulum at enim et magna lacinia sollicitudin id nec dolor. Sed ultricies urna ut justo blandit tincidunt. Sed sit amet orci et justo pellentesque iaculis accumsan ac quam.\n\nNunc tristique felis quis leo blandit eget iaculis lacus hendrerit. Maecenas euismod consequat lacus quis porttitor. Quisque consequat, metus eu interdum vulputate, quam dolor porttitor dui, non faucibus quam nibh nec erat. Integer sit amet gravida quam. Proin nunc eros, tincidunt sit amet accumsan laoreet, dictum vel sapien. Praesent at fringilla orci. Etiam vehicula lacinia nisi, et molestie justo congue molestie. Maecenas tempus, quam nec placerat suscipit, lorem sapien feugiat augue, id pharetra augue enim eu nisl. Morbi ullamcorper lacus ac dolor ultricies vel pellentesque odio consequat. Maecenas a pellentesque nunc. Phasellus a varius massa. Vestibulum eget tortor eget ante iaculis molestie. Pellentesque eu augue metus, ut pellentesque purus. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Curabitur consequat feugiat tincidunt. Proin tellus tortor, pharetra vel rhoncus ac, varius eget nisi. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Cras et nunc metus. Pellentesque tincidunt iaculis erat id porta. Curabitur eget magna et velit eleifend tempor.\n\nVestibulum ultricies leo at augue malesuada congue. Maecenas laoreet metus et nunc consectetur placerat. Nulla facilisi. Duis iaculis tristique feugiat. Ut quis consectetur justo. Praesent condimentum sagittis dui, in lobortis tellus accumsan quis. In aliquam lacus non dolor accumsan rutrum. Etiam sed urna dolor. Donec consectetur lacus eu ante sodales feugiat. Aliquam aliquet nibh vel massa mattis pellentesque. Curabitur et tortor nisl, ut consequat felis. Mauris non orci at tortor ultrices condimentum. Aliquam erat volutpat. Mauris porttitor, diam convallis semper hendrerit, erat mi tempor dolor, id semper augue justo fermentum odio. Sed vitae nulla eu augue fringilla pellentesque vel ac neque. Nullam arcu nibh, auctor ut accumsan ac, ullamcorper eu velit. Integer in ligula nec felis auctor viverra. In commodo malesuada volutpat. Etiam justo elit, tincidunt ac semper sed, eleifend eu odio. Cras ac nulla eget lorem tempor venenatis."];    
}

- (void)textViewDidLoad:textView
{
}

@end

@end
