---
title: "WPF menus and tabs"
lead: Menus, tabs, a status bar, combo boxes, date pickers and expanders are the parts of most WPF windows. This lesson writes them in XAML, connects menu items to Ring code, shows and hides the status bar with a checkable item, and tests every part.
---

## What you will learn

- a `DockPanel` with a `Menu` at the top and a `StatusBar` at the bottom,
- `MenuItem`: `Header` (with `_` for the key), separators and `InputGestureText`,
- a **checkable** menu item and its `Checked` and `Unchecked` events,
- `TabControl`, `TabItem` and the `SelectionChanged` event,
- `ComboBox`, `DatePicker` and `Expander`,
- `Visibility`: `Visible` and `Collapsed`,
- clicking a menu item in a test by raising its `Click` event.

The tutorial [WPF layout and styles](tut-38-wpf-layout.html) used a `Grid`; this lesson uses the controls of a normal application window.

## The program

{{file:samples/UsingDotNet/tutorials/ch11_wpf_menu.ring}}

![The window with the menu and the tabs](img/shots/tut-g140.png "The window with the menu and the tabs")

{{output:samples/UsingDotNet/tutorials/ch11_wpf_menu.ring --selftest}}

## How it works

### The layout

A `DockPanel` places each child on a side of the window: the menu goes to the `Top` and the status bar to the `Bottom` (`DockPanel.Dock`), and the last child (the tab control) fills what is left. Everything that the program uses has an `x:Name`, so `wpfFind(oWindow, "name")` finds it.

### Menus

In `Header="_File"` the underscore marks the access key: the user presses Alt+F. A `MenuItem` inside another is a submenu entry; `<Separator/>` draws a line; `InputGestureText="Ctrl+N"` shows the shortcut text (a shortcut itself needs a *command*, which is written with an `InputBindings` element in XAML or a `KeyDown` handler). `setClickEvent("newOrder()")` runs Ring code when the item is chosen, as for a button.

### A checkable item

`IsCheckable="True"` gives the item a check mark, and `IsChecked` is its state. The events `Checked` and `Unchecked` run when the user (or the program) changes it. Here the item *Status bar* shows or hides the status bar by setting `Visibility` to `"Visible"` or `"Collapsed"`. `Collapsed` takes no space; `Hidden` (the other value) keeps the empty space.

### Tabs

A `TabControl` has `TabItem` children. Each one has a `Header` (the title of the tab) and a content: here a `StackPanel` with controls and a `TextBlock`. `SelectedIndex` says which tab is shown and can be set from the program; `SelectionChanged` runs when it changes. The event handler of a tab control also runs for the *list controls inside it* (a combo box raises its own `SelectionChanged`, and the event travels up), so a handler that shows the tab should check that the tab control raised it when the tabs hold lists.

### Combo box, date picker, expander

A `ComboBox` has items (`ComboBoxItem`); `IsSelected="True"` chooses one at the start, `SelectedIndex` chooses by number and `Text` reads the chosen text. A `DatePicker` has `SelectedDate` (a `DateTime`, empty until the user chooses) and a calendar drop-down. An `Expander` shows its content when `IsExpanded` is true: it keeps rarely used options out of the way.

### Testing

The test cannot click a menu with a mouse, so it raises the `Click` event of the item itself: `RaiseEvent(new RoutedEventArgs().New_([ :routedEvent = new MenuItem().ClickEvent ]))`. After each action it reads the property that should have changed: the status text, the `Visibility` of the status bar, the selected tab, the chosen speed. The menu item *New* resets the combo box and the check box, and the test checks that too.

The checks of this program are in a separate file, `selftest/ch11_wpf_menu.ring`:

{{file:samples/UsingDotNet/tutorials/selftest/ch11_wpf_menu.ring}}

## What you learned

- a window with a menu, tabs and a status bar in XAML,
- menu items, separators and a checkable item,
- tabs, combo boxes, date pickers and expanders,
- `Visibility`,
- testing menu items by raising `Click`.

## Exercises

1. Add a menu *Edit* with *Copy* and *Paste* that use the text of a `TextBox`.
2. Add a context menu to the text block of the *About* tab (`ContextMenu` inside the element).
3. Add a third tab with a `ListBox` and show the number of items in the status bar.
4. Make *Exit* close the window (`oWindow.Close()`).

## Next

[WPF lists and dynamic content](tut-148-wpf-lists.html)
