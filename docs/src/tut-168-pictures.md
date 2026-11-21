---
title: "Pictures on every system"
lead: The picture classes of earlier lessons (Bitmap, Graphics) are a Windows feature. SkiaSharp, a package from nuget.org, draws, saves and reads pictures on Windows, Linux and macOS. This lesson draws a small picture, looks at its pixels, saves it as PNG, and reads the file back - and shows how a package with a native library is brought to Ring.
---

## What you will learn

- why `System.Drawing` is not the answer on every system, and what SkiaSharp offers instead,
- how a package with a **native library** is published and found,
- a bitmap, a canvas, a paint and colours,
- reading pixels, and saving and reading a PNG file,

## Why another picture library

The lessons [Images](tut-22-images.html) and [An image filter lab](tut-62-filters.html) use `Bitmap` and `Graphics` of Windows. In current versions of .NET these classes work on **Windows only**, so a program that makes pictures on a Linux server needs another library. **SkiaSharp** is one: the drawing engine of Chrome and Android, with a .NET interface. It makes the same picture on every system.

A drawing engine is written in C++, so SkiaSharp is two things: a managed DLL (`SkiaSharp.dll`) and a **native library** for each system (`libSkiaSharp.dll` for Windows, `libSkiaSharp.so` for Linux). The package of the managed part includes the native libraries for Windows and macOS. The one for Linux is a separate package, so the project file names both:

{{file:samples/UsingDotNet/tutorials/Skia/Skia.csproj}}

`dotnet publish` puts every native library in a folder of its own system, `Skia/libs/runtimes/win-x64/native`, `.../linux-x64/native` and so on. The bridge looks in the folder of the running system when .NET asks for a native library that is not found next to the DLL, so the program does not copy anything.

## The steps

They are the steps of the lessons [A NuGet package](tut-162-nuget.html), [A QR code](tut-165-qr.html) and [Excel files](tut-167-excel.html): a project file, `dotnet publish`, `wrapassembly.ring` for the namespace `SkiaSharp`, then `dnLoad` and `dnImportFrom`.

## The program

{{file:samples/UsingDotNet/tutorials/ch13_pictures.ring}}

{{output:samples/UsingDotNet/tutorials/ch13_pictures.ring}}

## How it works

### Bitmap, canvas, paint

- An `SKBitmap` is the picture: a grid of pixels. `@New([ :width = 200, :height = 100 ])` makes an empty one (a constructor chosen by the names of its parameters).
- An `SKCanvas` is what draws on a bitmap: `new SKCanvas(oBitmap)`. Its methods are `Clear`, `DrawCircle`, `DrawRect`, `DrawText` and more, and each of the ones with several versions takes a list of the names of its parameters.
- An `SKPaint` says **how** to draw: its `Color`, `IsAntialias` (smooth edges), `TextSize`. The same paint can draw many things, and it can be changed between them: the program draws the circle in yellow and the text in white with one paint.

### Colours

A colour is a value of the type `SKColor`, with `Red`, `Green`, `Blue` and `Alpha` (the opacity) from 0 to 255. `new SKColor().Parse("#2060c0")` reads the usual web notation. Colours are values, so the program makes them once (`oBlue`, `oYellow`, `oWhite`) and uses them where it needs them.

### Pixels

`oBitmap.GetPixel(150,50)` is the colour of the pixel at column 150 and row 50 (the top left corner is 0,0). The program checks two pixels: the corner is the blue of `Clear`, and the centre of the circle is the yellow of the paint.

### Saving and reading

`SKImage` is a finished picture. `new SKImage().FromBitmap(oBitmap)` makes one, and `Encode(NULL)` gives the data of a **PNG** file (the default format). `ToArray()` returns the bytes, and a `byte[]` that .NET returns is a Ring text, so `File.WriteAllBytes(cFile, cPng)` writes the file. The second to fourth bytes are the letters `PNG`, which the program uses as a test. `new SKBitmap().Decode(cFile)` reads a file again, and the pixels are the same.

For another format, give the format and the quality: `Encode([ :format = "Jpeg", :quality = 80 ])`.

### Many pixels are many calls

Every `GetPixel` or `SetPixel` crosses the bridge, like the `SetPixel` of the image lesson, and a picture has thousands of them. Use the drawing methods for shapes and text. For a filter over a whole picture, read the pixels once with a method that returns many at once (the lessons [An image filter lab](tut-62-filters.html) and [Core concepts](concepts.html) explain why).

### Which system

SkiaSharp works on Windows, Linux and macOS. The program here was run on Windows and on Linux (x64) and printed the same lines. macOS and arm64 were **not tested**, although the package has native libraries for them (the Linux one needs the extra package of the project file).

## What you learned

- `System.Drawing` is Windows-only, and SkiaSharp draws on every system,
- a package with a native library is published with its `runtimes` folder, and the bridge finds the library of the running system,
- bitmap, canvas, paint and colours; pixels; PNG and JPEG.

## Exercises

1. Draw a rectangle: `oCanvas.DrawRect([ :x = 10, :y = 10, :w = 60, :h = 30, :paint = oPaint ])`, in another colour.
2. Move the circle, change its size, and print the colour of a pixel on its edge.
3. Save the picture as JPEG with `Encode([ :format = "Jpeg", :quality = 80 ])` and compare the sizes of the two files.
4. Write a function `drawFlag(cColor1, cColor2, cColor3)` that draws three stripes and returns the PNG bytes.

## Next

[PDF files](tut-169-pdf.html)
