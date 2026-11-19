---
title: "Drawing and animation"
lead: Draw shapes and text on a canvas, move them with a timer and control them with the keyboard — the three ingredients of every simple game.
---

## What you will learn

- drawing with `UiCanvas`,
- animation with a timer and a "game loop",
- keyboard events and why a form needs `KeyPreview`,
- keeping the program state in global variables.

## The ingredients of a game

1. **State**: numbers that describe the world (position, speed, score).
2. **Update**: a function that changes the state a little (move the ball).
3. **Draw**: a function that shows the state.
4. A **timer** that calls update and draw, again and again.
5. **Input**: keys change the state.

## The program

{{file:samples/UsingDotNet/tutorials/g04_bounce.ring}}

![The bouncing ball and the paddle](img/shots/tut-g04.png "The ball bounces; Left and Right move the paddle")

{{output:samples/UsingDotNet/tutorials/g04_bounce.ring --selftest}}

## How it works

### The canvas

`uiPictureBox(oForm, x, y, w, h)` creates a picture box, and `new UiCanvas(oPicture)` gives it a bitmap and simple drawing calls:

| Call | Draws |
|---|---|
| `clear(color)` | fills everything |
| `fillCircle(x,y,radius,color)` | a filled circle |
| `fillRect(x,y,w,h,color)` | a filled rectangle |
| `text(text,x,y,color,size)` | text |
| `show()` | puts the finished picture on the screen |

A color is a name (`"Orange"`), a `#RRGGBB` text, or a .NET `Color`. Every frame the program clears the canvas and draws everything again; `show()` makes the result visible.

### The timer

`uiTimer(20,"step()")` creates a timer that calls `step()` every 20 milliseconds (50 times a second). `Start()` starts it, `Stop()` stops it. A Windows Forms timer ticks on the Ring thread, so it is safe to run Ring code in it.

### The game logic

`step()` moves the ball by `nDX` and `nDY`, bounces it off the walls by reversing a speed (`nDX = -nDX`), and checks whether it hit the paddle: the ball is low enough and between the paddle's left and right edges.

### The keyboard

```ring
oForm.KeyPreview = True
oForm.setKeyDownEvent("keyPressed(aDotNetArgs[2].KeyCode)")
```

By default the *control that has the focus* gets the keys. `KeyPreview = True` lets the form see them first. The event arguments are `[sender, eventArgs]`; `aDotNetArgs[2].KeyCode` is the key as a text: `"Left"`, `"Right"`, `"A"`, `"Space"`. (If the form contains buttons that steal the arrow keys, use `uiGameKeys`: see [Windows Forms](winforms.html#keyboard-in-games).)

### Testing a game

A test cannot wait for animation. `selfTest` stops the timer, calls `step()` three times and checks the numbers. It also presses `Left` by calling `keyPressed("Left")` and checks the paddle position, and reads a pixel from the canvas (`oCanvas.pixel(x,y)`) to prove that the ball is drawn.

## What you learned

- state, update, draw, timer, input,
- `UiCanvas` for drawing, `show()` to display,
- `KeyPreview` and `KeyCode`,
- stop the timer in tests and call the update by hand.

## Exercises

1. Make the ball faster each time it hits the paddle.
2. Add three lives: when the ball falls, take one life and show it; at zero show *Game over*.
3. Add the `Space` key to pause (`oTimer.Stop()` / `Start()`).
4. Draw a row of bricks at the top and remove the one the ball hits. The [Pong](gallery-apps.html#pong) and [Snake](gallery-apps.html#snake) applications show complete games.

## Next

[Drawing with the mouse](tut-139-paint.html)
