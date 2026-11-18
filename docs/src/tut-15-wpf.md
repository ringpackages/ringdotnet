---
title: "Tutorial 15: WPF"
lead: WPF is the newer Windows UI framework. A window is described in XAML, a text format of elements and attributes; this lesson loads a XAML window, reacts to events and binds a slider to a text.
---

## What you will learn

- the difference between WPF and Windows Forms,
- XAML,
- finding elements by name,
- events,
- data binding.

## WPF and Windows Forms

| | Windows Forms | WPF |
|---|---|---|
| Layout | positions in pixels | panels that arrange their children (`StackPanel`, `Grid`) |
| Description | code only | XAML text *or* code |
| Look | classic Windows controls | any look: shapes, brushes, animation |
| Best for | simple tools, quick results | modern, scalable UIs |

Both work from Ring with the same ideas: objects, properties, events.

## The program

{{file:docs/tutorials/g05_wpf.ring}}

![The window after Greet and after moving the slider](img/shots/tut-g05-greeted.png "After pressing Greet and moving the slider")

{{output:docs/tutorials/g05_wpf.ring --selftest}}

## How it works

### XAML

XAML is XML where each element is a WPF object and each attribute is a property:

```xml
<Button x:Name="greet" Content="Greet" Margin="0,8,0,0"/>
```

means "a `Button`, named `greet`, with the content `Greet`, and a margin on top". `<StackPanel>` is a *panel* that stacks its children vertically. The `Window` element is the window. The program builds the XAML text and calls `wpfXaml(text)`, which creates all the objects.

> [!NOTE] WPF has classes with the same names as Windows Forms ones. In RingDotNet the **WPF** version of a clashing name starts with `Wpf`: `WpfButton`, `WpfTextBox`, `WpfBinding`. The others keep their name (`Window`, `Slider`, `Ellipse`).

### Finding elements

`x:Name="nameBox"` gives an element a name; `wpfFind(oWindow,"nameBox")` returns the object. Keep the ones you need in global variables.

### Events

`setClickEvent("code")` works as in Windows Forms. `setValueChangedEvent` runs when the slider moves; here it sets the width and height of the circle from `oSlider.Value`.

### Data binding

A *binding* connects a property of one element to a property of another, with no code in between:

```ring
oBinding = new WpfBinding().New_1("Value")      # the property to follow: Value
oBinding.Source = oSlider                       # whose property
oValue.SetBinding(oValue.TextProperty,oBinding) # the Text of this block follows it
```

Move the slider and the text changes by itself. In the test: `oSlider.Value = 100`, then the text is `100`.

### Running

`wpfRun(oWindow)` shows the window and waits. `wpfTest` and `wpfEnd` are the self-test helpers, like `uiTest` and `uiEnd`.

## What you learned

- WPF windows can be described in XAML,
- `wpfXaml`, `wpfFind`, `wpfRun`,
- events work as before,
- bindings keep elements in sync without code.

## Exercises

1. Add a `CheckBox` named `shout` and make the greeting upper case when it is ticked.
2. Add a `ProgressBar` and bind its `Value` to the slider as well.
3. Change the circle's colour with a second slider (`Brush`).
4. See the WPF [samples](gallery-wpf.html) for shapes, grids, menus, tabs and timers.

## Next

[Tutorial 16: A web service with a database](tut-16-web-service.html).
