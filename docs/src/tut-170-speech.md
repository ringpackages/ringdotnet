---
title: "Text to speech"
lead: Windows has voices that read a text aloud. The System.Speech package from nuget.org gives them to a program. This lesson lists the voices, writes speech to a WAV file without any sound, compares speeds, and speaks aloud on request. It also shows what to do with a package that has a different DLL for each system.
---

## What you will learn

- how to use the voices of Windows from Ring,
- writing speech to a **file**, which can be tested without sound,
- the rate of a voice,
- a package with a **different DLL for each system**, and the project setting that picks the right one.

> [!NOTE] This lesson runs on Windows only. The voices are part of Windows, and the program says so on another system. (Linux and macOS have their own speech programs, which a Ring program can start as a command, as in the lesson [Working with other programs](tut-85-feed-programs.html).)

## A package with a DLL for each system

The package `System.Speech` has the same name and the same classes on every system, but only on Windows does it do anything. A package like that contains an **empty** DLL for general use and the **real** one in a folder for Windows. A plain `dotnet publish` copies the empty one, and the first call stops with *Speech is not supported on this platform*. The project file therefore says which system the output is for:

{{file:samples/UsingDotNet/tutorials/Speech/Speech.csproj}}

`RuntimeIdentifier` `win-x64` makes `dotnet publish` take the files for Windows, 64-bit, and `SelfContained` `false` keeps the output small, because the program uses the .NET that is already installed. Use the same setting for any package that is meant for one system.

## The steps

The steps are the ones of the lessons on packages ([A NuGet package](tut-162-nuget.html) and the lessons after it): a project file, `dotnet publish`, `wrapassembly.ring` (only the namespace `System.Speech.Synthesis`), then `dnLoad` and `dnImportFrom`.

## The program

{{file:samples/UsingDotNet/tutorials/ch13_speech.ring}}

{{output:samples/UsingDotNet/tutorials/ch13_speech.ring}}

Run it with `--speak` to hear the voice.

## How it works

### The voices

`new SpeechSynthesizer()` is the speaking voice. `GetInstalledVoices(NULL)` is a list of the voices of the computer, and `toList()` copies it into a Ring list. Each item describes one voice (its name, language and gender in `VoiceInfo`). The names are different on every computer, so the program only counts them. `SelectVoice(name)` picks one by name.

### Speech to a file

`SetOutputToWaveFile(cFile)` sends the speech to a WAV file and not to the speakers, and `Speak(cText)` makes it. That is quiet, so it can be used in a test: the program checks the **size** of the file. To end the file the output is set to nothing, with `SetOutputToNull()`, so that the file is closed before it is read.

`Rate` is a number from -10 (slow) to 10 (fast). A slow voice needs more time for the same text, so its WAV file is bigger: that is what the second line of the output tests. The WAV format is explained in the lesson [Sound](tut-164-sound.html), and the file can be played with a `SoundPlayer`.

### Speaking aloud

`SetOutputToDefaultAudioDevice()` sends the speech to the speakers again, and `Speak` **waits** until the text is spoken. `SpeakAsync` starts the speech and returns at once, but then the program must stay alive until the voice has finished; the lessons on timers and on tasks show ways to wait. The events of the synthesizer (the end of a sentence, for example) are raised while the speech runs; callbacks into Ring work only during a call from Ring (the lesson [Callbacks and events](tut-19-callbacks.html)), so this lesson does not use them.

### Before you use it

- A voice that is installed on your computer may not be installed on the computer of another person. The default voice always exists.
- The quality is the quality of the voices of Windows: clear, not natural. Online voice services are better, but they need a key, the internet and often money.
- Look at the licence of a package before you give a program to others.

## What you learned

- speech is a part of Windows, brought to Ring by a package,
- a package with a DLL for each system needs a project with `RuntimeIdentifier` for the system,
- speech can be written to a WAV file, which makes it testable without sound,
- `Rate`, `Speak` and `SpeakAsync`.

## Exercises

1. Run the program with `--speak`, and change the text.
2. Select a second voice with `SelectVoice` (print the names first: `aVoices[1].VoiceInfo.Name`) and compare how the two sound.
3. Write a function that reads the lines of a text file one by one with `Speak`.
4. Write the speech to a WAV file and play it with the program of the lesson [Sound](tut-164-sound.html).

## Next

[A project: from CSV to Excel](tut-171-csv-to-excel.html)
