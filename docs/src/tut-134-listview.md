---
title: "A list with columns"
lead: A ListView in details view shows rows with columns, check boxes and a header that can be clicked. This lesson builds a task list, sorts it by clicking a column header, counts the checked rows and removes them, keeping the data in a Ring list.
---

## What you will learn

- `ListView` in the **details** view, with `Columns`,
- rows (`ListViewItem`) and their cells (`SubItems`),
- `FullRowSelect`, `GridLines` and `CheckBoxes`,
- the event of a click on a **column header** and its arguments,
- sorting: the data is a Ring list, the view only shows it,
- comparing text with `strcmp`,
- removing the checked rows.

The tutorial [A folder browser](tut-42-browser.html) filled a `ListView` with files. This lesson makes the list work: sorting, checking and removing.

## The program

{{file:docs/tutorials/g134_listview.ring}}

![The task list](img/shots/tut-g134.png "The task list")

{{output:docs/tutorials/g134_listview.ring --selftest}}

## How it works

### Columns and rows

`View = "Details"` shows the columns. `Columns.Add([ :text = "Task", :width = 220 ])` adds a column with a title. A row is `new ListViewItem().New_([ :text = cName ])`: its text is the first cell, and `SubItems.Add(text)` adds the others. `Items.Add(item)` puts the row into the list. `Items.Item(0)` is the first row (counted from 0) and `SubItems.Item(2)` its third cell. `CheckBoxes = True` puts a check box in front of each row, and `Checked` is true when it is on.

### The data is the list

The program keeps the tasks in a Ring list `aTasks`, and `fillList` clears the `ListView` and creates the rows again. Sorting then means *sorting the list and filling the view again*; removing a row means removing the item from the list. The view never has information that the list does not have, so the two cannot disagree.

### The click on a header

`setColumnClickEvent("sortBy(aDotNetArgs[2].Column)")` runs the code when the user clicks a header. The variable `aDotNetArgs` is `[sender, eventArgs]` and the event arguments of this event have the number of the column. The same column again turns the order around (`lAscending`); another column starts with the ascending order. The test calls `sortBy` itself, because a test cannot click a header.

### Comparing text

The signs `<` and `>` compare **numbers** in Ring; with text they raise an error. `strcmp(a, b)` compares two texts and gives a number: less than 0 when `a` is first, 0 when they are the same, more than 0 when `a` is later. The function `goesAfter` joins each cell with `""` first, so numbers (the priority) and text (the name, the date) use the same code. Dates written as *year-month-day* sort correctly as text, which is one of the reasons for this form.

> [!NOTE] This is a simple bubble sort, enough for a list of a few hundred rows. For a big list sort with `sort()` of Ring (`sort(aList, 3)` sorts a list of lists by the third item) or use the `DataGridView` of the tutorial [Layout and richer controls](tut-23-layout.html).

### Checked rows

`setItemCheckedEvent` runs when a check box changes; the code shows the number of tasks and of checked rows in the status label. `removeChecked` goes through the rows, keeps the tasks of the rows that are **not** checked and fills the view again.

## What you learned

- the details view with columns, cells and check boxes,
- the header click event and `aDotNetArgs`,
- a Ring list as the data and a view that only shows it,
- sorting with `strcmp`,
- removing the checked rows.

## Exercises

1. Show a small arrow in the title of the sorted column (`oList.Columns.Item(0).Text = "Task ▲"`).
2. Add a text box that filters the rows: only tasks that contain the typed text are shown (keep the full list in `aTasks` and fill the view from a filtered copy).
3. Show a message with the selected task when the user double-clicks a row (the event `DoubleClick` and `SelectedItems`).
4. Use `sort(aTasks, 2)` of Ring for the sort by priority and compare the code with `sortBy`.

## Next

[Editing a grid](tut-142-grid.html)
