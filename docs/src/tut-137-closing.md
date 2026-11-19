---
title: "Closing a window"
lead: A program that has unsaved changes should ask before the window closes. This lesson uses the FormClosing event to ask Save, Don't save or Cancel, cancels the close when the user cancels, and shows what runs after the window has closed.
---

## What you will learn

- the **FormClosing** event, which runs *before* the window closes,
- the event argument `Cancel` that keeps the window open,
- a flag for *changes that are not saved* (`TextChanged`),
- the three answers of the question: Yes (save), No (do not save), Cancel,
- the **FormClosed** event, which runs after the close,
- a test that answers the question itself.

Every editor, every form that has data, asks before it closes. This is the pattern.

## The program

{{file:samples/UsingDotNet/tutorials/ch10_closing.ring}}

{{output:samples/UsingDotNet/tutorials/ch10_closing.ring --selftest}}

## How it works

### Remember the changes

The text box has the event `TextChanged`; its code sets the global `lChanged` to true and writes a message in the status label. `saveNow` writes the file and sets `lChanged` to false. The program asks about changes only when `lChanged` is true, so a user who did not change anything is never asked.

### FormClosing

`setFormClosingEvent("onClosing()")` runs `onClosing` each time the form is about to close: the user clicked the X, pressed Alt+F4, or the program called `Close()`. The event arguments are `aDotNetArgs[2]`, and `aDotNetArgs[2].Cancel = True` **stops the close**. The function asks the question with a message box with the buttons Yes, No and Cancel; Yes saves and lets the form close, No lets it close without saving, and Cancel sets `Cancel`. When there are no changes the function returns at once and the form closes.

### FormClosed

`setFormClosedEvent` runs *after* the form closed. It is too late to stop the close, but it is the place to release things (a timer, a file, a connection). The test uses it to know that the form really closed: after the answer Cancel `lClosed` is false, after Yes it is true.

### A question that a test can answer

A message box waits for a person, so the function `askSave` first looks at `cTestAnswer`: when a test has set it, that is the answer. The test sets `"Cancel"` and calls `oForm.Close()`: the form stays open, was asked once, and nothing was written. Then it sets `"Yes"` and closes again: the file has the new text, the flag is false and the form closed. The same function asks a real person when `cTestAnswer` is empty. Writing a question as a function with an answer that can be set from outside is the way to test any program that waits for the user.

The checks of this program are in a separate file, `selftest/ch10_closing.ring`:

{{file:samples/UsingDotNet/tutorials/selftest/ch10_closing.ring}}

> [!NOTE] `Close()` on a form that was shown with `ShowDialog` also raises `FormClosing`; the dialog result is set by the button. A form that was **hidden** with `Hide()` is not closed and does not raise the event.

## What you learned

- `FormClosing` and `Cancel`,
- a flag for unsaved changes,
- the Yes, No and Cancel answers,
- `FormClosed` for the clean up,
- a question that a test can answer.

## Exercises

1. Show the changes flag in the title of the window (`Notes *`) while there are changes, as editors do.
2. Add a **New** button that asks the same question before it clears the text.
3. Remember the position and the size of the window in the `FormClosing` event (the tutorial [Settings](tut-32-settings.html)) and restore them at the start.
4. Ask the question with the text of the changes in it (how many characters were added).

## Next

[More than one window](tut-149-windows.html)
