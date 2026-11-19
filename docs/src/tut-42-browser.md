---
title: "Tutorial 42: A folder browser"
lead: A tree of folders on the left, the files of the chosen folder on the right, and the totals at the bottom. A small Explorer, with TreeView and ListView.
---

## What you will learn

- `TreeView` and its nodes, and the `Tag` property,
- `ListView` in details mode with columns,
- building a tree from folders recursively,
- reacting to the user's choice,
- formatting file sizes.

## The controls

| Control | Shows | You use |
|---|---|---|
| `TreeView` | a hierarchy | `Nodes`, `Node.Nodes`, `SelectedNode`, event `AfterSelect` |
| `ListView` | a list with columns | `View = "Details"`, `Columns`, `Items`, `ListViewItem.SubItems` |

## The program

{{file:docs/tutorials/g42_browser.ring}}

![The folder browser](img/shots/tut-g42.png "Folders on the left, the files of Projects > Ring on the right")

{{output:docs/tutorials/g42_browser.ring --selftest}}

## How it works

### A demo folder

`makeDemoFolder` creates folders and files in the temp folder, so the tutorial can show a result and be tested anywhere. Give the program a real folder as its first argument to browse it: `ring g42_browser.ring "C:\Users\you\Documents"`.

### Building the tree

`addFolderNode(nodes, folder)` makes one node for the folder and then calls **itself** for every subfolder: that is *recursion*, the natural way to walk a tree. Folders are sorted so the order is stable. The important line:

```ring
oNode.Tag = cFolder
```

`Tag` is a free property that can hold *anything*: here the **full path** of the folder. The node's `Text` is only the name; when the user picks a node, the program reads its `Tag` to know which folder it is.

> [!TIP] For a very big tree, build only the first level and add the subfolders when a node is *expanded* (event `BeforeExpand`). Walking a whole disk at start would take too long.

### Reacting to the choice

`setAfterSelectEvent("folderChosen()")` runs when a node is selected. The function reads `oTree.SelectedNode.Tag`, clears the list, and adds a `ListViewItem` for every file: `new ListViewItem().New_([ :text = name ])` makes the row with its first column, and `SubItems.Add(text)` fills the other columns (size, modified date).

### The ListView

`View = "Details"` shows columns like Explorer; `Columns.Add([ :text = "Name", :width = 180 ])` adds a column with a title and a width in pixels; `FullRowSelect` highlights a whole row; `GridLines` draws lines. A `ListView` can also show icons (`LargeIcon`, `SmallIcon`, `List`).

### File sizes

`sizeText` turns `1536` into `1.5 KB`. `uiNumber(...)` formats a number without Ring's fixed two decimals (otherwise `1.5` would be written `1.50`).

### Testing

The test checks the tree (one root, three subfolders), selects a node by code (`oTree.SelectedNode = ...`, which raises the same event as a click), and checks the list and the status line. It also tests `sizeText` as a plain function.

## What you learned

- recursion builds a tree,
- `Tag` carries data on a node,
- `ListView` details mode,
- selection events fill the other control.

## Exercises

1. Show an icon for folders and files (an `ImageList`).
2. Sort the list when the user clicks a column header (`ColumnClick`).
3. Open a file with a double-click (`Process.Start` with `UseShellExecute = True`).
4. Add a **Refresh** button that reloads the tree.

The full-size version is the [FileExplorer](gallery-apps.html#file-explorer) application.

## Where to go next

This was the last tutorial of the chapter **Windows Forms**. The next chapter is **WPF**: it starts with [Tutorial 15: WPF](tut-15-wpf.html). The [Tutorials](tutorials.html) page lists all the chapters, and you can start any of them.
