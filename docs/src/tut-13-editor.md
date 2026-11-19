---
title: "A small text editor"
lead: Build a real tool in about eighty lines — a menu, a text area that fills the window, a status bar, open and save with file dialogs, and the layout rule that surprises everyone once.
---

## What you will learn

- menus with `uiMenu`,
- a multi-line `TextBox` that fills the window (`Dock`),
- a `StatusStrip`,
- the open and save dialogs,
- reacting to a change with an event,
- a layout rule: add the filling control first.

## The program

{{file:samples/UsingDotNet/tutorials/ch10_editor.ring}}

![The editor with some text](img/shots/tut-g03-text.png "The tiny editor: menu on top, status bar at the bottom")

{{output:samples/UsingDotNet/tutorials/ch10_editor.ring --selftest}}

## How it works

### Menus

`uiMenu(oForm, aMenus)` builds the menu bar from a list: `[title, [ [item, code], ... ]]`. Each item has the Ring code to run when it is chosen; `"-"` is a separator line.

### Filling the window: Dock

`Dock = "Fill"` makes a control take all the free space of its parent; other values are `"Top"`, `"Bottom"`, `"Left"`, `"Right"`. When the window is resized the control follows.

> [!WARNING] **Order matters.** Windows Forms places docked controls starting with the *last added*. If you add the menu first and the filling editor after it, the editor is placed first and fills everything — **under** the menu and the status bar, hiding its first line. The fix: add the control that fills **first**, then the menu and the status bar. The program does that.

### A status bar

A `StatusStrip` holds `ToolStripStatusLabel` items. Change a label's `Text` to show information: the number of characters, or "Saved ...".

### React to changes

`setTextChangedEvent("textChanged()")` runs `textChanged()` every time the text changes. The function records that the text is not saved and updates the status bar.

### Open and save

`uiOpenFileName(title, filter)` and `uiSaveFileName(title, filter)` show the standard dialogs and return the chosen path (or `""` if the user cancels). The filter is `"Text files|*.txt|All files|*.*"`: pairs of a description and a pattern. `File.ReadAllText` and `File.WriteAllText` do the actual work.

> [!NOTE] Look at `loadFile`: the text is first read into a variable (`cContent = new File().ReadAllText(cPath)`) and then assigned (`oEditor.Text = cContent`). Writing `oEditor.Text = new File().ReadAllText(cPath)` loses the assignment in Ring — a method of a *new* object on the right side of a property assignment. Use a variable.

### The test

`selfTest` types into the editor, saves to a temporary file, creates a new document, opens the file again and checks each step. Because the real dialogs would wait for a person, the test calls `loadFile` and `saveFile` with a known file name.

## What you learned

| Idea | Example |
|---|---|
| a menu from a list | `uiMenu(oForm, [...])` |
| fill the window | `Dock = "Fill"` |
| add the filling control first | editor, then menu, then status bar |
| status information | `StatusStrip` |
| file dialogs | `uiOpenFileName`, `uiSaveFileName` |
| react to changes | `setTextChangedEvent` |

## Exercises

1. Warn before **New** or **Exit** when the text is not saved (`uiAsk`).
2. Add **Edit → Select all** (`oEditor.SelectAll()`) and **Copy** (`oEditor.Copy()`).
3. Show the cursor line number in the status bar (`oEditor.GetLineFromCharIndex(oEditor.SelectionStart)`).
4. Add a **Font** menu item that opens a `FontDialog` and changes `oEditor.Font`.

The full-size version of this program is the [Notepad](gallery-apps.html#notepad) application.

## Next

[Formatted text](tut-133-richtext.html)
