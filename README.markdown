WyzihatKit
==========

A [Cappuccino](http://cappuccino.org/) control providing rich text editing through use of the [WyziHat](http://github.com/josh/wysihat/) editor.

This is mostly a hack for use until a proper rich text capable CPTextView is introduced.

## Installation

Link the `WyziHat` folder into your `Frameworks` folder. Then copy `Wyzihat/Resources/WKTextView` into `Resources/WKTextView`. 

Create and combine the `wyzihat.js` file:

	git clone git://github.com/josh/wysihat.git
	cd wysihat
	rake
	cat dist/prototype.js dist/wysihat.js >>wyzihat.js
	
Optionally minify the combined `wyzihat.js` - it will shrink very well.

Copy your combined `wyzihat.js` into `Resources/WKTextView`.

## Usage

	textView = [[WKTextView alloc] initWithFrame:effectiveFrame];
	[textView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];    
	[textView setDelegate:self];

The view needs to load resources such as `editor.html` and `wyzihat.js`. Wait for the `richTextEditorDidLoad:` delegate call before using.

## License

WysiHat is released under the MIT license.

# Authors

* Alexander Ljungberg, [WireLoad LLC](http://wireload.net)
* Harry Vangberg
