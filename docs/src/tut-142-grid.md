---
title: "Editing a grid"
lead: A DataGridView can be a small spreadsheet: typed columns, cells that the user edits, a read-only total that the program fills, and a grand total that follows each change. This lesson builds an order grid with text, check box and combo box columns and reacts to the cell events.
---

## What you will learn

- columns with **types**: `DataGridViewTextBoxColumn`, `...CheckBoxColumn`, `...ComboBoxColumn`,
- adding rows with the values of the cells (`Rows.Add`),
- reading and writing a cell: `Rows.Item(row).Cells.Item(column).Value`,
- the **CellValueChanged** event and `RowIndex`,
- committing a check box or a combo box change at once,
- a **read-only** column that the program fills,
- a number that arrives as text, and a text that is not a number.

The tutorial [Layout and richer controls](tut-23-layout.html) showed a grid that is bound to a `DataTable`. Here the grid is *unbound*: it holds its own cells, and the program works with them directly.

## The program

{{file:docs/tutorials/g142_grid.ring}}

![The order grid](img/shots/tut-g142.png "The order grid with its totals")

{{output:docs/tutorials/g142_grid.ring --selftest}}

## How it works

### Columns with types

Each column is an object that is added to `oGrid.Columns`. A **text box column** lets the user type; a **check box column** shows a check box in each cell; a **combo box column** shows a drop-down list with the items you add to the column (`Items.Add`). `Name` is how the program finds the column, `HeaderText` is the title, and `ReadOnly = True` makes the column not editable: the *Total* column is only filled by the program.

### Rows and cells

`Rows.Add([ "Pens", 10, 2.5, False, "Small", "" ])` adds a row, with one value for each column in the order of the columns. A cell is found by the row number (from 0) and the column **name**: `Rows.Item(0).Cells.Item("Qty").Value`. The value of a cell is whatever was put into it: a number, a text, a boolean. When the *user* types into a text cell the value is a **text**, so the functions `cellText` and `cellNumber` convert.

### A number from a text

`0 + "12"` is 12, and `0 + "abc"` raises a Ring error. `cellNumber` wraps the conversion in `try` and `catch` and answers 0 for a text that is not a number, so a typo in a cell does not stop the program: the total of that row is just 0. (A real program would also show a message or mark the cell.)

### Events

`setCellValueChangedEvent("rowChanged(aDotNetArgs[2].RowIndex)")` runs after a cell changed. The event arguments have `RowIndex` and `ColumnIndex`. `rowChanged` calculates the total of the row (quantity times price, plus 5 for express, plus 10 percent for the size Large), writes it into the *Total* cell, and shows the grand total in the label. Writing the total raises the event again, which is why the function writes only when the new text is different: it stops after one round.

A check box or a combo box cell keeps the change *pending* until the cell loses the focus. `CurrentCellDirtyStateChanged` with `CommitEdit` makes the change count at once, so the total follows the click.

### Rounding

`50 * 1.1` is `55.00000000000001` in a double. `shortNumber` rounds to two decimals and writes a whole number without decimals, so the cell shows `55` and `31.90`.

### The test

The test changes cells like a user: a quantity, a check box, a size, a wrong price. After each change it reads the *Total* cell and the label. A new row is added, calculated and counted. Because the logic is in `rowChanged` and `cellNumber`, the test does not need the mouse.

## What you learned

- typed columns and read-only columns,
- adding rows, reading and writing cells,
- `CellValueChanged` and committing edits,
- converting cell values safely,
- a grand total that follows the changes.

## Exercises

1. Add a button **Delete row** that removes the selected row (`Rows.RemoveAt`) and updates the sum.
2. Add a column *Discount* (a combo box with 0, 5 and 10 percent) and use it in the total.
3. Show a red background for a row whose quantity is not a number (`DefaultCellStyle.BackColor`).
4. Sort by the *Total* column when the user clicks its header (`SortMode`).

## Next

[A small text editor](tut-13-editor.html)
