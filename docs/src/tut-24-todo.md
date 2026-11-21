---
title: "A project: a to-do list that remembers"
lead: A complete small application — add, tick and remove tasks, see how many are done, and find them again the next time the program starts. Windows Forms, JSON and files together.
---

## What you will learn

- planning a small application: data, window, behavior, saving,
- a `CheckedListBox`,
- saving to JSON and loading it again,
- keeping a window and its data in step.

## The design

| Part | Decision |
|---|---|
| **Data** | the tasks live in the list control itself; each has a text and a done flag |
| **Window** | a text box and *Add* / *Remove* buttons on top, the list in the middle, a status line at the bottom |
| **Behaviour** | *Add* ignores blank text; clicking an item ticks it; the status says "n of m done" |
| **Saving** | after every change the tasks are written to a JSON file; at start-up the file is read |

## The program

{{file:samples/UsingDotNet/tutorials/ch12_todo.ring}}

![The to-do list](img/shots/tut-g24.png "Two of three tasks are done")

{{output:samples/UsingDotNet/tutorials/ch12_todo.ring --selftest}}

## How it works

### The window

Remember the tutorial [A small text editor](tut-13-editor.html): the control that fills the window is added **first**, then the top panel and the status label (the helpers `uiPanel`, `uiLabel` and `Dock` do the rest). `CheckOnClick = True` makes one click tick or untick an item.

### Add and remove

`addTask` trims the text, ignores a blank one, adds `Items.Add([ :item = text, :isChecked = False ])` (the second parameter is the initial *checked* state), clears the text box, saves and refreshes the status. `removeTask` removes the selected item (`SelectedIndex` is `-1` when nothing is selected).

### Reacting to a tick

`setMouseUpEvent("tasksChanged()")` runs after the click, when the item's state is already up to date; the function saves and refreshes the status line. (The `ItemCheck` event runs *before* the state changes, which makes a status line show the old number.)

### Saving as JSON

The file holds a list of lists, one `[done, text]` per task: `[[1,"Buy milk"],[0,"Write the tutorial"]]`. `JsonSerializer.Serialize(aList)` writes it, and loading uses `JsonDocument`: `GetArrayLength()`, `Item(i)`, `GetInt32()`, `GetString()`.

### Starting and stopping

`loadTasks` runs before the window is shown. `setFormClosingEvent("saveTasks()")` saves once more when the window closes. While loading, a flag `lLoading` stops `saveTasks` from rewriting the file in the middle of the loading.

### Testing

`selfTest` adds tasks, ticks one, saves, clears the list, loads again and checks the contents, the JSON text and the status. It uses a separate file name when started with `--selftest`, so that it never touches your real list.

The checks of this program are in a separate file, `selftest/ch12_todo.ring`:

{{file:samples/UsingDotNet/tutorials/selftest/ch12_todo.ring}}

## What you learned

- design first: data, window, behavior, saving,
- `CheckedListBox`, events after a click,
- JSON for saving the tasks as a list of [done, text] pairs,
- a flag to avoid saving while loading,
- tests that use their own file.

## Exercises

1. Show the done tasks in gray (use `DrawItem`, or simply move done tasks to the bottom).
2. Add **Clear done** that removes all ticked tasks.
3. Save to the user's documents folder (`Environment.GetFolderPath("MyDocuments")`).
4. Add a due date to each task and sort by it.

The full-size version is the [TodoList](gallery-apps.html#todo-list) application.

## Next

[A project: Tic-Tac-Toe](tut-35-tictactoe.html)
