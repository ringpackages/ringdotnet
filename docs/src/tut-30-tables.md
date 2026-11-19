---
title: "Tutorial 30: Tabular data"
lead: Rows and columns are everywhere — spreadsheets, CSV files, database results. This lesson reads a CSV text into a DataTable, then filters, sorts, summarises and writes it back.
---

## What you will learn

- what CSV is and how to read it,
- `DataTable`, `DataRow`, `DataView`,
- `Compute` for sums, averages, counts,
- sorting and filtering without changing the data,
- grouping by hand and writing CSV.

## CSV

*CSV* (comma separated values) is the simplest table format: a header line with the column names, then one line per row with the values separated by commas.

```text
Region,Seller,Amount
North,Ann,1200
South,Bob,800
```

Spreadsheets, databases and many programs read and write it.

> [!NOTE] Real CSV files can contain commas inside quoted values (`"Smith, John"`). This tutorial's data has none, so splitting on commas is enough. For messy files use a CSV library (a NuGet package, [tutorial 18](tut-18-csharp-library.html)) or a regular expression.

## The program

{{file:docs/tutorials/t30_tables.ring}}

{{output:docs/tutorials/t30_tables.ring}}

## How it works

### Step 2: the table

A `DataTable` has **typed columns**: `Region` and `Seller` are texts, `Amount` is an integer (`System.Int32`). Types matter: sums and sorting treat numbers as numbers, not as text (as text, `800` would sort after `2000`). `Rows.Add([...])` adds a row; the values are in column order. The program turns the lines into rows: `str2list` splits the text into lines, `substr(line,",",nl)` turns the commas into line breaks, and `number()` converts the amount.

### Step 3: Compute

`Compute(expression, filter)` evaluates an aggregate over the rows that pass the filter:

| Expression | Meaning |
|---|---|
| `SUM(Amount)` | the total |
| `AVG(Amount)` | the average |
| `MIN(Amount)` / `MAX(Amount)` | the smallest / biggest |
| `COUNT(Amount)` | how many |

The filter is a text such as `Region = 'North'` or `Amount > 500`: a small SQL-like language. An empty filter means all rows. Text values go in single quotes.

### Step 4: a DataView

A `DataView` is a **window onto the table** with its own sort order and filter. `oView.Sort = "Amount DESC"` sorts, `oView.RowFilter = "Region = 'South'"` hides other rows, and `oView.Count` counts what is visible. The table itself is not changed; `RowFilter = ""` shows everything again. A grid bound to a view ([tutorial 23](tut-23-layout.html)) updates by itself.

### Step 5: groups

`Compute` has no "group by". Collect the different regions, then ask for the sum of each: a loop, `find` to avoid duplicates, `sort` to order them. (A database does this with `GROUP BY`; with a SQLite table, `groupCount` and `sqlRows` in [tutorial 17](tut-17-databases.html).)

### Step 6: writing CSV

Loop over the rows and build lines. Join the values with commas and the lines with `nl`. Remember to quote values that contain commas.

## What you learned

- tables have typed columns,
- `Compute` summarises, `DataView` sorts and filters,
- group by with a loop,
- reading and writing CSV is a text job.

## Exercises

1. Add the average sale per seller.
2. Sort by region, then by amount descending (`oView.Sort = "Region, Amount DESC"`).
3. Write only the rows of one region to a new CSV file.
4. Add a calculated column `Commission` = `Amount * 0.1` (`Columns.Add` with an `Expression`).

## Next

[Tutorial 73: Reports with SQL](tut-73-sql-reports.html)
