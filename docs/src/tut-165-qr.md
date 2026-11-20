---
title: "A QR code"
lead: A QR code is a picture that holds a text, such as a web address or the name and password of a Wi-Fi network. This lesson uses the QRCoder package from nuget.org to make one, prints it as text in the console and writes it as a PNG picture. It is the second lesson on NuGet packages: the first one explained the steps, this one uses them.
---

## What you will learn

- how a **QR code** is made of modules and what the levels of error correction mean,
- the steps of the previous lesson on a second package: project file, `dotnet publish`, wrap, load,
- a method chosen by the names of its parameters, constructors with `New_`, and enums as texts,
- reading a value from a result that has no Ring class (`getProp`),
- writing the bytes of a PNG picture to a file.

## What a QR code is

A QR code is a square grid of dark and light **modules**. The three big squares in the corners tell a camera where the code is and how it is turned. Between them the text is stored as bits, together with **extra data** that lets a camera read the code even when a part of it is dirty or covered. The amount of extra data is the **level of error correction**:

| Level | Part of the code that can be lost |
|---|---|
| `L` (low) | about 7% |
| `M` (medium) | about 15% |
| `Q` (quartile) | about 25% |
| `H` (high) | about 30% |

A higher level needs more modules for the same text, so the code gets bigger. The empty border around the code (the *quiet zone*) is part of the picture, because a camera needs it.

## The steps

They are the steps of the lesson [A NuGet package](tut-162-nuget.html):

1. a project file names the package, `QRCoder` here,
2. `dotnet publish Qr -c Release -o Qr/libs` copies it,
3. `wrapassembly.ring` writes the Ring classes,
4. `dnLoad` and `dnImportFrom`, then the classes are used.

The project file is in `samples/UsingDotNet/tutorials/Qr`, and it is the same as before with another name and version:

{{file:samples/UsingDotNet/tutorials/Qr/Qr.csproj}}

## The program

{{file:samples/UsingDotNet/tutorials/ch13_qr.ring}}

{{output:samples/UsingDotNet/tutorials/ch13_qr.ring}}

## How it works

### Making the code

`QRCodeGenerator` makes the **data** of a code: the grid of modules. Its method `CreateQrCode` has several versions, so it takes a list of the names of the parameters: `[ :plainText = "RING", :eccLevel = "L" ]`. The level is an enum of the package, and an enum in Ring is its **name as a text**, `"L"`.

The data is not a picture yet. Other classes of the package turn it into a picture of one kind or another:

- `AsciiQRCode` draws it with text characters. `GetGraphic(1)` returns a text of lines, and the program prints it. A console shows the dark modules as blocks.
- `PngByteQRCode` draws it as the bytes of a PNG file. `GetGraphic(8)` uses 8 pixels for each module.

Both classes take the data in their constructor. They have more than one constructor, so the program writes `new AsciiQRCode().New_([ :data = oCode ])`, the form of the lesson [The generic functions](tut-160-generic-calls.html).

### A result that has no class

`oSized.ModuleMatrix` is a list of rows, a `List<BitArray>`. The package has no Ring class for that type, so a property of it, such as `Count`, is read with the generic `getProp("Count")`. The grid is as high as it is wide, so the count is the number of modules on a side: 33 for the longer text at level L, and 41 at level H.

### The picture

A `byte[]` that .NET returns is a Ring text of bytes (a copy), so the PNG is a Ring text. Its second to fourth bytes are the letters `PNG`, which is how the program tests that it is a picture, and `File.WriteAllBytes(path, bytes)` writes it to a file. The program writes the file to the folder of temporary files and removes it at the end; in your program you would keep it, or show it in a `PictureBox` (the tutorial [Images](tut-22-images.html)).

### Using a package safely

- The program was tested to make a code and a PNG. A real use of a code should be **tried with a camera** of the kind that your users have, with the size and the colours that you chose.
- The text of a code is not secret: anybody who scans it reads it. A code with a password for a Wi-Fi network shows the password to everybody who sees the code.
- Look at the licence of a package before you give your program to others (the page of the package at nuget.org shows it).

## What you learned

- a QR code is a grid of modules, and the level of error correction trades size for safety,
- the same steps bring any package: project file, publish, wrap, load,
- parameters by name, enums as texts, `New_` for a class with several constructors,
- `getProp` for a value of a type with no class, and bytes written to a file.

## Exercises

1. Make a code for a Wi-Fi network: the text is `WIFI:T:WPA;S:name;P:password;;`. Change the level to `H` and compare the sizes.
2. Print the codes of three different texts one after the other.
3. Write the PNG with `GetGraphic(20)` and open the file with the picture viewer of your system.
4. Show the picture in a window: write the file, then load it into a `PictureBox` as in the tutorial [Images](tut-22-images.html).

## Next

[More than one system](tut-166-systems.html)
