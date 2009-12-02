WyzihatKit Changelog
====================

# Version 0.2 (December 2nd, 2009)

## New Features
* Support for insert image, bullets, ordered lists, font selection, link, unlink, strikethrough and text alignment.
* The current font can now be read from the editor with the font method.
* New delegate method textViewCursorDidMove:.
* Added a setTextValue: method.

## Changes and Fixes
* Fixed: editor height calculation didn't work in Firefox. The replacement code is also more elegant and could be more efficient for large amounts of text. 
* Fixed: deleting or inserting text would not cause the scrollbar to update without first mousing over it.
* Workaround for focus lost when the toolbar is clicked: the new option setShouldFocusAfterAction: makes the editor automatically focus after actions such as boldSelection.
* Fixed: textViewDidLoad is not sent until the WysiHat ready flag is set. This resolves some problems where content could not be set in Firefox immediately in a textViewDidLoad callback. 
* Wysihat now available as a submodule, making it easier to grab the right hacked version.
* Basic support for the editor scrolling automatically to follow the cursor.
* Wyzihat is now correctly spelled Wysihat in most places.

# Version 0.1 (November 27)

* First release.
