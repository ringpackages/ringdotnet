---
title: "PDF files"
lead: A report, an invoice or a certificate is usually a PDF. The PDFsharp package from nuget.org makes PDF files from a program. This lesson writes a two-page report with a title, a line and a few rows of text, and reads the file back to check it. It is the third lesson in a row that uses a package, so the steps are short.
---

## What you will learn

- how a PDF page is measured and drawn,
- a document, a page, and an `XGraphics` that draws on it,
- fonts, brushes and pens,
- saving a file and opening it again to check it,
- what to look at before using a PDF package in a real program.

## How a PDF page works

A PDF page is a sheet with a size in **points** (one point is 1/72 of an inch): an A4 page is about 595 points wide and 842 high. The point 0,0 is the **top left** corner, and `y` grows **downwards**. Text and lines are drawn at positions in points, and each piece of text has a font and a size.

PDFsharp has the same shape as the drawing classes of the earlier lessons:

| Idea | In PDFsharp |
|---|---|
| the file | `PdfDocument` |
| a sheet | `PdfPage`, from `oDocument.AddPage(NULL)` |
| a surface to draw on | `XGraphics`, from `new XGraphics().FromPdfPage(oPage)` |
| a font | `XFont` (a name and a size) |
| what text is filled with | a **brush**, `XBrushes.Black` |
| what a line is drawn with | a **pen**, `XPens.Black` |

## The steps

They are the steps of the lessons [A NuGet package](tut-162-nuget.html), [Excel files](tut-167-excel.html) and [Pictures on every system](tut-168-pictures.html): a project file, `dotnet publish`, `wrapassembly.ring`, `dnLoad` and `dnImportFrom`. The project file names the package:

{{file:samples/UsingDotNet/tutorials/Pdf/Pdf.csproj}}

The program wraps only the namespaces that it uses: `PdfSharp.Pdf` (the document and the pages), `PdfSharp.Pdf.IO` (reading files) and `PdfSharp.Drawing` (fonts, brushes and `XGraphics`).

## The program

{{file:samples/UsingDotNet/tutorials/ch13_pdf.ring}}

{{output:samples/UsingDotNet/tutorials/ch13_pdf.ring}}

## How it works

### Drawing

`oGraphics.DrawString([ :s = ..., :font = ..., :brush = ..., :x = 50, :y = 60 ])` writes a text with its baseline at `y`. `DrawString` has several versions, so it takes a list of the names of its parameters, and so does `DrawLine`. The program writes the rows of a Ring list with a loop that moves `nY` down by 22 points each time. A page of a real report would also check that `nY` does not pass the bottom of the page (about 800) and add another page when it does.

### Fonts

A font is made with the name of a family and a size: `dnNew("PdfSharp.Drawing.XFont",[ :familyName = "Arial", :emSize = 22 ])`. The font must exist **on the computer that makes the file**: Windows has Arial, and other systems have other fonts. Check how the file looks on the system where the program will run, and not only on the one where you wrote it. The program was run on Windows and on Linux, and both wrote a PDF that the program could read back. I did not look at the pages on Linux, so a program that depends on the look of a page has to be tried there.

### The title of the file

`oDocument.Info.Title = "Sales report"` puts a title in the information of the file, the text that a viewer shows in its title bar. `Info` is an object of the document, and `Title` is a property of it.

### Closing and reading

`Save(cFile)` writes the file and `Close()` ends the document. To check the result the program opens the file again with `PdfReader.Open` in the mode `"Import"` and asks for `PageCount` and the title. PDFsharp is for **making** PDF files and for changing and joining them, not for reading the **text** of a page: to search the text of a PDF you need another package.

### Before you use it in a real program

- **Look at the licence** of a PDF package. Some are free for any use, others are free only for a small business or for open source. It is on the page of the package at nuget.org.
- **Text that is long** has to be cut into lines by the program, or by a helper class of the package (PDFsharp has a text formatter for it).
- **Many small drawing calls** are many calls over the bridge. A report of a few pages is no problem.

## What you learned

- a PDF page is measured in points, from the top left corner,
- a document has pages, and an `XGraphics` draws on a page,
- fonts, brushes and pens are objects; `dnNew` with parameter names makes a font,
- a file can be opened again to check its pages and title,
- check the fonts and the licence before a real use.

## Exercises

1. Change the title text and the font size, and add a third page.
2. Draw a rectangle around the title: `XGraphics` has `DrawRectangle`; look at the names of its parameters in `Pdf/classes/PdfSharp.Drawing.classes.ring`.
3. Write the rows of a list of 40 products and add a new page when `nY` is above 780.
4. Make a function `makeInvoice(cCustomer, aItems, cFile)` that writes a one-page invoice and returns the total.

## Next

[Testing your programs](tut-28-testing.html)
