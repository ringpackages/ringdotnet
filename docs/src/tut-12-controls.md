---
title: "A form with many controls"
lead: Build a registration form with text boxes, a number box, a combo box, a check box and a list box, read what the user typed, and check it before accepting.
---

## What you will learn

- the common controls and their main properties,
- reading and changing what the user entered,
- validating input and giving feedback,
- finding controls in `Controls` for tests.

## The common controls

| Control | The user... | Main property |
|---|---|---|
| `Label` | reads text | `Text` |
| `TextBox` | types text | `Text` |
| `NumericUpDown` | picks a number | `Value`, `Minimum`, `Maximum` |
| `ComboBox` | picks one item of a drop-down list | `SelectedIndex`, `Text` |
| `CheckBox` | switches something on or off | `Checked` |
| `ListBox` | sees (and picks from) a list | `Items`, `SelectedIndex` |
| `Button` | clicks | `Text`, event `Click` |

## The program

{{file:docs/tutorials/g02_registration.ring}}

![The form, empty](img/shots/tut-g02.png "The registration form")

![The form after two people were registered](img/shots/tut-g02-filled.png "After registering Ann and Bob")

{{output:docs/tutorials/g02_registration.ring --selftest}}

## How it works

### Creating the controls

The helpers `uiTextBox`, `uiComboBox`, `uiCheckBox` and `uiListBox` create the control and add it to the form. `uiComboBox(oForm, x, y, width, aItems)` fills the drop-down list from a Ring list. A `NumericUpDown` has no helper, so it is created with the class and configured in braces:

```ring
oAge = new NumericUpDown() {
	Location = new Point(110,54)
	Size = new Size(80,24)
	Minimum = 1
	Maximum = 120
	Value = 30
}
oForm.Controls.Add(oAge)
```

The control only appears in the window after `oForm.Controls.Add(...)`.

### Reading what was entered

| Question | Code |
|---|---|
| what was typed? | `oName.Text` |
| what number? | `oAge.Value` |
| which item is chosen? | `oCountry.Text` (or `SelectedIndex`: `-1` means nothing) |
| is it ticked? | `oNewsletter.Checked` |

### Validation

`register()` checks the input **before** using it: an empty name or no country shows a message in `oResult` and returns. Check, tell the user what is wrong, and only then do the work. `trim()` removes spaces, so a name of three spaces counts as empty.

### The list box

`oPeople.Items.Add(cLine)` adds a line; `Items.Count` counts. The text is built from the pieces: name, age, country, and `(newsletter)` if the box is ticked.

### Testing the form

The test finds the **Register** button with `oForm.Controls.Item(7)` — the seventh control added — and calls `PerformClick()`. Then it checks the messages and the list. Controls are numbered in the order they were added, starting at 0.

## What you learned

- controls are objects; read and write their properties,
- `Items`, `Checked`, `Value`, `SelectedIndex` for the common ones,
- validate first, then act,
- `PerformClick()` lets a test press a button.

## Exercises

1. Clear the age and country after a registration.
2. Refuse ages under 18 with a message.
3. Add a `RadioButton` pair (`Male`/`Female`) in a `GroupBox` and add the choice to the line.
4. Add a **Remove** button that deletes the selected person (`oPeople.Items.RemoveAt(...)`).

## Next

[Layout and richer controls](tut-23-layout.html)
