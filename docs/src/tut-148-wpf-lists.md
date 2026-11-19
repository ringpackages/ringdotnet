---
title: "WPF lists and dynamic content"
lead: Most windows show a list that changes while the program runs. This lesson fills a ListBox from Ring, adds, removes and moves items, uses the selection, and builds a button for each item in code, so that the window follows the data.
---

## What you will learn

- the `Items` collection: `Add`, `Insert`, `RemoveAt`, `Clear`, `Count`,
- `SelectedIndex` (and `-1` for nothing),
- moving an item: take it out and put it in at a new place,
- creating controls **in code** and adding them to a panel (`Children`),
- keeping the window in step with the data with one `refresh` function,
- clicking buttons in a test.

The tutorial [WPF menus and tabs](tut-140-wpf-menu.html) wrote a fixed window in XAML. Here the XAML has an empty list and an empty panel, and the program fills them.

## The program

{{file:samples/UsingDotNet/tutorials/ch11_wpf_lists.ring}}

![The list window](img/shots/tut-g148.png "A list with the buttons that the program made")

{{output:samples/UsingDotNet/tutorials/ch11_wpf_lists.ring --selftest}}

## How it works

### The Items collection

`listBox().Items` is the list of the items of a `ListBox`. `Add(text)` adds an item at the end, `Insert(index, item)` puts one at a place, `RemoveAt(index)` removes one, `Clear()` removes all, and `Count` and `Item(index)` read it. The items here are texts, but a list can hold any object. `Insert` has two values in a fixed order, so it is called with two plain values and not with names.

### The selection

`SelectedIndex` is the number of the selected item, counted from 0, and **-1** when nothing is selected. `removeItem` and `moveItem` start by looking at it, and do nothing when there is no selection: the test checks that too. After a move the program sets `SelectedIndex` to the new place, so the user can press *Up* again.

### Moving an item

There is no *move* method, so the function takes the item out (`RemoveAt`), puts it in at the new place (`Insert`) and selects it. The edges are checked first: the first item cannot go up and the last cannot go down.

### One refresh

After each change the program calls `refresh`, which sets the count text and makes the buttons again. The window is a **picture of the data**, and there is one function that draws it. A program that updates the count in five different places forgets one of them.

### Controls made in code

`oChips.Children.Clear()` removes the old buttons, and a loop makes one `wpfButton(text, code)` for each item, sets its `Margin` and adds it with `Children.Add`. The code of each button is a text that includes the number of the item (`"showItem(" + i + ")"`), so the button knows which item it shows. A `WrapPanel` puts the buttons in a row and starts a new row when the row is full.

### The test

The test acts like the user: it types into the text box and clicks **Add** three times, checks the items, the count and the buttons, clicks one of the made buttons, selects an item and moves it, removes the selected item, and clears the list. Buttons are clicked by raising their `Click` event (`RaiseEvent`), as in the tutorial [WPF layout and styles](tut-38-wpf-layout.html).

The checks of this program are in a separate file, `selftest/ch11_wpf_lists.ring`:

{{file:samples/UsingDotNet/tutorials/selftest/ch11_wpf_lists.ring}}

## What you learned

- adding, inserting, removing and clearing items,
- the selection and its `-1`,
- one function that keeps the window in step with the data,
- controls that the program makes and adds to a panel.

## Exercises

1. Add a button that sorts the items (read them into a Ring list, `sort` it, fill the list again).
2. Show the number of the selected item in the count text when the selection changes (`setSelectionChangedEvent`).
3. Make each chip remove its item when it is clicked.
4. Add an *Undo* button that remembers the last removed item.

## Next

[WPF animation](tut-70-wpf-animation.html)
