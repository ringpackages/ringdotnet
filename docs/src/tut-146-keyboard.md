---
title: "The keyboard in a form"
lead: A form feels right when the keyboard works: only digits in an age box, Enter for OK and Escape for Cancel, Tab in a sensible order, access keys on the labels and the text selected when a box gets the focus. This lesson sets all of them and tests them with real key presses.
---

## What you will learn

- the **KeyPress** event: `KeyChar` and `Handled`,
- `MaxLength`,
- `AcceptButton` and `CancelButton`: the buttons of the Enter and Escape keys,
- the **tab order** (`TabIndex`),
- **access keys**: the `&` in a label,
- selecting all the text when a box gets the focus (`Enter` event, `SelectAll`),
- typing keys in a test with `uiSendKeys`.

The tutorial [Drawing and animation](tut-14-animation.html) used `KeyDown` for a game. A data form uses the keyboard in other ways.

## The program

{{file:docs/tutorials/g146_keyboard.ring}}

![The keyboard form](img/shots/tut-g146.png "The form after OK was pressed")

{{output:docs/tutorials/g146_keyboard.ring --selftest}}

## How it works

### Only digits

`KeyPress` runs for each character that the user types, **before** it reaches the box. The event argument (`aDotNetArgs[2]`, passed to `filterKey`) has `KeyChar`, the character, and `Handled`: when the function sets `Handled = True` the character is thrown away. The function accepts the digits (codes 48 to 57) and the Backspace key (code 8) and refuses all the rest. This filter works for typing; text that is *pasted* does not go through `KeyPress`, so a real program also checks the value at the end (the `Validating` event, or the check in the OK button).

### MaxLength

`MaxLength = 3` limits the number of characters, whatever the user types or pastes. It is the simplest limit and needs no code.

### Enter and Escape

`oForm.AcceptButton = oOk` makes **Enter** press the OK button from any box; `CancelButton` makes **Escape** press Cancel. The test types Enter with the name empty and gets the message *Please fill in both boxes*; with the name typed, the same Enter shows the result. Escape closes the form. These two properties are all that a dialog needs.

### Tab order

The **Tab** key moves the focus to the control with the next `TabIndex`. Controls get the order in which they were added, and `TabIndex` makes it explicit: name, age, OK, Cancel. A form with a wrong tab order is a common reason for complaints. The test checks the order by pressing Tab in the name box and asking which control has the focus.

### Access keys

In a label the `&` underlines the next letter: `&Name` shows <u>N</u>ame (Windows draws the underline only after the user presses Alt, as in the picture), and **Alt+N** moves the focus to the control that follows the label in the tab order (a label itself cannot take the focus, so it passes it on). This is why each label is created just before its box. Buttons use the same marks (`&OK`) and press themselves.

### Select all on entering

The `Enter` event of a box (not the key!) runs when the box gets the focus; `SelectAll()` selects its text, so the user can type over it. Many programs do this for every text box.

### Typing keys in a test

`uiSendKeys(oForm, "1a2-3")` posts the keys to the focused control of **this form** through the real key processing, so `KeyPress`, `MaxLength`, `AcceptButton` and `Tab` work as they do for a user, and the keys can never reach another program. The test types the letters and the minus sign between the digits, and only `123` stays; two characters were refused (`nRejected` counts them: `a` and `-`). A fourth digit is stopped by `MaxLength`, and Backspace works because the filter lets it through. The keys that the helper types are lower case.

## What you learned

- filtering the characters of a box,
- Enter and Escape buttons,
- the tab order and access keys,
- select-all on entering,
- testing with real key presses.

## Exercises

1. Allow one decimal point in a box for prices, but only one.
2. Change the access keys: `&Name` and `N&ame` are different, and two labels with the same key move through the controls in turn.
3. Make the OK button disabled until both boxes have text.
4. Use the `Validating` event of the age box to refuse a value over 150.

## Next

[Layout and richer controls](tut-23-layout.html)
