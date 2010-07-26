goog.require('goog.dom');
goog.require('goog.editor.Command');
goog.require('goog.editor.SeamlessField');
goog.require('goog.editor.plugins.BasicTextFormatter');
goog.require('goog.editor.plugins.EnterHandler');
goog.require('goog.editor.plugins.HeaderFormatter');
goog.require('goog.editor.plugins.LinkDialogPlugin');
goog.require('goog.editor.plugins.ListTabHandler');
//goog.require('goog.editor.plugins.LoremIpsum');
goog.require('goog.editor.plugins.RemoveFormatting');
goog.require('goog.editor.plugins.SpacesTabHandler');
goog.require('goog.editor.plugins.UndoRedo');

goog.exportSymbol('goog.editor.Field.EventType.DELAYEDCHANGE', goog.editor.Field.EventType.DELAYEDCHANGE);
goog.exportSymbol('goog.editor.Field.EventType.SELECTIONCHANGE', goog.editor.Field.EventType.SELECTIONCHANGE);
goog.exportSymbol('goog.editor.SeamlessField', goog.editor.SeamlessField);
goog.exportProperty(goog.editor.SeamlessField.prototype, 'registerPlugin', goog.editor.SeamlessField.prototype.registerPlugin);
goog.exportProperty(goog.editor.SeamlessField.prototype, 'makeEditable', goog.editor.SeamlessField.prototype.makeEditable);
goog.exportProperty(goog.editor.SeamlessField.prototype, 'makeUneditable', goog.editor.SeamlessField.prototype.makeUneditable);
goog.exportProperty(goog.editor.SeamlessField.prototype, 'setHtml', goog.editor.SeamlessField.prototype.setHtml);
goog.exportProperty(goog.editor.SeamlessField.prototype, 'getCleanContents', goog.editor.SeamlessField.prototype.getCleanContents);

goog.exportSymbol('goog.events.listen', goog.events.listen);
goog.exportSymbol('goog.editor.plugins.BasicTextFormatter', goog.editor.plugins.BasicTextFormatter);
goog.exportSymbol('goog.editor.plugins.RemoveFormatting', goog.editor.plugins.RemoveFormatting);
goog.exportSymbol('goog.editor.plugins.UndoRedo', goog.editor.plugins.UndoRedo);
goog.exportSymbol('goog.editor.plugins.ListTabHandler', goog.editor.plugins.ListTabHandler);
goog.exportSymbol('goog.editor.plugins.SpacesTabHandler', goog.editor.plugins.SpacesTabHandler);
goog.exportSymbol('goog.editor.plugins.EnterHandler', goog.editor.plugins.EnterHandler);
goog.exportSymbol('goog.editor.plugins.HeaderFormatter', goog.editor.plugins.HeaderFormatter);

