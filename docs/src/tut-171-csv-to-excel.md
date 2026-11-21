---
title: "A project: from CSV to Excel"
lead: A real program uses several packages together. This project reads sales from a CSV text with CsvHelper, keeps the rows in a LiteDB database, finds some of them with a query, adds up the amounts by region, and writes an Excel report with ClosedXML. It brings the lessons on packages together in one program.
---

## What you will learn

- using **three packages** from one project file and one `dotnet publish`,
- wrapping each DLL into its own folder and loading the classes,
- reading a CSV with **CsvHelper** (the header, and fields by the name of their column),
- keeping rows as documents in **LiteDB** and finding rows with a query,
- turning the answers into an Excel file with **ClosedXML**, and reading it back to check it.

## The plan

The program has one job, and each package does one part of it:

| Step | Package | What happens |
|---|---|---|
| 1 | CsvHelper | the CSV text is read row by row, and a field is taken by the name of its column |
| 2 | LiteDB | each row is stored as a document in a collection (a file on disk) |
| 3 | LiteDB | a query finds the rows with 9 units or more |
| 4 | Ring | the amounts are added up for each region |
| 5 | ClosedXML | a workbook with two sheets is written: all rows with a formula for the amount, and the totals |
| 6 | ClosedXML | the file is read back, and the total that the formula gives is checked |

Ring does the adding in step 4 itself, because it is one loop. The point is to see the three packages working together.

## One project for three packages

The packages of the earlier lessons each had a project file of their own. Here one project file names all three, and one `dotnet publish` copies them with everything they need:

{{file:samples/UsingDotNet/tutorials/Report/Report.csproj}}

`wrapassembly.ring` then runs once for each DLL, with a **folder for each** (`Report/classes/CsvHelper`, `.../LiteDB`, `.../ClosedXML`), and each run names the namespace that the program uses. A folder of its own for each assembly keeps the generated files of the three apart.

## The program

{{file:samples/UsingDotNet/tutorials/ch13_csv_to_excel.ring}}

{{output:samples/UsingDotNet/tutorials/ch13_csv_to_excel.ring}}

The totals can be checked by hand: East is 6 × 8 + 3 × 2.5 = 55.5, North is 10 × 2.5 + 4 × 8 + 9 × 3 = 84, South is 7 × 2.5 + 12 × 3 + 2 × 8 = 69.5, and together they are 209, which is also what the formula in the report gives.

## How it works

### Reading the CSV

`CsvReader` takes a reader of text and a culture, which tells it how numbers are written (`en-US` has a decimal point). The text comes from a Ring text here, through a `StringReader`; for a file you would give a `StreamReader` of its path. `Read()` moves to the next row, and the first `Read()` followed by `ReadHeader()` takes the names of the columns, so that `GetField("units")` finds a field **by the name of its column** and not by its position. A field comes back as a text; `number(...)` makes the numbers of it.

### Keeping the rows in LiteDB

LiteDB is a small database in one file, and it keeps **documents**: a document is a set of named values, like a Ring list of pairs. `new BsonDocument()` is a document, and `Add([ :key = ..., :value = ... ])` puts a value in it (the overload is chosen by the names of the parameters). A **collection** is where documents are kept, like a table. Its type is generic, so it has no Ring class of its own and its methods are called with `callMethod`: `Insert`, `Count`, `Find` and `FindAll`.

### Asking a question

`Find` takes a **condition** written as a text in the language of LiteDB: `"$.units >= 9"` says "the field `units` of the document is 9 or more". The condition is made with `new BsonExpression().Create(...)`. The answer is a collection of documents, and `toList()` copies it into a Ring list. A value of a document is read with the method that matches its type: `AsString`, `AsInt32` or `AsDouble`.

### Adding up

LiteDB has its own functions for sums, and the program uses a short loop instead: it keeps a list of `[region, amount]` pairs, finds the region with `find(aTotals,cRegion,1)` and adds the amount of the row. The lists are then sorted so that the output and the report always come in the same order.

### Writing the report

The workbook has two sheets: **Sales** has one row for each sale, and the amount of each row is a **formula** (`=D2*E2`) that Excel works out; the last row has the sum of the column. **By region** has the totals that Ring added up. The header cells are bold. The steps are those of the lesson [Excel files](tut-167-excel.html).

### Reading the report back

A formula has no stored value until something works it out. When the program reads the file back, ClosedXML works out the formula of the total cell, so `GetNumber()` gives 209. That is a simple check that the report is right.

## What you learned

- three packages can share one project file and one publish, each wrapped into its own folder,
- CsvHelper reads rows and fields by the names of the columns,
- LiteDB keeps documents, finds them with a query, and its collections are used with `callMethod`,
- ClosedXML writes sheets with formulas, and reading the file back checks the report,
- each package does one job, and Ring joins the jobs.

## Exercises

1. Add two more rows to the CSV text and see how the totals and the report change.
2. Change the query to `$.region = 'South' AND $.units >= 5` and print the rows that it finds.
3. Read the CSV from a file: write the text to a file, open it with `dnNew("System.IO.StreamReader",[ :path = cFile ])` and give that reader to `CsvReader`.
4. Add a third sheet **By product** with the amount of each product, in the same way as the sheet **By region**.

## Next

[Common mistakes](tut-161-common-errors.html)
