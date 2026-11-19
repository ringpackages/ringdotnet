---
title: "WPF data binding"
lead: In WPF controls can follow each other without any code. A text box shows the value of a slider, a button switches on and off with a check box, a label shows the chosen item of a list. This lesson writes all of it in XAML with bindings and tests it from Ring.
---

## What you will learn

- a **binding**: a property that follows another property,
- `ElementName` and `Path`,
- `Mode=TwoWay` and `UpdateSourceTrigger=PropertyChanged`,
- `StringFormat` and `FallbackValue`,
- binding to `IsChecked` and to `SelectedItem.Content`,
- testing a window by changing a value and reading another.

The tutorial [WPF](tut-15-wpf.html) made one binding in code, and the tutorial [WPF layout and styles](tut-38-wpf-layout.html) wrote XAML. Here the bindings are in the XAML, so most of the work is done by WPF and the Ring code is short.

## The program

{{file:docs/tutorials/g131_wpf_binding.ring}}

![The binding window](img/shots/tut-g131.png "The binding window")

{{output:docs/tutorials/g131_wpf_binding.ring --selftest}}

## How it works

### A binding

`{Binding ElementName=amount, Path=Value}` means: *take the property `Value` of the element named `amount`*. It is written as the value of a property in XAML. The element needs an `x:Name`, and the property that has the binding follows it from then on, at the start and at each change. The Ring program only creates the window; moving the slider changes the text box, the progress bar and the text *without* any Ring event.

### Two directions

A binding to a property such as `ProgressBar.Value` goes one way: the slider is the **source** and the bar the **target**. A text box is also an input, so its binding says `Mode=TwoWay`: typing `40` changes the slider. `UpdateSourceTrigger=PropertyChanged` sends the text at each change; without it WPF waits until the text box loses the focus.

### Formats and fallbacks

`StringFormat=N0` formats the value as text with a format string (the tutorial [Formatting numbers and dates](tut-129-formatting.html)), so the slider value `75` appears as `75` and not `75.0000000001`. A format with braces starts with `{}` (`StringFormat={}{0:F0} percent`): the first pair tells the XAML parser that the text is not another binding. `FallbackValue` is shown when the path has no value; here, when nothing is chosen in the list.

### State and choice

`IsEnabled="{Binding ElementName=allow, Path=IsChecked}"` connects a button to a check box: unchecking switches the button off. `Path=SelectedItem.Content` follows the chosen item of a list and takes its text. These are the cases where a program without bindings needs an event for each control and a function that updates the others.

### The test

The test acts like the user: it sets the slider value, types into the text box, clears the check box and chooses an item, and after each step it reads the property that should have followed. The checks are the proof that the bindings are right.

> [!NOTE] The controls here are bound to each other. A binding to the *data* of your program (a list of objects) needs .NET objects that tell WPF when they change (`INotifyPropertyChanged`), which cannot be written in Ring; a program of this kind puts the values into the controls with code, as the tutorial [WPF](tut-15-wpf.html) does.

## What you learned

- the binding syntax with `ElementName` and `Path`,
- one-way and two-way bindings,
- `StringFormat` and `FallbackValue`,
- bindings between a check box and a button, and between a list and a text,
- a test that reads the result of the bindings.

## Exercises

1. Add a `Slider` for the width of a `Rectangle` and bind `Width` to its `Value`.
2. Bind the `Text` of a `TextBlock` to the `Text` of the text box, so that it shows what is typed.
3. Make a second slider and bind its `Value` to the first one with `Mode=TwoWay`.
4. Add a `ComboBox` instead of the list and bind to `SelectedItem.Content`.

## Next

[WPF animation](tut-70-wpf-animation.html)
