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

The view needs to load resources such as `editor.html` and `wyzihat.js`. Wait for the `textViewDidLoad:` delegate call before using.

## Sample

A sample program is provided in the `sample` folder. You can [view it online](http://hosting.wireload.net/wyzihat/) or compile it yourself. To compile, install `Frameworks` and `wyzihat.js`:
	
	cd sample
	capp gen -f -l --force # Installs Cappuccino frameworks.
	cd Frameworks
	ln -s ../../ WyzihatKit
	cd ..
	cp <WYZIHAT_BUILD>/wyzihat.js Resources/WKTextView

Then open up `index-debug.html` in a browser.

# License

WysihatKit is released under the MIT license. The sample incorporates public domain icons from the [Tango Icon Library](http://tango.freedesktop.org/Tango_Icon_Library). 

# Authors

* Alexander Ljungberg, [WireLoad LLC](http://wireload.net)
* Harry Vangberg
