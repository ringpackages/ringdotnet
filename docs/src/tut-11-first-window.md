---
title: "Your first window"
lead: Build a window in four small steps — an empty form, a label and a button, an event that counts clicks, and the same program written without the helper functions.
---

## What you will learn

- the parts of a Windows Forms program: runtime, form, controls, events, message loop,
- the helper functions `uiForm`, `uiLabel`, `uiButton`, `uiRun`,
- why event code can only see global variables,
- what the helpers do, by writing the program without them.

## Windows Forms in one minute

**Windows Forms** is the classic way to build desktop windows in .NET. A window is a **Form**. Things in it — labels, buttons, text boxes — are **controls**. A control is an object with properties (`Text`, `Location`, `Size`) and events (`Click`). The program runs a **message loop**: it waits for the user to do something, runs your code, and waits again until the window closes.

## Step 1: the smallest window

{{file:docs/tutorials/g01a_window.ring}}

![The empty window](img/shots/tut-g01a.png "Step 1: a window with a title")

- The `using { }` block comes **first**. Because it names `System.Windows.Forms`, it starts the Windows desktop runtime and makes the Ring thread suitable for windows (this is what `dnUseDesktop()` does).
- `uiForm("My first window",320,120)` makes a form with a title and a client area of 320 × 120 pixels, centred on the screen.
- `uiRun(oForm)` shows the window and waits. The program continues after the window is closed.
- `uiTest` and `uiEnd` make the program test itself when started with `--selftest`; you can ignore them for now.

## Step 2: a label and a button

{{file:docs/tutorials/g01b_controls.ring}}

![A label and a button](img/shots/tut-g01b.png "Step 2: controls")

`uiLabel(parent, text, x, y, width, height)` and `uiButton(parent, text, x, y, width, height, code)` create a control and put it into the form. The position `x, y` is measured in pixels from the top-left corner of the form. The last argument of `uiButton` is the Ring code to run when the button is clicked; here it is empty, so the button does nothing yet.

## Step 3: the button does something

{{file:docs/tutorials/g01c_counter.ring}}

![The counter after three clicks](img/shots/tut-g01c-clicked.png "Step 3: after three clicks")

{{output:docs/tutorials/g01c_counter.ring --selftest}}

### The important rule: events see only globals

`"clicked()"` is a **text** of Ring code. Ring runs it later, when the user clicks, *outside* the place where it was written. At that moment the local variables of `main` are gone. Therefore:

> [!WARNING] The code of an event can only use **global variables**. Create the controls and the data of the program as globals at the top of the file (`oLabel = ""`, `nClicks = 0`), then fill them inside `func main`.

`clicked()` is an ordinary function. It changes the counter and writes the new text into the label (`oLabel.Text = ...`). Assigning to a **property** (`Text`) changes what you see.

### The program tests itself

`selfTest()` clicks the button three times with `PerformClick()` and checks the label with `dnAssert`. Run `ring g01c_counter.ring --selftest` and the window opens, clicks, checks and closes by itself; the output is the one above. The same idea tests every sample and application of the package.

## Step 4: without the helpers

The helpers are only short-cuts. This program builds the same window with the real classes, so you can see what is going on:

{{file:docs/tutorials/g01d_plain.ring}}

![The same program without helpers](img/shots/tut-g01d.png "Step 4: the plain version")

| Helper | What it really does |
|---|---|
| `uiForm(title,w,h)` | `new Form()`, then `Text`, `ClientSize = new Size(w,h)`, `StartPosition = "CenterScreen"` |
| `uiLabel(...)` | `new Label()`, then `Text`, `Location = new Point(x,y)`, `Size`, then `oForm.Controls.Add(...)` |
| `uiButton(...)` | `new Button()`, the same, and `setClickEvent(code)` |
| `uiRun(oForm)` | `Application.EnableVisualStyles()` and `Application.Run(oForm)` (the message loop) |

Note how the properties are written inside **braces**: `new Label() { Text = "..." }` means "create the label and set these properties". The `StartPosition` is an **enum**, written as a text: `"CenterScreen"`.

## What you learned

| Idea | Example |
|---|---|
| start the desktop runtime first | `using { "System.Windows.Forms" }` |
| a form and controls | `uiForm`, `uiLabel`, `uiButton` |
| positions and sizes in pixels | `20, 15, 280, 24` |
| an event is Ring code in a text | `"clicked()"` |
| events see only globals | `oLabel`, `nClicks` at the top |
| the same without helpers | `new Form() { ... }` |

## Exercises

1. Add a third button, `Add 10`, that adds ten to the counter.
2. Make the label red when the counter is above 5 (`oLabel.ForeColor = new Color().Red`).
3. Add a second label that shows `even` or `odd`.
4. Change the form so that it cannot be resized (`FormBorderStyle = "FixedDialog"`, `MaximizeBox = False`).

## Next

[A form with many controls](tut-12-controls.html)
