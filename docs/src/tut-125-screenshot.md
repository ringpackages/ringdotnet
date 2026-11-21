---
title: "Screens and pictures of windows"
lead: A program can ask about the screens of the computer and take a picture of a part of the screen or of one of its own controls. This lesson uses Screen, CopyFromScreen and DrawToBitmap, and reads the pixels of the result to check how a window looks.
---

## What you will learn

- the `Screen` class: the primary screen, its size and its working area,
- taking a picture of a part of the screen with `Graphics.CopyFromScreen`,
- taking a picture of a control with `DrawToBitmap`,
- reading pixels with `GetPixel` to check a window,
- why the program prints yes and no for the facts of the screen.

The tutorial [Images](tut-22-images.html) made pictures from nothing. Here the pictures come from the screen and from windows. These classes are part of Windows Forms, so the lesson needs Windows.

## The program

{{file:samples/UsingDotNet/tutorials/ch10_screenshot.ring}}

{{output:samples/UsingDotNet/tutorials/ch10_screenshot.ring}}

> [!NOTE] This program uses a generic function (`dnStatic`) where a class cannot be used. The lesson [The generic functions](tut-160-generic-calls.html) explains them.

## How it works

### Screens

`Screen.PrimaryScreen` is the main monitor and `Screen.AllScreens` all of them. `Bounds` is the size of a screen and `WorkingArea` the part that windows use (the screen without the taskbar). The values depend on the computer, so the program checks relations that are true everywhere: the working area fits in the screen.

### A picture of the screen

A `Bitmap` holds the picture, and a `Graphics` made from it (`FromImage`) draws on it. `CopyFromScreen` copies a part of the screen into the bitmap: the place on the screen, the place in the bitmap and the size of the part. `Save` writes a PNG file. The picture shows what is on the screen at that moment, including other programs, so a program that takes pictures of the screen tells its users.

### A picture of a control

`DrawToBitmap(bitmap, rectangle)` asks a **control** to draw itself on a bitmap. The result does not depend on what is in front of the window. This is the method to use in the tests of a window program: the test makes the picture of a panel and looks at pixels. The picture of a *form* also has its title bar and border, which the system draws, so the program takes the picture of a panel to know where each pixel is.

### Reading the picture

`GetPixel(x, y)` gives a `Color`, and its `Name` is the color as `AARRGGBB`: alpha, red, green and blue in hexadecimal. `ffdc2828` is a fully opaque red (220, 40, 40) and `ffffffff` is white. A pixel far from the label is the background; a pixel in the label, away from the text, is the label's own background. The count of step 5 looks at every fourth pixel in each direction, which is enough for an estimate and 16 times faster.

> [!NOTE] Each `GetPixel` call crosses the bridge, so it suits a few pixels. For a whole picture read all the bytes at once with `LockBits`.

### Release the pictures

A `Bitmap` and a `Graphics` hold system resources, so the program calls `Dispose()` on them when it is done (the tutorial [Releasing resources](tut-71-dispose.html)).

## What you learned

- `Screen`, `Bounds` and `WorkingArea`,
- `CopyFromScreen` and `DrawToBitmap`,
- checking a window by reading its pixels,
- `Dispose` for pictures.

## Exercises

1. Make a function `screenshot(cFile)` that saves the whole primary screen.
2. Take a picture of a panel that has a button and check the pixel in the middle of the button.
3. Write a test that changes the `BackColor` of a panel and checks that the pixels changed.
4. Take a picture of the panel before and after a click and count the pixels that differ.

## Next

[Printing](tut-153-printing.html)
