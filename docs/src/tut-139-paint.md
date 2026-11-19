---
title: "Drawing with the mouse"
lead: The mouse events say where the pointer is and whether a button is down. This lesson builds a small paint program: press the button and move to draw, choose a color and a pen size, clear the picture, and test it by calling the same functions that the events call.
---

## What you will learn

- the events **MouseDown**, **MouseMove** and **MouseUp**,
- the event argument: `X`, `Y` (pixels from the top left of the control),
- a **stroke** as three steps and a flag that says the button is down,
- drawing on a `Bitmap` that a `PictureBox` shows,
- a round pen, and why the first point of a stroke is a circle,
- testing a mouse program by reading pixels.

The tutorial [Drawing and animation](tut-14-animation.html) drew with a timer and the keyboard. Here the mouse draws.

## The program

{{file:samples/UsingDotNet/tutorials/g139_paint.ring}}

![The paint program](img/shots/tut-g139.png "The paint program with a few strokes")

{{output:samples/UsingDotNet/tutorials/g139_paint.ring --selftest}}

## How it works

### The three events

`setMouseDownEvent`, `setMouseMoveEvent` and `setMouseUpEvent` of the picture box run Ring code. The code has the event arguments in `aDotNetArgs[2]`: `aDotNetArgs[2].X` and `.Y` are the place of the pointer in pixels from the top left corner of the picture box. The code passes them to functions (`mouseDown(x, y)`), and the **functions** do the work. This is the whole design: the events only translate, so a test can call `mouseDown(50, 100)` without a mouse.

### A stroke

A stroke has a start, a middle and an end. `mouseDown` sets `lDrawing` to true and remembers the place; `mouseMove` draws a line from the remembered place to the new place and remembers the new place; `mouseUp` sets the flag to false and counts the stroke. `MouseMove` also runs when the button is up, and then the function returns at once: moving the pointer without the button draws nothing. Many short lines, one for each mouse event, make a smooth curve.

### Drawing on a bitmap

The program does not draw on the screen. It draws on a `Bitmap` (the tutorial [Images](tut-22-images.html)) with a `Graphics` object, and the `PictureBox` shows the bitmap. `Refresh()` draws the picture box again after each change. Because the picture is in a bitmap, it stays when another window covers the form, it can be saved (`Save`), and a test can read it (`GetPixel`).

### The pen

`Pen` has a color and a `Width`. `StartCap = "Round"` and `EndCap = "Round"` make the ends of each line round, so the small steps join without gaps. A line of length zero draws nothing, so the first point of a stroke is a filled circle with the size of the pen: a click without a move leaves a dot.

### The test

The test acts like a user: a stroke from `(50, 100)` to `(150, 100)` in steps of 10 pixels, then it reads the pixel in the middle (black) and the one above the line (white). A move with the button up leaves the canvas white. A click in red with a thick pen leaves a red dot. `Save` writes a PNG, and **Clear** makes the picture white again. The test needs no mouse and no screen position, and it checks the *result*: the pixels.

> [!NOTE] The picture box has the size of the bitmap. If a picture box is bigger than the bitmap and `SizeMode` stretches it, the pointer positions must be scaled to the bitmap first.

## What you learned

- the three mouse events and their arguments,
- a stroke with a flag,
- drawing on a bitmap and showing it in a picture box,
- a test that calls the functions of the events and reads pixels.

## Exercises

1. Add a button **Eraser** that draws in white with a thick pen.
2. Add the color **Green** and a button that opens a `ColorDialog`.
3. Draw a straight line from the first place to the current one while the button is down (a *rubber band*): keep a copy of the bitmap and draw on the copy.
4. Add **Undo**: keep a list of bitmap copies, one for each stroke.

## Next

[Images](tut-22-images.html)
