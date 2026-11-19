---
title: "A chart"
lead: Turn numbers into a picture. A bar chart needs only a little arithmetic — scaling values to pixels, a round-numbered axis — and the drawing calls you already know.
---

## What you will learn

- the arithmetic of a chart: scaling values to pixels,
- a "nice" axis maximum,
- drawing a grid, bars, numbers and labels,
- saving the picture,
- testing a drawing by reading its pixels.

## The plan

A chart is a picture of numbers, and every point of the picture is computed:

1. a **plot area**: left margin for the numbers, top margin for the title, bottom margin for the labels,
2. a **scale**: the biggest value (rounded up to a nice number) fills the height of the plot area,
3. for each value a **bar**: its height is `plotHeight × value / scaleMax`, its left edge is `left + slot × index`,
4. the **text**: title, numbers on the axis, value above each bar, label below.

## The program

{{file:samples/UsingDotNet/tutorials/g36_chart.ring}}

![The chart](img/shots/tut-g36.png "Sales per month")

{{output:samples/UsingDotNet/tutorials/g36_chart.ring --selftest}}

## How it works

### The scale

The biggest value is 25. If 25 touched the top of the chart the axis would read 0, 6.25, 12.5... Ugly. `niceMax` finds a **round** number at or above the maximum: 25 → 30, 8 → 8, 120 → 150. It takes the power of ten below the value (`10` for 25), tries the factors `1, 1.5, 2, 3, 4, 5, 6, 8, 10` and returns the first product that is big enough. The axis then runs 0, 7.5, 15, 22.5, 30. (Ring prints `7.5` as `7.50`; use rounding or a format if you want `7.5`.)

### Pixels from values

For a bar: `nHeight = (nBottom - nTop) * value / nScaleMax`. A value of `nScaleMax` fills the whole plot area; half of it fills half. The *y* of the top of a bar is `nBottom - nHeight` because **y grows downwards** on a screen: the bottom axis has the *bigger* y.

### One bar per value

The width available for one bar is `nSlot`, the plot width divided by the number of bars. The bar fills 60 percent of its slot and is centred in it, which leaves a gap between bars. The colour comes from a list.

### The text

`oCanvas.text(text, x, y, color, size)` draws the title, the axis numbers, the value above each bar and the label under it. Small offsets (`-18`, `+6`) place the text next to the bar without touching it.

### Saving

`oCanvas.oBitmap` is the .NET bitmap that the canvas draws on: `Save([ :filename = ..., :format = ... ])` writes a PNG (the tutorial [Images](tut-22-images.html)).

### Testing a drawing

You cannot look at a picture in a test, but you can **read pixels**. `oCanvas.pixel(x,y)` returns the colour: the background is `ffffffff` (white), and a point inside the April bar is `ffdc143c` (crimson). The test also checks the helper functions `maxOf` and `niceMax` with plain `dnAssert`s. Pixel positions must be whole numbers: `floor(...)`.

## What you learned

- chart = scale + bars + text,
- y grows downwards,
- a round axis maximum,
- tests can read pixels.

## Exercises

1. Draw a **line chart**: points joined by `oCanvas.line`.
2. Add a legend that lists the months with their colours.
3. Read the data from a CSV file (the tutorial [Tabular data](tut-30-tables.html)).
4. Draw a **pie chart** with `FillPie` (`Graphics`), using the percentage of each value.

## Next

[A folder browser](tut-42-browser.html)
