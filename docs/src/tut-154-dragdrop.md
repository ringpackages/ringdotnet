---
title: "Drag and drop"
lead: Users expect to drag an item from one place to another, and to drop files on a window. This lesson starts a drag from a list, accepts the drop in another list, chooses move or copy from the Ctrl key, accepts files, and tests the whole thing without a mouse.
---

## What you will learn

- the **source** side: `MouseDown` and `DoDragDrop`,
- the **target** side: `AllowDrop`, `DragEnter`, `DragOver` and `DragDrop`,
- the **data** (`DataObject`): a format and a value,
- the **effect**: `Copy`, `Move` or `None`, and the Ctrl key,
- dropping **files** from the explorer (the format `FileDrop`),
- making the event arguments yourself to test a drop.

## The program

{{file:samples/UsingDotNet/tutorials/ch10_dragdrop.ring}}

{{output:samples/UsingDotNet/tutorials/ch10_dragdrop.ring --selftest}}

## How it works

### The source starts the drag

The `MouseDown` event of the fruit list runs `beginDrag(x, y)`. `IndexFromPoint` finds the item under the mouse, and `DoDragDrop([ :data = item, :allowedEffects = "Copy, Move" ])` starts the operation: the mouse now carries the data, and **the call waits** until the user drops or cancels. Its result is the effect that the target chose. When it is `Move` the item is taken out of the source; for `Copy` it stays.

### The target decides

A control accepts drops only when `AllowDrop = True`. Then it gets **DragEnter** when the mouse with the data comes in, **DragOver** while it moves inside, and **DragDrop** when the button is released. In `DragEnter` and `DragOver` the program looks at what is carried (`e.Data.GetDataPresent("Text")`) and sets `e.Effect`: `Move` or `Copy` shows the matching mouse pointer, and `None` shows a forbidden sign and refuses the drop. The same function serves both events.

### Move or copy

The key state in the event arguments has a bit for each key: **8** is Ctrl. `(e.KeyState & 8) != 0` is true while Ctrl is held, and the program answers `Copy`; without Ctrl it answers `Move`. This is the rule of the file explorer. (Ring's `&` is the bit and.)

### The drop

`DragDrop` reads the data with `e.Data.GetData("Text")` and adds it to the basket once. When the item is already there the function sets `e.Effect = "None"`: the source sees that nothing was taken, and `beginDrag` does not remove the item.

### Files

A file dropped from the explorer arrives in the format **FileDrop**, and its data is a list of paths. `dropFiles` goes through the list with `toList()` and shows the file names (`Path.GetFileName`). A window or a list needs only `AllowDrop` and the two events; the paths are real, so the program can open the files.

### Testing without a mouse

A test cannot drag with a mouse, so it makes the arguments that .NET would make: `new DataObject().@New([ :format = "Text", :data = "banana" ])` is the data, and `new DragEventArgs(data, keys, x, y, allowed, effect)` is the event argument. The test calls `dragEnter` and `dragDrop` with them and reads `Effect` and the lists. The functions are the same that the events call. Only `beginDrag`, which starts a real drag, is not called by the test.

The checks of this program are in a separate file, `selftest/ch10_dragdrop.ring`:

{{file:samples/UsingDotNet/tutorials/selftest/ch10_dragdrop.ring}}

> [!NOTE] Ring code runs on the Ring thread, and the drag events do too, so the handlers can use the controls directly. `DoDragDrop` runs its own message loop until the drop, which is why events keep arriving during it.

## What you learned

- starting a drag and the meaning of its result,
- accepting a drop and choosing the effect,
- Ctrl for copy and the bit test `& 8`,
- dropping files,
- building the data and the arguments for a test.

## Exercises

1. Allow dragging from the basket back to the fruit list.
2. Show the drop position in the status (`e.X` and `e.Y`, converted with `PointToClient`).
3. Accept only files with the extension `.txt` and refuse the others in `DragEnter`.
4. Reorder the items of one list by dragging inside it (use `IndexFromPoint` on the drop point).

## Next

[Your own dialog](tut-40-dialog.html)
