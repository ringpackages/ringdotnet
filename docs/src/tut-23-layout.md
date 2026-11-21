---
title: "Layout and richer controls"
lead: Make a window that looks right at every size, with a draggable split bar, tabs, a table of labels and a data grid that shows a filtered table.
---

## What you will learn

- the layout tools: `Dock`, `SplitContainer`, `TabControl`, `TableLayoutPanel`,
- `DataGridView` showing a `DataTable` through a `DataView`,
- connecting controls with events,
- two layout details that are worth knowing before you start.

## Layout in Windows Forms

Placing controls with x and y numbers (as in [Your first window](tut-11-first-window.html)) is fine for a small fixed window. A window that the user can resize needs **layout containers**:

| Tool | What it does |
|---|---|
| `Dock` | glue a control to an edge (`Top`, `Bottom`, `Left`, `Right`) or fill the rest (`Fill`) |
| `SplitContainer` | two panels with a bar the user can drag |
| `TabControl` / `TabPage` | pages with tabs |
| `TableLayoutPanel` | a grid of rows and columns |
| `FlowLayoutPanel` | controls placed one after the other, wrapping |
| `Anchor` | keep the distance to the edges when the window grows |

## The program

{{file:samples/UsingDotNet/tutorials/ch10_layout.ring}}

![The Details tab](img/shots/tut-g23.png "The Details tab: name, city and number of orders of the chosen customer")

![The Orders tab](img/shots/tut-g23-orders.png "The Orders tab: a data grid showing only Cy's orders")

{{output:samples/UsingDotNet/tutorials/ch10_layout.ring --selftest}}

## How it works

### SplitContainer

A `SplitContainer` has `Panel1` (left) and `Panel2` (right). You add controls to the panels: `oSplit.Panel1.Controls.Add(oList)`. Give each child `Dock = "Fill"` so that it follows its panel.

> [!WARNING] Set `SplitterDistance` **after** the container was added to the form. Before that, the container has its default size (200 pixels) and the position is relative to that: the bar jumps when the form's real size arrives.

### Tabs

Create a `TabPage` for each tab, set its `Text` (the title on the tab), and add the pages to `oTabs.TabPages`. The page is a container: add its controls to `oDetails.Controls`.

### TableLayoutPanel

A table with columns and rows. `oTable.Controls.Add([ :control = oTitle, :column = 0, :row = nRow ])` puts a control into a cell (named arguments, because this method has several versions). `Dock = "Fill"` makes the label fill its cell; `TextAlign = "MiddleLeft"` centers the text vertically.

### DataTable, DataView, DataGridView

- A **DataTable** is a table in memory: columns, rows.
- A **DataView** is a *window onto* a table, with a filter and a sort order. `oView.RowFilter = "Customer = 'Cy'"` hides every other row, with a SQL-like expression.
- A **DataGridView** shows data: `DataSource = oView`. Because the grid shows the *view*, changing the filter updates the grid by itself.

`oView.Count` is the number of rows that pass the filter. (Reading `oGrid.Rows.Count` right after changing the filter can show the old number, because the grid updates a moment later. Ask the view.)

### One list, many controls

`setSelectedIndexChangedEvent("customerChosen()")` runs when the user picks a customer. The function fills the labels and sets the filter: this *one* event keeps the whole window in step. Remember: the controls the event code uses are **global variables**.

## What you learned

- containers instead of pixel positions,
- `Dock`, `SplitContainer`, `TabControl`, `TableLayoutPanel`,
- `DataTable` → `DataView` → `DataGridView`,
- set the splitter after adding it, ask the view for counts.

## Exercises

1. Add a `FlowLayoutPanel` at the bottom with three buttons that wrap when the window is narrow.
2. Sort the grid by quantity when the user clicks a button (`oView.Sort = "Quantity DESC"`).
3. Add a text box that filters the *customer list* by what the user types.
4. Add a third tab with a `PictureBox` that shows the picture made in the tutorial [Images](tut-22-images.html).

## Next

[A list with columns](tut-134-listview.html)
