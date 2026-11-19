---
title: "A tray icon"
lead: Some programs live in the notification area next to the clock: they hide their window, show an icon with a menu, and come back when the user double-clicks it. This lesson uses NotifyIcon, a context menu, Hide and Show, and a balloon message.
---

## What you will learn

- `NotifyIcon`: the icon, the tip (`Text`) and `Visible`,
- the **icon** (`SystemIcons`),
- a `ContextMenuStrip` with `Open` and `Quit`,
- `Hide()` and `Show()` for the window,
- the **balloon** message (`ShowBalloonTip`),
- removing the icon when the program ends.

The tutorial [Closing a window](tut-137-closing.html) and the tutorial [More than one window](tut-149-windows.html) used `Close`, `Hide` and `Show`. A tray program hides its window instead of closing it.

## The program

{{file:samples/UsingDotNet/tutorials/ch10_tray.ring}}

{{output:samples/UsingDotNet/tutorials/ch10_tray.ring --selftest}}

## How it works

### The icon

A `NotifyIcon` needs an `Icon`: a small picture. `new SystemIcons().Application` is the standard application icon; a program with its own icon loads it from an `.ico` file. `Text` is the tip that appears when the mouse rests on the icon (at most 63 characters), and `Visible = True` puts the icon in the tray. An icon that is not visible is not shown at all.

### The menu

The right click shows the `ContextMenuStrip` of the icon. `Items.Add("Open")` adds an item and returns it, and `setClickEvent` gives it code. The double click on the icon has its own event, `DoubleClick`, and both call `showFromTray`. The menu item **Quit** closes the form, which ends the program.

### Hide and show

`oForm.Hide()` takes the window off the screen and off the taskbar, without closing it: the program goes on running, and the controls keep their values. `Show(NULL)` and `Activate()` bring it back in front. This is different from *minimizing*, where the window stays on the taskbar.

### The balloon

`ShowBalloonTip` shows a short message from the icon: a title, a text, an icon (`Info`, `Warning`, `Error`) and a time in milliseconds. Windows may show it as a notification and the user can switch these off, so a balloon is for information that is nice to have. The program does not show one in a test.

### Remove the icon

The tray keeps the icon of a program that ended without removing it, until the mouse moves over it. The `FormClosed` event sets `Visible = False` and calls `Dispose()` so the icon goes away with the program.

### The test

The test checks the icon, the tip and the menu, hides the window and checks that the window is hidden and the icon is not, then brings the window back through `showFromTray` and through the menu item (`PerformClick`). Nothing needs the real tray.

The checks of this program are in a separate file, `selftest/ch10_tray.ring`:

{{file:samples/UsingDotNet/tutorials/selftest/ch10_tray.ring}}

## What you learned

- a tray icon with a tip and a menu,
- hiding a window and bringing it back,
- the balloon message,
- removing the icon at the end.

## Exercises

1. Hide the window instead of closing it when the user clicks the X (the event `FormClosing` with `Cancel`; the tutorial [Closing a window](tut-137-closing.html)), and quit only from the menu.
2. Change the icon (draw one with `Graphics` on a 16 by 16 `Bitmap` and make an `Icon` of it).
3. Add a menu item that shows the time in a balloon.
4. Make the program start hidden in the tray.

## Next

[Menus, toolbars and shortcuts](tut-41-menus.html)
