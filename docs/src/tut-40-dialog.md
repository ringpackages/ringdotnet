---
title: "Your own dialog"
lead: Message boxes are not enough when you need several values. A dialog is a small modal window that asks for data and gives it back — with validation, default buttons, and a test that acts as the user.
---

## What you will learn

- what *modal* means and how `ShowDialog` works,
- building a dialog form with `OK` and `Cancel`,
- `AcceptButton`, `CancelButton` and `DialogResult`,
- validating input and keeping the dialog open,
- returning the answer to the caller,
- testing a modal dialog with a timer.

## Modal and modeless

A **modal** window blocks the window behind it until it is closed: the user must answer first. That is what you want when the program needs an answer *now* — a file name, a choice, a few settings. `form.ShowDialog()` shows a window modally and **waits**: the line after it runs only after the dialog closed, and it returns *how* it was closed (`"OK"` or `"Cancel"`). A **modeless** window (`Show()`) lets the user continue working elsewhere.

## The program

{{file:docs/tutorials/g40_dialog.ring}}

![The main window](img/shots/tut-g40-main.png "The main window shows the profile")

![The dialog](img/shots/tut-g40-dialog.png "The dialog: name, age, OK and Cancel")

{{output:docs/tutorials/g40_dialog.ring --selftest}}

## How it works

### A function that asks

`askProfile(name, age)` builds the dialog, shows it, and **returns** `[name, age]` or `""`. The rest of the program does not know that a window was involved: `editProfile` calls it, checks `islist(aAnswer)`, and uses the answer. A *dialog function* hides the window behind a plain call, which also makes the logic easy to follow and to test.

### Making it look like a dialog

| Property | Effect |
|---|---|
| `FormBorderStyle = "FixedDialog"` | a thin border, not resizable |
| `MaximizeBox = False`, `MinimizeBox = False` | no maximise or minimise buttons |
| `StartPosition = "CenterParent"` | opens in the middle of the main window |

### Default buttons

`oDialog.AcceptButton = oOk` makes the **Enter** key press OK; `CancelButton = oCancel` makes **Esc** press Cancel. A button with a `DialogResult` (`oCancel.DialogResult = "Cancel"`) closes the dialog by itself with that result.

### Validation

**OK** has its own code, `okPressed`: it checks the name. If it is empty the dialog **stays open**, shows a red message and puts the cursor back in the field (`Focus()`). Only a valid input sets `oDialog.DialogResult = "OK"`, which closes the dialog. Never let a dialog return bad data: the caller should be able to trust the answer.

### Reading the answer

After `ShowDialog(NULL)` returns, the controls still exist: read `oNameBox.Text` and `oAgeBox.Value`, then `Dispose()` the dialog. (`ShowDialog` has several versions, so the plain call passes `NULL`.)

### Testing a modal dialog

A modal dialog stops the test at `ShowDialog` — nobody will click. The trick is a **timer**: a Windows Forms timer keeps ticking *inside* the dialog's own message loop. The test starts a timer before `ShowDialog`; the timer acts as the user. Tick 1 types a blank name and presses OK (and the test checks that the dialog complained, and is still there); tick 2 types `Bob`, sets the age and presses OK, and stops the timer. The main test then checks that the answer was used.

## What you learned

- `ShowDialog` is modal: it waits and returns the result,
- `AcceptButton`, `CancelButton`, `DialogResult`,
- validate before closing with OK,
- a dialog function that returns data or `""`,
- a timer drives a modal dialog in a test.

## Exercises

1. Add a **Country** combo box to the dialog.
2. Show the current profile in the dialog title (`Edit profile - Ann`).
3. Add an **Apply** button that changes the main window without closing the dialog.
4. Use the standard dialogs for a change: `ColorDialog`, `FontDialog`, `FolderBrowserDialog` (they also use `ShowDialog` and return `"OK"`).

## Next

[Menus, toolbars and shortcuts](tut-41-menus.html)
