---
title: "More than one window"
lead: A program often has a main window and a tool window that stays open beside it. This lesson opens a second window with Show and an owner, keeps only one copy of it, lets the two windows talk, counts the open windows and closes the tool with its owner.
---

## What you will learn

- the difference between a **modal** window (`ShowDialog`) and a window that stays open (`Show`),
- **`Show(owner)`**: the tool window belongs to the main window,
- opening **one** copy and bringing it to the front (`Activate`),
- two windows that talk: a function that changes the controls of the other,
- `Application.OpenForms`,
- why an event must not destroy its own window object.

The tutorial [Your own dialog](tut-40-dialog.html) used a *modal* dialog: the main window waits until it is closed. A tool window is *modeless*: both windows work.

## The program

{{file:samples/UsingDotNet/tutorials/ch10_windows.ring}}

{{output:samples/UsingDotNet/tutorials/ch10_windows.ring --selftest}}

## How it works

### Show with an owner

`oTool.Show(oForm)` opens the tool window and **returns at once**, so the main window can still be used. The argument is the **owner**: an owned window always stays in front of its owner, is minimized and restored with it, and is closed with it. Without an owner (`Show(NULL)`) the two windows are separate. The test reads `oTool.Owner.Text` and gets the title of the main window.

### One copy

Clicking *Open the tool window* twice must not make two tool windows. `openTool` first looks at `lToolOpen`: when the window is open it only calls `Activate()`, which brings it to the front, and returns. `nToolOpened` counts how many windows were really made; the test shows 1 after two clicks.

### Talking

A window is made of controls, and the controls are variables. The tool window calls `applyTool()`, a function that reads the text box of the tool and writes the label of the main window: `oShown.Text = "Applied: " + oToolBox.Text`. There is nothing special about it: both windows are in one program. (A bigger program keeps the data in one place and lets both windows read it.)

### Counting windows

`Application.OpenForms` is the collection of all the open forms of the program: 1 at the start, 2 with the tool, 1 again after the tool was closed. It is a good check in a test, and it is how a program finds out whether a window of a kind is already open.

### Closing

`setFormClosedEvent` runs after a window closed. The tool window uses it to clear the flag, so the next click opens a *new* window. The code only sets a flag: assigning another value to `oTool` inside the event would destroy the object while one of its own methods is running, and Ring refuses (*Trying to destroy the object using the self reference*). The next `openTool` makes a new window and puts it in `oTool`, and the old object is released then.

When the **main** window closes, its owned windows close with it, and the program ends when the last window is closed (the message loop runs on the main window).

> [!NOTE] The main window of a test program has to be in the variable `oForm`, because the test closes `oForm` when the test code ends.

## What you learned

- `Show(owner)` for a window that stays open,
- opening one copy,
- windows that call functions that change each other's controls,
- `OpenForms`,
- closing and the clean up of a window object.

## Exercises

1. Make the tool window remember its place: write `Left` and `Top` in the closed event (the tutorial [Settings](tut-32-settings.html)) and use them when it opens again.
2. Add a button *Close the tool* to the main window.
3. Open a modal dialog from the tool window with `ShowDialog` and see which windows can be used.
4. Make a second kind of tool window (a *Colors* window) and keep one copy of each.

## Next

[A tray icon](tut-155-tray.html)
