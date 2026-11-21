---
title: "Printing"
lead: A program prints by answering an event: the PrintPage event runs once for each page, and the program draws the page. This lesson prints a report of 100 rows on several pages with a header, a page number and a footer, changes the page to landscape, and looks at the pages as pictures without a printer.
---

## What you will learn

- `PrintDocument` and the **PrintPage** event,
- drawing a page on `e.Graphics` inside the margins (`e.MarginBounds`),
- **paging**: how many rows fit, and `e.HasMorePages`,
- paper size, margins and **landscape** (`DefaultPageSettings`),
- the **preview controller**: pages as pictures, no printer needed,
- why a page of the preview is a **metafile**, and how to look at its pixels.

Printing is drawing: the tutorial [Images](tut-22-images.html) used `Graphics` to draw on a bitmap, and here the same calls draw on a page. These classes are part of Windows Forms and need Windows.

## The program

{{file:samples/UsingDotNet/tutorials/ch10_printing.ring}}

{{output:samples/UsingDotNet/tutorials/ch10_printing.ring}}

## How it works

### A document and its event

A `PrintDocument` does not draw by itself. `Print()` starts the job, and for each page the document raises **PrintPage**; the program draws on `e.Graphics` and, if the page is full, sets `e.HasMorePages = True`. The document then asks for the next page, and so on until the program answers `False`. The state of the job (the number of the page, the next row to print) is kept in global variables, because each call of the event is separate.

### The page

The unit of the page is a hundredth of an inch. `e.MarginBounds` is the rectangle inside the margins (`Left`, `Top`, `Right`, `Bottom`), so the program never draws into the margin. The height of a line comes from the font: `Font.@GetHeight(graphics)` gives it in the unit of the graphics. The header has the title and the page number, the rows follow, and the loop stops when the next line would not fit above the bottom margin (one line is kept for the footer). In the output the first page has 57 rows and the second 43: 100 rows in all.

### Paper and margins

`DefaultPageSettings` has the `PaperSize`, the `Margins` and `Landscape`. The program sets the paper explicitly (A4 is 827 by 1169 hundredths of an inch), so the pages are the same on every computer; without it the size comes from the default printer, which can be A4 or Letter. In **landscape** the page is wide and low, so fewer rows fit and the same report needs three pages instead of two.

> [!NOTE] The row counts depend on the font (`Arial` here): a computer without that font would use another one and could fit a different number of rows.

### Preview without a printer

`PrintController = new PreviewPrintController()` makes the pages as pictures in memory and sends nothing to a printer. A real job leaves this line out and the default controller sends the pages to the printer (add `PrintDialog` before it if the user should choose a printer). `GetPreviewPageInfo()` returns the pages, and `Image` is the picture of a page.

### A page is a metafile

The preview image is a **metafile**: the list of the drawing commands, not pixels (its size is in the units of the printer, 4963 by 7015 at 600 dots per inch). A metafile has no `GetPixel`. The function `pageBitmap` draws it on a white `Bitmap` of 827 by 1169 pixels, and then the program can read pixels: the margin is white, the page has black text, and the last page has less on it than the first. The bitmap can be saved as a PNG.

> [!NOTE] Printing needs an installed printer for the page settings, even for a preview. On Windows the *Microsoft Print to PDF* printer is always there; a computer without any printer raises an error when the document asks for its settings.

## What you learned

- the PrintPage event and `HasMorePages`,
- drawing inside `MarginBounds` and paging by the height of a line,
- paper, margins and landscape,
- the preview controller and looking at a page as a bitmap.

## Exercises

1. Print a table with lines between the rows and the columns (`DrawLine`).
2. Print the number of the page as *Page 2 of 3*: first count the pages with the preview controller, then print.
3. Add a button to a form that prints the report with `PrintDialog`.
4. Print a picture on its own page and scale it to fit inside the margins.

## Next

[A chart](tut-36-chart.html)
