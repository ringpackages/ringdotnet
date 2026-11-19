---
title: "More input controls"
lead: A date picker, a slider, radio buttons, tool tips and an error marker are the controls that make a form pleasant to fill in. This lesson builds a booking form with all of them and tests it by changing the values like a user.
---

## What you will learn

- `DateTimePicker`: the date, the limits and the format,
- `TrackBar`: a slider with whole numbers and its change event,
- `RadioButton` and `GroupBox`: one choice out of a few,
- `ToolTip`: text that appears when the mouse rests on a control,
- `ErrorProvider`: an error icon with a message next to a control,
- keeping the price in **one function** that the controls call.

The tutorial [A form with many controls](tut-12-controls.html) used text boxes, a combo box and check boxes. These are the other controls that you find in most forms.

## The program

{{file:samples/UsingDotNet/tutorials/ch10_inputs.ring}}

![The booking form](img/shots/tut-g128.png "The booking form")

{{output:samples/UsingDotNet/tutorials/ch10_inputs.ring --selftest}}

## How it works

### The date picker

`DateTimePicker.Value` is a `DateTime`. `MinDate` and `MaxDate` limit what the user can choose (here the year 2030), and the value is always kept inside them. `Format = "Short"` shows the date in the short form of the user's culture; `Long`, `Time` and `Custom` (with `CustomFormat`) are the others. To make a date the program uses `dnNew("DateTime",[ :year = 2030, :month = 5, :day = 10 ])`, and to show it `Value.Format("d MMMM yyyy")` (the tutorial [Dates and times](tut-103-dates-and-times.html)).

### The track bar

A `TrackBar` is a slider: `Minimum`, `Maximum`, `Value` and `TickFrequency` (the distance between the small marks). `setValueChangedEvent("showPrice()")` runs the code each time the value changes, whether the user moves the slider or the program sets `Value`. The label next to the slider shows the number, because the slider itself does not.

### Radio buttons

Radio buttons that have the same parent are one group: turning one on turns the others off. The three buttons are inside a `GroupBox`, which draws the frame with the title *Room*; a second group on the same form would be independent. `Checked` says which is on, and `setCheckedChangedEvent` runs the code on a change. (It runs for the button that was turned off as well, which is why `showPrice` only *reads* the state and does not toggle anything.)

### One function for the price

`roomPrice`, `roomName` and `total` are small functions that read the controls. `showPrice` and `book` call them, and so does the test. A price that is calculated in one place cannot be different in two places (the tutorial [A project: a to-do list that remembers](tut-24-todo.html) keeps its data the same way).

### Tool tips and error markers

`ToolTip.SetToolTip(control, text)` gives a control a tip. `ErrorProvider.SetError(control, text)` shows a small red icon next to the control, and the text appears when the mouse rests on the icon. An empty text removes it. This is better than a message box: the user sees *which* field is wrong and can go on typing.

### Testing

The test sets `oNights.Value = 7` as a user would move the slider, and the change event updates the label and the price. It checks that choosing *Double* turns *Single* off, that **Book** without a name sets the error text and does not book, and that with a name the error is gone and the booking line is right.

The checks of this program are in a separate file, `selftest/ch10_inputs.ring`:

{{file:samples/UsingDotNet/tutorials/selftest/ch10_inputs.ring}}

> [!NOTE] The names of the controls that the event code uses are global variables (the tutorial [Your first window](tut-11-first-window.html)). The button is kept in `oBook`, so the test does not need to count the controls of the form.

## What you learned

- the date picker with limits and formats,
- the track bar and its change event,
- radio buttons in a group box,
- tool tips and the error marker,
- a price that is calculated in one function.

## Exercises

1. Add a check box **Breakfast** that adds 8 per night.
2. Make the date picker choose the departure and show the number of nights from the arrival date.
3. Show a tool tip on each radio button with the price of the room.
4. Disable **Book** while the name is empty (the event `TextChanged` of the text box).

## Next

[The keyboard in a form](tut-146-keyboard.html)
