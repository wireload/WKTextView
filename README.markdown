WyzihatKit
==========

A [Cappuccino](http://cappuccino.org/) control providing rich text editing through use of the [Google Closure Library](http://code.google.com/closure/library/) editor. In a previous version the Wysihat editor was used, hence the framework name.

This is mostly a hack for use until a proper rich-text-capable `CPTextView` is introduced.

## Installation

Link the `WyzihatKit` folder into your `Frameworks` folder.

Create and combine the `Resources/WKTextView/closure-editor.js` file using the WyzihatKit modified version of the Closure editor:

	git submodule init
	git submodule update
	cd auxiliary
	# Edit build.sh to provide the correct path to closure.jar.
	sh build.sh

## Usage

	textView = [[WKTextView alloc] initWithFrame:effectiveFrame];
	[textView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
	[textView setDelegate:self];

The view needs to load resources such as `editor.html` and `closure-editor.js`. Wait for the `textViewDidLoad:` delegate call before using.

## Sample

A sample program is provided in the `sample` folder. You can [view it online](http://hosting.wireload.net/wysihat/) or compile it yourself. To compile, install `Frameworks` and `wysihat.js`:

	cd sample
	capp gen -f -l --force # Installs Cappuccino frameworks.
	cd Frameworks
	ln -s ../../ WyzihatKit

Then open up `index-debug.html` in a browser.

# License

WysihatKit is released under the Apache License 2.0. The sample incorporates Creative Commons icons from [FamFamFam](http://www.famfamfam.com/lab/icons/silk/).

# Authors

* Alexander Ljungberg, [WireLoad LLC](http://wireload.net)
* Evadne Wu
* Klaas Pieter Annema
* Paul Baumgart
* xanados

## Thanks to

* Harry Vangberg
