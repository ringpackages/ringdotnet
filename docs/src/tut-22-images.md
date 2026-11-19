---
title: "Images"
lead: Create a picture in memory, draw on it, read and change pixels, convert it to gray, resize it and save it as a PNG — all without opening a window.
---

## What you will learn

- bitmaps and pixels,
- `Graphics`, brushes and pens,
- `GetPixel` and `SetPixel`,
- saving and loading image files,
- when to use a different way to call a method (positional arguments and objects).

## Concepts

An **image** is a grid of **pixels**; each pixel has a **colour** made of red, green, blue (0–255) and an alpha value for transparency. A **Bitmap** is such a grid in memory. To draw on it you use a **Graphics** object created from the bitmap. A **Brush** fills areas, a **Pen** draws lines, a **Font** draws text.

> [!NOTE] `System.Drawing` is part of the desktop runtime, so the `using` block with `System.Drawing` starts the desktop runtime even though the program shows no window.

## The program

{{file:docs/tutorials/t22_images.ring}}

{{output:docs/tutorials/t22_images.ring}}

The three pictures that the program saves:

![The drawing](img/tutorials/tutorial22.png "STEP 2: a rectangle, a circle, a line and a text (240 × 160)")

![The gray copy](img/tutorials/tutorial22-gray.png "STEP 5: the gray copy")

![The small copy](img/tutorials/tutorial22-small.png "STEP 6: the resized copy (120 × 80)")

## How it works

### Drawing

`new Bitmap(240,160)` is an empty picture; `new Graphics().FromImage(oBitmap)` gives the drawing tool; `Clear(color)` fills the background. Then:

| Call | Draws |
|---|---|
| `FillRectangle(brush, new Rectangle(x,y,w,h))` | a filled rectangle |
| `FillEllipse(brush, new Rectangle(x,y,w,h))` | a filled ellipse (a circle if w = h) |
| `DrawLine(pen, new Point(x1,y1), new Point(x2,y2))` | a line |
| `DrawString(text, font, brush, new PointF(x,y))` | text |

Colours are `new Color().SteelBlue`, `new Color().Black`... (the names of the .NET `Color` properties). A pen's width is a property: `new Pen(color) { Width = 3 }`.

> [!TIP] These drawing methods take their arguments **in order**: a `Rectangle` or a `Point` object carries the numbers. In the tutorial [Drawing and animation](tut-14-animation.html) `UiCanvas` gives shorter calls for simple drawing on screen.

### Pixels

`GetPixel(x,y)` returns a `Color` with `R`, `G`, `B` and `Name` (the hexadecimal text `ffffffff`: alpha, red, green, blue). Coordinates start at `0`. Steel blue is R=70 G=130 B=180, exactly what step 3 prints.

### Saving and loading

`oBitmap.Save([ :filename = cPng, :format = new ImageFormat().Png ])` writes the file; the format decides the type (`Png`, `Jpeg`, `Bmp`, `Gif`). To open a file, `dnNew("Bitmap",[ :filename = cPng ])` chooses the constructor by the parameter name.

### A gray copy

A pixel is gray when its red, green and blue are equal. The average `(R + G + B) / 3` is a simple conversion. Two loops visit every pixel: for every `nY`, for every `nX`, read the colour, compute the gray value, write it with `SetPixel`. `new Color().FromArgb([ :red = r, :green = g, :blue = b ])` makes a colour from three numbers. Pixel loops are slow in any language that goes through a bridge: for big images use `LockBits` or leave the work to a library.

### Resizing

Draw the loaded image into a smaller rectangle of a new bitmap: `DrawImage(oLoaded, new Rectangle(0,0,120,80))`.

### Release

`Dispose()` frees the picture memory and unlocks the file. Always dispose bitmaps and graphics objects when you are done, and **before** you delete their file.

## What you learned

- bitmap, pixel, colour, `Graphics`,
- brushes and pens,
- `GetPixel` / `SetPixel` loops,
- save, load, resize,
- `Dispose()` when finished.

## Exercises

1. Draw a 100 × 100 chessboard with `FillRectangle`.
2. Turn the picture into a negative (255 − each channel).
3. Make a thumbnail that keeps the proportions of any picture: width 100, height `100 × h / w`.
4. Save the same bitmap as a JPEG and compare the file sizes.
5. Show the picture in a window with a `PictureBox` (`oPicture.Image = oBitmap`).

## Next

[A chart](tut-36-chart.html)
