---
title: "The clipboard"
lead: Copy and paste is how programs share data on a computer. This lesson puts text, a table for a spreadsheet and a picture on the clipboard, reads text back, clears it, and leaves the clipboard as the user had it.
---

## What you will learn

- `Clipboard.SetText`, `GetText` and `ContainsText`,
- a **table** that a spreadsheet pastes as cells (tabs and new lines),
- `SetImage`, `ContainsImage` and `GetImage`,
- `Clear`,
- why a program that tests the clipboard puts back what it found.

The clipboard belongs to the whole computer: every program can read and replace it. The tutorial [A text editor](tut-13-editor.html) used the edit commands of a text box; this lesson uses the clipboard itself, which also copies to and from other programs.

## The program

{{file:samples/UsingDotNet/tutorials/ch10_clipboard.ring}}

![The clipboard form](img/shots/tut-g127.png "The clipboard form")

{{output:samples/UsingDotNet/tutorials/ch10_clipboard.ring --selftest}}

## How it works

### Text

`SetText(text)` puts a text on the clipboard. `GetText(NULL)` reads the text (the method has more than one form, so it takes `NULL` when there is nothing to choose). Before reading, `ContainsText(NULL)` says whether there is text at all: the clipboard can hold a picture, a list of files or nothing. The program shows *The clipboard has no text* when pasting is not possible instead of showing an empty box.

The clipboard belongs to the whole computer, and another program (a clipboard manager, for example) can have it open for a moment, so a read can answer *nothing* although there is text. `readText` therefore asks again, up to twenty times with a pause of 50 milliseconds, and returns an empty text only when there is really none. The same is done for the picture (`waitForImage`). A test that reads the clipboard needs this; a program that reads it for a user can show an error after the tries.

### A table

A spreadsheet (Excel, LibreOffice, Google Sheets) pastes text as a **table** when the columns are separated by a tab (`char(9)`) and the rows by a new line. `copyTable` builds this text from a Ring list of rows, and nothing else is needed: paste it into a spreadsheet and the cells appear. The same text pasted into a plain text box shows the tabs as spaces.

### A picture

`SetImage(bitmap)` puts a picture on the clipboard and other programs paste it as an image (a drawing program, a word processor, a message window). `ContainsImage()` asks and `GetImage()` returns a `Bitmap`. The picture is drawn with `Graphics` (the tutorial [Images](tut-22-images.html)).

### Clear

`Clear()` removes everything. After it `ContainsText(NULL)` is false.

### Be polite

The test of this program uses the real clipboard, so it first saves the text that the user had (`cBefore`) and at the end puts it back. A program should not destroy what the user copied, unless the user asked it to copy something. A program that copies something because the user clicked **Copy** shows it (the status line says what was copied), so the user knows that the clipboard has changed.

> [!NOTE] A program should not put passwords on the clipboard without a good reason. When it does (a password manager), it clears the clipboard after a short time.

## What you learned

- reading and writing text on the clipboard,
- a table for spreadsheets,
- pictures on the clipboard,
- `Clear`, and leaving the clipboard as it was.

## Exercises

1. Add a button **Copy as CSV** that puts the table on the clipboard with commas, and quotes the cells that have a comma.
2. Add a button that pastes a table from a spreadsheet into a `ListBox` (split the rows at the new lines and the cells at the tabs).
3. Show the length of the clipboard text in the status line each second (a timer; the tutorial [Timers and progress](tut-34-timers.html)).
4. Clear the clipboard 20 seconds after copying a text.

## Next

[Your own dialog](tut-40-dialog.html)
