---
title: "Sound"
lead: A program can play a sound it makes itself. This lesson builds a WAV file from numbers (a Ring text can hold any byte), plays it with SoundPlayer, and shows what to do when a framework class has no Ring class yet - wrap it from the DLL of the framework.
---

## What you will learn

- what to do with a framework class that has **no Ring class** in the package,
- how a **WAV** file is made: a header and the samples of the wave,
- building binary data in a Ring text, with `char()` and little-endian numbers,
- giving the bytes to a `SoundPlayer` through a `MemoryStream`,
- `Play`, `PlaySync` and `PlayLooping`.

## A class that has no Ring class

The package wraps the namespaces that most programs use (`System`, `System.IO`, `System.Windows.Forms` and others; the [class reference](api.html) lists every class). `SoundPlayer` is in `System.Media`, which is **not** one of them. A class that is not listed has no Ring class, but it is in a DLL of the framework, and the generator that the package uses for your own libraries ([A library written in C#](tut-18-csharp-library.html)) can wrap a namespace of any DLL:

```bash
ring wrapassembly.ring System.Windows.Extensions.dll classes System.Media
```

The last words name the namespaces to wrap (without them, every namespace of the DLL is wrapped). The program then does `dnLoad` and `dnImportFrom` as for any other library.

This DLL is in the folder of the **desktop runtime**, next to `System.Windows.Forms.dll`, and that folder is different on every computer. The program does not write a path: it asks a Windows Forms class where it lives, `new Label().GetType().Assembly.Location`, and takes the folder of that file.

> [!NOTE] This lesson runs on Windows only, because `SoundPlayer` uses the sound system of Windows (the program says so on another system).

## The program

{{file:samples/UsingDotNet/tutorials/ch13_sound.ring}}

{{output:samples/UsingDotNet/tutorials/ch13_sound.ring}}

The program is silent by default, so that it can run in a test. Run it with `--play` to hear a quarter of a second of the note A.

## How it works

### A sound is a list of numbers

A microphone measures the air pressure many times a second, and a speaker moves to follow the numbers. A sound that the program makes is a **wave** (here `sin`) that is measured at fixed moments:

- the **sample rate** is how many numbers there are in a second: 8000 is enough for a clear note,
- the **frequency** is how fast the wave goes up and down: 440 times a second is the note A,
- the **amplitude** is the size of the wave: 12000 of a possible 32767 is a clear, not too loud sound.

`sin(2 * pi * 440 * nSample / nRate)` is the value of the wave at sample number `nSample`, between -1 and 1, and multiplying it by 12000 makes a whole number.

### The WAV file

A WAV file is a **header** of 44 bytes that says what follows, and then the samples:

| Bytes | Content | Here |
|---|---|---|
| 4 | `RIFF`, the kind of file | |
| 4 | the size of the rest of the file | 36 + the size of the data |
| 4 | `WAVE` | |
| 4 | `fmt `, the format block | |
| 4 | the size of the format block | 16 |
| 2 | the format: 1 is plain samples (PCM) | 1 |
| 2 | channels: 1 is mono | 1 |
| 4 | samples in a second | 8000 |
| 4 | bytes in a second | 8000 × 2 |
| 2 | bytes of one sample, for all channels | 2 |
| 2 | bits of a sample | 16 |
| 4 | `data` | |
| 4 | the size of the samples in bytes | 2 × the number of samples |
| … | the samples | |

Every number in the header is stored **little endian**: the lowest byte first. `le16` and `le32` at the end of the program do that: `char(n % 256)` is the lowest byte, and `floor(n / 256)` is what is left for the next one. A 16-bit sample that is below zero is stored as 65536 minus its size (the *two's complement*), so the program adds 65536 to a negative value before it splits it into two bytes.

### A Ring text holds any byte

`char(0)` to `char(255)` make single bytes, and a Ring text can contain all of them, also the byte 0. So the whole file is one text, `cWav`, with 4044 bytes. A text that goes to a `byte[]` parameter becomes the same bytes (the tutorial [Binary files](tut-45-binary.html) and [Core concepts](concepts.html)).

### The stream and the player

`MemoryStream` has several constructors, so it is made with the name of the parameter that you want to pass: `dnNew("System.IO.MemoryStream",[ :buffer = cWav ])`. The class that the generator wrote for `SoundPlayer` is used the same way: `new SoundPlayer().@New([ :stream = oStream ])`. The tutorial [The generic functions](tut-160-generic-calls.html) explains the named form.

`Load` is a keyword of Ring, so the method of .NET is `@Load()` (a name that is a keyword gets an `@` at the start). It reads the stream and **checks that it is a good WAV file**: a mistake in the header makes it raise an exception, so the line `the sound is loaded` is a test of the header as well.

### Playing

| Method | What it does |
|---|---|
| `PlaySync()` | plays the sound and waits until it ends |
| `Play()` | plays on another thread and returns at once |
| `PlayLooping()` | plays again and again until `Stop()` |
| `Stop()` | stops the sound |

Sounds that the system itself plays (`SystemSounds.Beep`) are in the same namespace, and the wrapped class can play them: `SystemSounds` is a static class, so a call goes through an object of the class.

## What you learned

- a class without a Ring class is wrapped from its DLL with `wrapassembly.ring`, and the DLL of a framework is found through a class that lives next to it,
- a WAV file is a header and samples, with numbers stored little endian,
- a Ring text is a list of bytes, built with `char()`,
- `MemoryStream` with a named constructor, `SoundPlayer` with `@Load`, `PlaySync` and `Play`.

## Exercises

1. Run the program with `--play`, then change the frequency to 880 (one octave higher) and 220 (one octave lower).
2. Make the note one second long and fade it: multiply every sample by `(nSamples - nSample) / nSamples`.
3. Play two notes one after the other by adding the samples of the second one to `cData` before the header is made.
4. Write the sound to a file with `new File().WriteAllBytes(cFile, cWav)` (the tutorial [Files and folders](tut-05-files.html)) and play the file by name: `new SoundPlayer().@New([ :soundLocation = cFile ])`.

## Next

[A QR code](tut-165-qr.html)
