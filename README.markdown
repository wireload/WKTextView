WyzihatKit
==========

**NOTE: This version of WyzihatKit has been succeeded by a Google Closure Editor based version. See https://github.com/aljungberg/WyzihatKit for the latest.**

A [Cappuccino](http://cappuccino.org/) control providing rich text editing through use of the [WysiHat](http://github.com/josh/wysihat/) editor.

This is mostly a hack for use until a proper rich-text-capable `CPTextView` is introduced.

## Installation

Link the `WyzihatKit` folder into your `Frameworks` folder.

Create and combine the `wyzihat.js` file using the WyzihatKit modified version of WysiHat:

	git submodule init
	git submodule update
	cd wysihat
	git submodule init
	git submodule update
	rake
	cat dist/prototype.js dist/wysihat.js >../Resources/WKTextView/wysihat.js

Optionally minify the combined `wysihat.js` - it will shrink very well.

## Usage

	textView = [[WKTextView alloc] initWithFrame:effectiveFrame];
	[textView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
	[textView setDelegate:self];

The view needs to load resources such as `editor.html` and `wysihat.js`. Wait for the `textViewDidLoad:` delegate call before using.

## Sample

A sample program is provided in the `sample` folder. You can [view it online](http://hosting.wireload.net/wysihat/) or compile it yourself. To compile, install `Frameworks` and `wysihat.js`:

	cd sample
	capp gen -f -l --force # Installs Cappuccino frameworks.
	cd Frameworks
	ln -s ../../ WyzihatKit

Then open up `index-debug.html` in a browser.

# License

WysihatKit is released under the MIT license. The sample incorporates Creative Commons icons from [FamFamFam](http://www.famfamfam.com/lab/icons/silk/).

# Authors

* Alexander Ljungberg, [WireLoad LLC](http://wireload.net)
* xanados
* Paul Baumgart
* Evadne Wu
* Harry Vangberg
