WyzihatKit Changelog
====================

# Version 0.4 (May 1th, 2010)

## New Features
* Upgraded WysiHat. This version ups the minimum requirements to IE 7, Firefox 3, Safari 4 or Chrome 4. WyzihatKit was updated to use WysiHat as a contentEditable div instead of an iframe.
* Implemented setEnabled/isEnabled. When disabled the editor does not display a text edit cursor; it does not listen to mouse events, etc.
* Support for editor padding was removed since it too was a source of jumping bugs, although on a smaller scale. If you need padding just add it around the editor instead.
* Jakefile to create debug and release builds (`jake debug` and `jake release`).
* setFontSizeForSelection.
* setColorForSelection.

## Changes and Fixes
* WKTextView can now become the first responder. Tabbing out of the field is possible with Shift-Tab, the standard key for tabbing backwards. Tab forward is not possible to allow the tab character to be written.
* Fixed: clicking on a WKTextView would cause it to gain focus without requesting first responder status. The most visible artifact of this was that tabbing out of the view if it was activated by mouse didn't work as expected because Cappuccino didn't know the view was selected to begin with.
* Activating an editor by clicking on it now makes its window the key window.
* Backgrounds underneath WKTextView now shine through.
* Fixed: some variables leaking into the global scope.
* Fixed: uninitialized height could cause a race condition in Webkit.
* Fixed: in Firefox, clicking on the WKTextView did not make it the first responder, and shift tab did not back tab out of the editor.
* Renamed setFont to setFontNameForSelection.
* Content height calculations are much improved and it looks like most of the jumping bugs (hitting enter to insert a new row while at the last row in a text taller than the view height) are resolved. Performance might also be improved.
* Removed some left over logging.

# Version 0.3 (January 13th, 2010)

## New Features
* New delegate method textViewDidChange.

## Changes and Fixes
* Fixed: text views with a vertical scrollbar would have 15 of their rightmost pixels missing until the window was first resized.
* Fixed: sometimes a text select would be followed by an immediate deselect; clicking with Safari could result in text being reflowed; moving the cursor in Opera back and forth lead to spaces being inserted at the cursor position.
* Fixed: the wysihat submodule pointed to the non public github repository.

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
