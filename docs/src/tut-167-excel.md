---
title: "Excel files"
lead: Reports, price lists and exports often come as Excel files. The ClosedXML package from nuget.org reads and writes .xlsx files without Excel on the computer. This lesson writes a small sales sheet with formulas and a bold header, reads it back, and shows what is special about a package whose classes are interfaces.
---

## What you will learn

- the steps of the NuGet lessons on a package that needs **several** DLLs,
- a workbook, a worksheet and a cell, and how to find a cell by its address,
- text, numbers and formulas in cells, and a style,
- reading a file back, including the result of a formula,
- how to call the methods of ClosedXML that have **overloads**.

## What an .xlsx file is

A `.xlsx` file is a zip file with XML inside: one part for each sheet, one for the styles, and so on. A package that knows the format can make and read these files itself, so the program does not need Excel, and it works on a server or on Linux. The package here is **ClosedXML**. It uses a few other packages, and `dotnet publish` copies all of them, as in the lesson [A NuGet package](tut-162-nuget.html).

| Part of a file | In ClosedXML | Example |
|---|---|---|
| the file | a **workbook**, `XLWorkbook` | `new XLWorkbook()` |
| a sheet of the file | a **worksheet** | `oBook.AddWorksheet("Sales")` |
| one square | a **cell**, by its address | `oSheet.Cell("B2")` |
| a group of squares | a **range** | `oSheet.Range("A1:D1")` |

## The steps

1. A project file names the package (`Excel/Excel.csproj` here), and `dotnet publish Excel -c Release -o Excel/libs` copies ClosedXML **and the DLLs it needs** into `Excel/libs`.
2. `wrapassembly.ring` writes Ring classes for the namespace `ClosedXML.Excel` of `ClosedXML.dll`. The other DLLs are not wrapped: ClosedXML uses them by itself.
3. `dnLoad` and `dnImportFrom`.
4. The classes are used.

{{file:samples/UsingDotNet/tutorials/Excel/Excel.csproj}}

## The program

{{file:samples/UsingDotNet/tutorials/ch13_excel.ring}}

{{output:samples/UsingDotNet/tutorials/ch13_excel.ring}}

## How it works

### Writing

`oSheet.Cell("B2").Value = 12.5` puts a number in a cell, and `.Value = "Tea"` puts a text. The type of the value decides the type of the cell: a number stays a number in Excel, so a formula can use it, and a text stays a text.

A formula is a text that starts with `=`, written to `FormulaA1` (the cell address style of Excel, `A1`): `"=B2*C2"`. The program builds one for each row with a Ring text (`"=B" + nLine + "*C" + nLine`). A formula is worked out when a value is **read** (by ClosedXML here, and by Excel when a person opens the file), so the program reads the file back to print the totals.

The bold header is a **style**: `Range("A1:D1").Style.Font.Bold = true` gives the whole range one setting.

### Reading

`new XLWorkbook().New_([ :file = cFile ])` opens an existing file (a constructor chosen by the name of its parameter, the form of [The generic functions](tut-160-generic-calls.html)), and `Worksheet("Sales")` takes a sheet by its name. `LastRowUsed(NULL).RowNumber()` is the number of the last row that has anything in it, so the program loops from 1 to it.

A cell holds a `Value`, and a value has methods: `ToString()` is the text of the value (also for a number or a formula), `GetNumber()` is the number. A cell that is empty gives an empty text, as in the last row of the output.

> [!NOTE] Ring writes a number with decimals using two decimals when it joins it to a text, so `GetNumber()` of 126.5 prints as `126.50` in the last line. The cell holds 126.5.

### Interfaces

ClosedXML gives you **interfaces**: `AddWorksheet` returns an `IXLWorksheet`, `Cell` returns an `IXLCell`, and the classes behind them are not public. The generated Ring classes are named after the interfaces (`IXLWorksheet`, `IXLCell`, `IXLRange`), and the objects that come back are wrapped as the right one. You never write `new IXLCell`: you get cells from the worksheet. An interface can inherit members from other interfaces (`Font.Bold` is declared in `IXLFontBase`), and they are all available.

### Overloads

Most of the methods of ClosedXML have several versions, and the rules of [Core concepts](concepts.html) apply:

| In C# | In Ring |
|---|---|
| `Cell("B2")` | `Cell("B2")` |
| `Cell(2, 2)` | `Cell([ :row = 2, :column = 2 ])` |
| `LastRowUsed()` | `LastRowUsed(NULL)` |
| `Worksheet("Sales")` or `Worksheet(1)` | `Worksheet("Sales")` or `Worksheet(1)` |

The names of the parameters are in the files that the generator wrote (`Excel/classes/ClosedXML.Excel.classes.ring`).

### Using ClosedXML in a program

- **Check the licence** of every package before you give a program to others. It is on the page of the package at nuget.org.
- **Close what you open**: `Dispose()` of a workbook releases the file, so it can be moved or deleted. The program does that before it deletes the file.
- **Many cells are many calls.** Every `Cell(...).Value = ...` crosses the bridge. A sheet of a few thousand cells is fine; for hundreds of thousands, look for a method of the package that takes many values at once (ClosedXML has `InsertData` for that).

## What you learned

- an `.xlsx` file is made and read by a package, and no Excel is needed,
- `dotnet publish` brings a package with all its DLLs, and `wrapassembly.ring` can wrap just one namespace,
- cells are found by address, and hold texts, numbers and formulas,
- the classes of a package that works with interfaces,
- overloads: named parameters and `NULL`.

## Exercises

1. Add a fourth product, and change the sum to include its row.
2. Change the total of the last row to the average price: `"=AVERAGE(B2:B4)"`.
3. Open a sheet that you made in Excel and print the text of the first column.
4. Write the Ring list of a CSV file (the tutorial [Tabular data](tut-30-tables.html)) into a sheet, one cell for each field.

## Next

[Testing your programs](tut-28-testing.html)
