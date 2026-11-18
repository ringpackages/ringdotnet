---
title: "Tutorial 70: WPF animation"
lead: In WPF you do not move a shape with a timer and a loop. You say "change this property from this value to that value in two seconds" and WPF does it on every frame. This lesson moves, fades and rotates shapes with animations.
---

## What you will learn

- the idea of an **animation**: a property, a start, an end and a duration,
- `DoubleAnimation`, `Duration`, `AutoReverse` and `RepeatBehavior`,
- **easing**, so that movements start and stop smoothly,
- animating a position (`Canvas.Left`), `Opacity` and a rotation `Angle`,
- stopping an animation,
- testing an animated window.

## Timer or animation?

In [tutorial 14](tut-14-animation.html) a timer changes the position 50 times a second and the program redraws. In WPF the *rendering system* knows about time: you describe the change once and WPF calculates every frame, uses the graphics card and keeps the window responsive. You animate **dependency properties**: `Opacity`, `Width`, `Canvas.Left`, `Angle`, colors...

## The program

{{file:docs/tutorials/g70_wpf_animation.ring}}

![The animation window](img/shots/tut-g70.png "A moment of the animation: the ball is half way, the blue box is fading, the green square is turning")

{{output:docs/tutorials/g70_wpf_animation.ring --selftest}}

## How it works

### The window

The window is described in XAML ([tutorial 15](tut-15-wpf.html)): a `Canvas` for free positions with an ellipse, a rectangle and a second rectangle that has a `RotateTransform` named `spin` as its `RenderTransform`; and a row with two buttons and a text.

### One animation

```ring
oMove = new DoubleAnimation()
oMove.SetProp("From",10)
oMove.SetProp("To",340)
oMove.Duration = new Duration().New_([ :timeSpan = new TimeSpan().FromSeconds(2) ])
oMove.AutoReverse = True
oMove.RepeatBehavior = new RepeatBehavior().Forever
oBall.BeginAnimation(new Canvas().LeftProperty,oMove)
```

A `DoubleAnimation` changes a number. `From` and `To` are *optional* values in WPF, so they are set by name with `SetProp`. `Duration` takes a `TimeSpan`. `AutoReverse` makes the ball come back, `RepeatBehavior.Forever` repeats. `BeginAnimation(property, animation)` attaches the animation to a property of an element; `LeftProperty`, `OpacityProperty` and `AngleProperty` are the properties as objects.

### Easing

A straight animation starts and stops abruptly. An **easing function** changes the speed: `SineEase` with `EasingMode = "EaseInOut"` starts slowly, is fastest in the middle and slows down at the end, which looks natural. Others: `BounceEase`, `ElasticEase`, `CubicEase`, `QuadraticEase`.

### Three properties

The ball animates `Canvas.Left`, the box animates `Opacity` (1 to 0.1) and the green square animates the `Angle` of its rotation from 0 to 360. The same pattern fits any numeric property.

### Stopping

`BeginAnimation(property, dnNull())` starts "no animation" on the property: the animation stops. (`dnNull()` is the .NET null.)

### Testing

You cannot take a picture in a test, but you can ask for **values**. In a self test a `DispatcherTimer` waits 900 milliseconds and then reads the *current* values (`GetValue(property)`, or the `Angle` attribute): the ball must be somewhere between 20 and 340, the box must be fading and the square must have turned. Then the test stops the animations and closes the window.

> [!NOTE] WPF can also animate in XAML with a `Storyboard`. Doing it in code, as here, lets you create the animations from data: one for each item of a list, for example.

## What you learned

- `DoubleAnimation` with `From`, `To`, `Duration`,
- `AutoReverse` and `RepeatBehavior`,
- easing,
- `BeginAnimation` and stopping with `dnNull()`,
- testing with a timer and the current values.

## Exercises

1. Make the ball bounce with `BounceEase` and `EasingMode = "EaseOut"`.
2. Animate the `Width` of the blue box.
3. Animate a color: `ColorAnimation` on `Fill.Color` of the ball.
4. Add a slider that changes the speed (the `Duration`) of the ball.

## Next

[Tutorial 71: Releasing resources](tut-71-dispose.html)
