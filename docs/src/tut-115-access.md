---
title: "Microsoft Access databases"
lead: Many small businesses keep their data in an Access file. This lesson uses an .accdb file from Ring through ODBC — it makes the file, creates tables, inserts rows with parameters, runs joins and totals, works with dates, and uses a transaction. It runs on Windows with the Microsoft Access Database Engine.
---

## What you will learn

- what is needed to use Access from Ring (and why it works only on Windows),
- making a new `.accdb` file (ADOX) and connecting with `OdbcConnection`,
- the Access column types and SQL dialect,
- parameters (`?`) instead of text joined into a statement,
- reading rows with a reader, joins, `GROUP BY`, `TOP`, `LIKE`,
- dates, transactions, closing,
- the limits of Access and when to choose another database.

The tutorial [Databases step by step](tut-17-databases.html) used SQLite and the tutorial [Reports with SQL](tut-73-sql-reports.html) wrote reports with SQL. The ideas are the same; only the driver and a few details of the SQL change.

## What you need

| Need | Why |
|---|---|
| **Windows** | the Access drivers exist only there |
| the **Microsoft Access Database Engine**, **64-bit** | it brings the ODBC driver *Microsoft Access Driver (\*.mdb, \*.accdb)* and the OLEDB provider. It is installed with Microsoft Access or Microsoft 365, or from the free "Access Database Engine Redistributable" |
| `System.Data.Odbc.dll` | the .NET classes for ODBC. They are a NuGet package, not part of the runtime; the RingDotNet package has the file in its `bin` folder and the program loads it with `dnLoad` |

**The bitness must match.** Ring and the .NET runtime here are 64-bit, so the driver must be 64-bit. If a 32-bit Microsoft Office is installed, the 64-bit engine cannot be installed next to it, and the connection fails with *"Data source name not found"* or *"provider not registered"*. The program checks the registry for the driver and, when anything is missing, prints what is missing and stops without an error (the output below shows the real run of this computer; on Linux the program says that Access needs Windows).

## The program

{{file:samples/UsingDotNet/tutorials/ch09_access.ring}}

{{output:samples/UsingDotNet/tutorials/ch09_access.ring}}

> [!NOTE] This program uses a few generic functions (`dnNew`, `dnStatic`, `dnType`, `callMethod`, `getProp`, `setProp`, `dnNull`) where a class cannot be used. The lesson [The generic functions](tut-160-generic-calls.html) explains them.

## How it works

### A new file

The ODBC driver opens Access files but **cannot create** one. **ADOX** can: it is a COM component that comes with Access, and `Catalog.Create(connection string)` makes an empty `.accdb`. The program reaches it through reflection: `Type.GetTypeFromProgID("ADOX.Catalog")`, `Activator.CreateInstance`, and `Type.InvokeMember("Create", ...)` with the connection string of the OLEDB provider (`Provider=Microsoft.ACE.OLEDB.16.0;Data Source=file`). If you already have an Access file, skip this step and just open it.

### The connection

`Driver={Microsoft Access Driver (*.mdb, *.accdb)};Dbq=C:\path\file.accdb;` names the driver and the file. For a file with a database password add `Pwd=secret;`; for a read-only open add `ReadOnly=1;`. The classes of `System.Data.Odbc` have no generated Ring classes, so the program makes them with `dnNew(type, [arguments])` and uses `callMethod` and `getProp` ([Core concepts](concepts.html), *Plain objects*). A command is made with `CreateCommand()`, its `CommandText` is the SQL, and `ExecuteNonQuery()` runs a statement that changes data (the answer is the number of rows), `ExecuteScalar()` gives one value and `ExecuteReader()` gives rows.

### Column types and SQL

Access has its own names for types and a few differences in its SQL:

| Wanted | Access SQL |
|---|---|
| a number that counts by itself | `AUTOINCREMENT` (or `COUNTER`) |
| text of up to n characters | `TEXT(n)` (up to 255) or `MEMO` for long text |
| a whole number | `LONG` (4 bytes) or `INTEGER` (2 bytes) |
| money, exact | `CURRENCY` (fixed 4 decimals) |
| date and time | `DATETIME` |
| yes or no | `YESNO` |
| the first n rows | `SELECT TOP n ...` (there is no `LIMIT`) |
| a name with a space or a reserved word | in brackets: `[Order Date]` |

Searching with `LIKE` uses `%` and `_` through ODBC (in the Access program itself it is `*` and `?`). `SELECT * FROM T WHERE 1 = 0` returns no rows but describes the columns, which the program uses to list the column names and types (`GetSchema("Columns", restrictions)` answers "Optional feature not implemented" with this driver; `GetSchema("Tables")` works).

### Parameters

`INSERT INTO Customers (Name, City, Vip) VALUES (?, ?, ?)` has **placeholders**; the values go into the command's `Parameters` (`AddWithValue`). The driver uses them **in the order of the `?` marks**, so the names do not matter. Parameters are not only a convenience: a name such as `Bob O'Neil` would break a statement made by joining text (the apostrophe ends the text), and a value such as `x'; DROP TABLE Customers; --` could change what the statement does. As a parameter it is plain data. **Never put a value into the text of a statement.** The program shows that the apostrophe and the Arabic name come back exactly as they went in: Access stores Unicode text.

### Reading rows

`ExecuteReader()` gives a reader; `Read()` moves to the next row and answers *false* at the end; `GetValue(n)` reads column n (0 is the first). `FieldCount`, `GetName` and `GetDataTypeName` describe the columns. Numbers and `CURRENCY` come back as Ring numbers, text as text and a `DATETIME` as a .NET `DateTime`, which the program formats with `Format("yyyy-MM-dd")`. A column without a value is a **NULL** (`System.DBNull`): test for it before you use the value, and remember that `COUNT(column)` does not count NULL values while `COUNT(*)` counts rows. Dispose the reader (`Dispose()`) before you run the next command on the same connection.

### Joins and totals

`INNER JOIN ... ON c.Id = o.CustomerId` puts the orders next to their customers. `GROUP BY` makes one row for each group with `COUNT`, `SUM` and `AVG`; `HAVING` filters the **groups** (where `WHERE` filters the **rows** before they are grouped). The result shows that customers with fewer than two orders are not listed. `SUM` of a currency column is exact, which is why money is `CURRENCY` and not a floating-point number (the tutorial [Money](tut-57-money.html)).

### Dates

A `DateTime` object goes in as a parameter and the comparison `Ordered > ?` works with real dates, so there is no need for the Access date literal `#2/15/2024#` (which also depends on the format of the computer). Access has date functions in SQL: `Year(d)`, `Month(d)`, `Day(d)`, `DateAdd`, `DateDiff` and `Format(d, "yyyy-mm")`.

### Transactions

`BeginTransaction()` makes several statements **one change**: `Commit()` keeps them, `Rollback()` undoes them. In step 10 the first `UPDATE` is correct and the second one names a table that does not exist, so the program rolls everything back, and the city of Ann is still Cairo. Every command that belongs to the transaction needs `Transaction` set to it (`runSqlIn`). Use a transaction whenever two changes must stay together (a transfer between two accounts, an order with its lines); it is also much **faster** for many inserts, because Access writes to the disk once at the end.

### Closing

Close the connection (`Close()`, `Dispose()`) and call `OdbcConnection.ReleaseObjectPool()`: ODBC keeps closed connections for reuse. The **Access engine keeps the file open until the program ends**, so the program cannot delete its test file at once (a `.laccdb` lock file appears next to the database while it is open). The program removes the old file at the start of the next run.

## Limits and advice

- **Size and users.** An Access file is limited to **2 GB** and is meant for a **few users** on a fast local disk; there is no server, every program opens the file itself. It is not a good choice for a web site with many visitors or for a file on a slow network share.
- **Backups.** The file is the database: copy it when no program has it open (or after *compact and repair*, which the `JRO.JetEngine` COM object does).
- **Old files.** `.mdb` files of Access 97 or 2000 may need the older *Jet* engine, which has no 64-bit version; open them in Access and save them as `.accdb`.
- **Moving on.** When the data grows or many users need it, move it to **SQLite** (the tutorial [Databases step by step](tut-17-databases.html), a file without a server) or to **SQL Server** and use Entity Framework (the tutorial [Entity objects and migrations](tut-27-entities.html)). The Access driver can read the old file for the copy. The same ODBC driver family also reads **Excel** and **text/CSV** files (`Microsoft Excel Driver`, `Microsoft Access Text Driver`) with the same code.

> [!NOTE] `samples/UsingDotNet/tests/test_access.ring` tests all of this with 29 checks (Unicode, NULL, transactions, an attack text) and skips itself where Access is not available.

## What you learned

- Access needs Windows, the 64-bit Access Database Engine and `System.Data.Odbc.dll`,
- ADOX makes a new file; ODBC opens it,
- the Access column types and the small differences of its SQL,
- parameters instead of text in statements,
- readers, joins, grouping, dates and transactions,
- the limits of Access.

## Exercises

1. Add a table `Products` and a table `OrderLines` and make a report of the quantity sold for each product.
2. Write `insertMany(oConnection, cSql, aRows)` that inserts a list of rows inside **one** transaction, and compare its time with single inserts for 1000 rows (the tutorial [Speed — measure first](tut-53-speed.html)).
3. Write `export(oConnection, cTable, cFile)` that writes a table as JSON (the tutorial [Writing JSON as a stream](tut-100-json-writer.html)).
4. Open an existing `.accdb` file of your own and list its tables and columns.

## Next

[Settings](tut-32-settings.html)
