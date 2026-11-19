---
title: "Tutorial 41: Menus, toolbars and shortcuts"
lead: One action, many ways to reach it. This lesson writes each action once and connects it to a menu item, a toolbar button, a context menu and a keyboard shortcut.
---

## What you will learn

- the menu bar, toolbar, context menu and status bar controls,
- shortcut keys,
- a menu item that can be ticked,
- the rule that keeps a program tidy: **write each action once**.

## The principle

A user may reach "make upper case" from the **Text** menu, a toolbar button, the right-click menu, or `Ctrl+U`. If each of those had its own code, a fix would have to be made four times. Instead each action is **one function** (`upperCase`, `newText`), and every control only *calls* it.

## The program

{{file:docs/tutorials/g41_menus.ring}}

![The window with a menu bar, a toolbar and a status bar](img/shots/tut-g41.png "Menu bar, toolbar, the text and the status bar")

{{output:docs/tutorials/g41_menus.ring --selftest}}

## How it works

### The menu bar

`uiMenu` builds the bar from a list: `[title, [ [item, code, shortcut], ... ]]`. The *code* is the Ring code to run (a function call), `"-"` is a separator, and the optional *shortcut* is the .NET text of the `Keys` enum: `"Control, N"`, `"Control, A"`, `"Alt, F4"`. The shortcut also appears next to the item in the menu, and works even when the menu is closed.

### A tick in the menu

`Word wrap` is a `ToolStripMenuItem` created by hand with `CheckOnClick = True`: each click toggles `Checked` and raises `CheckedChanged`. The handler copies the state to the text box (`oText.WordWrap = oWrapItem.Checked`). It is added to the **Text** menu through `oForm.MainMenuStrip.Items.Item(2).DropDownItems.Add(...)`.

### The toolbar

A `ToolStrip` holds buttons (`ToolStripButton`); each has a `Text` and a click event. `Items.Add` puts a button on the strip. The toolbar is built in a loop from a list of `[caption, code]`.

### The context menu

A `ContextMenuStrip` is a menu without a bar: assign it to a control (`oText.ContextMenuStrip = oContext`) and it opens with the right mouse button.

### The order of docked controls

> [!NOTE] Windows Forms places docked controls starting from the **last added**. The text area (`Dock = "Fill"`) is added first, then the toolbar, then the menu bar, then the status bar. The menu bar ends up at the very top, the toolbar below it, the status bar at the bottom, and the text area gets what is left. If you add the menu before the toolbar, the toolbar is placed above the menu. See [tutorial 13](tut-13-editor.html).

### Telling the user what happened

Every action calls `say(message)`, which writes into the status bar and counts the calls. The test uses the counter: three actions from three different places, three reports.

### Testing

`PerformClick()` runs a menu item, a toolbar button or a context menu entry as if it were clicked. The test reaches each one through the control collections (`Items.Item(n)`) and checks that the **same function** ran: the text was turned to upper case in all three cases. It also toggles the tick and checks word wrap and the status text, and reads the `ShortcutKeys` property of *Copy*: `C, Control` (a combination of two flags, written in this order by .NET).

## What you learned

- write each action once,
- menu items, toolbar buttons, context menus all call it,
- shortcuts are enum texts,
- `CheckOnClick` for ticks,
- docking order decides the layout.

## Exercises

1. Add *Redo* and *Undo* (`oText.Undo()`) with `Ctrl+Z`.
2. Enable or disable *Cut* and *Copy* depending on whether text is selected (`Enabled`, `SelectionChanged`).
3. Add a recent-files list that grows as the user opens files.
4. Add a toolbar button with an image (`oButton.Image = new Bitmap(...)`, [tutorial 22](tut-22-images.html)).

## Next

[Tutorial 34: Timers and progress](tut-34-timers.html)
