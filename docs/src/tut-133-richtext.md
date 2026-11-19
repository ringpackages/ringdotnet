---
title: "Formatted text"
lead: A rich text box shows text in bold, in colors and in different fonts, and saves it as an RTF file that word processors can open. This lesson formats the selected words, finds and marks every match of a word, and saves and loads the formatted text.
---

## What you will learn

- the **selection**: `SelectionStart`, `SelectionLength`, `SelectedText` and `Select`,
- formatting the selection: `SelectionFont` and `SelectionColor`,
- `Find` and marking every match with `SelectionBackColor`,
- the difference between `Text` and `Rtf`,
- `SaveFile` and `LoadFile` with the format `RichText`.

The tutorial [A small text editor](tut-13-editor.html) used a plain text box, where all the text has the same font. A `RichTextBox` keeps a format for each part of the text.

## The program

{{file:samples/UsingDotNet/tutorials/ch10_richtext.ring}}

![The rich text window](img/shots/tut-g133.png "Bold and red words, and the marked matches")

{{output:samples/UsingDotNet/tutorials/ch10_richtext.ring --selftest}}

## How it works

### The selection

Formatting always applies to the **selection**. `Select([ :start = 5, :length = 4 ])` selects four characters from the position 5 (positions count from 0), `SelectedText` is the text of the selection and `SelectionLength` its size. When nothing is selected the format applies to the text that is typed next. The function `selectWord` finds a word and selects it.

### Font and color

`SelectionFont` is a `Font`; it has the family, the size and the style (`Bold`, `Italic`...). A font object does not change: to make the selection bold the program makes a **new** font (`uiFont("Segoe UI", 11, True)`) and assigns it. `SelectionColor` and `SelectionBackColor` are colors. The same selection can be read back: `SelectionFont.Bold` says whether the selected text is bold, which is how the **Bold** button works as a toggle. When the selection has mixed formats `SelectionFont` is empty and `SelectionColor` is empty too; the program only reads them after selecting one word.

### Find

`Find` searches the text and returns the place of the match, or `-1`. With a start place (`:start`) and options it can search on from the last match: the loop of `findAll` selects each match, gives it a yellow background and starts the next search after it. The search ignores upper and lower case unless the option `MatchCase` is used.

### Text and Rtf

`Text` is the plain text without any format. `Rtf` is the same text with the format codes in the **Rich Text Format**: `\b` is bold, and the color table lists the colors. The test checks both: the formatting does not change the plain text, and the RTF has the codes. RTF is a text format, so the property can be saved in a file or sent in a message.

### Saving and loading

`SaveFile([ :path = ..., :fileType = "RichText" ])` writes an RTF file; `LoadFile` reads it into another `RichTextBox`, and the bold word is still bold. Word processors open the file. Use the file type `PlainText` to write only the text.

> [!NOTE] `RichTextBox` is a Windows Forms control. WPF has its own `RichTextBox` with a different model (documents made of paragraphs and runs).

## What you learned

- the selection and its formatting,
- fonts as objects that are replaced, not changed,
- finding and marking text,
- `Text` and `Rtf`, and saving as RTF.

## Exercises

1. Add buttons **Italic** and **Underline** with the font styles `Italic` and `Underline`.
2. Add a `ColorDialog` (`new ColorDialog()`) so that the user chooses the color.
3. Change `findAll` to match the case, with a check box *Match case*.
4. Add a button that removes all the marks (`SelectionBackColor` to white for the whole text, after `SelectAll()`).

## Next

[The clipboard](tut-127-clipboard.html)
