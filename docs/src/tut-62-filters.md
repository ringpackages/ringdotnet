---
title: "An image filter lab"
lead: A picture is a table of numbers. This lesson holds the pixels in Ring lists, writes each filter as a small function, saves the result as a BMP file written byte by byte, and shows the original and the result side by side.
---

## What you will learn

- a picture as rows of `[red, green, blue]` numbers,
- filters as functions that take a pixel (or its neighbours) and return a new one,
- why per-pixel calls across the bridge are slow, and a faster way,
- the structure of a **BMP** file and writing it with Ring,
- little-endian numbers,
- showing an image in a `PictureBox`.

## The program

{{file:samples/UsingDotNet/tutorials/g63_filters.ring}}

![The filter lab with sepia](img/shots/tut-g63.png "Sepia: the original on the left, the filtered picture on the right")

![The filter lab with edges](img/shots/tut-g63-edges.png "Edges: flat areas are black, the outlines are light")

{{output:samples/UsingDotNet/tutorials/g63_filters.ring --selftest}}

## How it works

### Pixels as numbers

`aSource[y][x]` is `[r, g, b]`, each from 0 to 255. The sample picture is made by `pictureColor`, a function that returns the colour of a point: a sky that gets lighter near the horizon, a circle for the sun (a point is inside if `(x − 94)² + (y − 22)² ≤ 14²`), grass, a house and a roof. Everything is plain Ring, so it is fast.

### Filters

Most filters change each pixel on its own, so `mapPixels` applies a function to every pixel (`call cFunction(aPixel)`):

| Filter | Rule |
|---|---|
| **Gray** | `0.299 r + 0.587 g + 0.114 b` — the eye sees green brighter than blue |
| **Invert** | `255 − value` for each channel |
| **Brighter / Darker** | add or subtract 40, and **clamp** the result into 0…255 |
| **Sepia** | each new channel is a weighted sum of the old three |
| **Blur** | each pixel becomes the **average of its 3 × 3 neighbourhood** |
| **Edges** | the difference between a pixel and its right and lower neighbour; where the picture is flat the difference is zero (black) |

Blur and edges look at neighbours, so they need two nested loops, and they must write into a **new** list: if you changed the picture in place, the next pixel would see already changed neighbours.

### The slow way and the fast way

The obvious way to show the result is `Bitmap.SetPixel(x, y, color)` for every pixel. Every call crosses the bridge (and creating the colour is another call), so the 10,800 pixels of this small picture would take several seconds *for each click*. See the tutorial [Speed — measure first](tut-53-speed.html): fewer calls win. Instead, the program builds the whole **file** in Ring and lets .NET load it with one call.

### A BMP file

A BMP is one of the simplest picture formats:

- a 14-byte file header (`"BM"`, the file size, where the pixels start),
- a 40-byte picture header (width, height, 24 bits per pixel, ...),
- the pixels: row by row **from the bottom row up**, each pixel as **blue, green, red**, each row padded to a multiple of 4 bytes (120 pixels × 3 = 360 is).

Numbers in the header are **little-endian**: the least significant byte comes first (`le32` and `le16`). The same idea is in the tutorial [Binary files](tut-45-binary.html). A Ring text is a list of bytes, so `char(n)` builds a byte and `write(file, text)` writes them.

`showPixels` writes `imageN.bmp` and loads it with `dnNew("Bitmap",[ :filename = cFile ])`. A new name for each image is used because a loaded image keeps its file open; the folder is deleted when the window closes. The self test reads one pixel back from the picture box (the sun, red 255 and blue 0) to prove that the file was written correctly.

> [!TIP] Try the same with `uiPictureBox` and a photo of your own: load it with `Bitmap`, read the pixels once into lists, and use the filters from this tutorial. Reading one pixel at a time is slow, so keep photos small, or look at `LockBits` for fast access.

## What you learned

- pixels as numbers and filters as functions,
- 3 × 3 neighbourhoods and writing to a new list,
- clamping,
- writing a BMP file and little-endian numbers,
- avoiding thousands of bridge calls.

## Exercises

1. Add a **Threshold** filter: black below 128 gray, white above.
2. Add a **Mirror** filter that reverses each row.
3. Make **Blur** stronger by repeating it three times.
4. Add a button that saves the result with `File.Copy` to a file chosen with `uiSaveFileName`.

## Next

[A chat over TCP](tut-63-chat.html)
