WKTextView
==========

A [Cappuccino](http://cappuccino.org/) control providing rich text editing through use of a browser driving content editable field. Under the hood, the [Google Closure Library](http://code.google.com/closure/library/) editor is used.

Until a proper `CPTextView` is written this will probably be one of the most full featured rich text editor for Cappuccino.

You can view an online demo [here](http://wireload.net/open_source/wktextview-sample/index.html).

## Features

 * Bold, italics, underline, strike through.
 * Left, right, center and justify alignment.
 * Bulleted and numbered lists.
 * Links.
 * Images.
 * Fonts.
 * Outputs regular HTML.
 * Vaguely resembles a proper CPTextView in its API.

## Installation

Link the `WKTextView` folder into your `Frameworks` folder.

Create and combine the `Resources/WKTextView/closure-editor.js` file using the WKTextView modified version of the Closure editor:

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

A sample program is provided in the `sample` folder. To compile and view, run the `samplify.sh` script, then open up `index-debug.html` in a browser:

    sh samplify.sh
    open sample.dist/index-debug.html

# License

WKTextView is released under the Apache License 2.0. The sample incorporates Creative Commons icons from [FamFamFam](http://www.famfamfam.com/lab/icons/silk/).

# Authors

* Alexander Ljungberg, [WireLoad Inc](http://wireload.net)
* Evadne Wu
* Klaas Pieter Annema
* Paul Baumgart
* xanados

## Thanks to

* Harry Vangberg
