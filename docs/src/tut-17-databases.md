---
title: "Tutorial 17: Databases step by step"
lead: Store data that survives the end of the program. Describe tables, add and read rows, search, connect tables, ask questions, group a transaction, and keep everything in a file.
---

## What you will learn

- what a database, a table, a row and a key are,
- describing tables as data and creating them,
- insert, read, update, delete,
- searching safely with SQL parameters,
- relations between tables,
- queries, aggregates, transactions and file databases.

## Database words

| Word | Meaning |
|---|---|
| **table** | a list of rows of the same shape (like a spreadsheet sheet) |
| **column** | one field of every row (`Title`, `Year`) |
| **row** | one record |
| **key** | a column that identifies a row (`Id`); the database numbers it for you |
| **foreign key** | a column that holds the key of a row in *another* table (`AuthorId`) |
| **SQL** | the language of databases; you only need a little of it |

RingDotNet uses **Entity Framework Core** with **SQLite**, a database in one file (or in memory). You describe the tables as Ring data; there is no SQL to write for normal work.

## Part 1: tables, rows, searches

{{file:docs/tutorials/e01_library.ring}}

{{output:docs/tutorials/e01_library.ring}}

### Step by step

**Step 1 — the schema.** A table is `[name, [columns]]`; a column is `[name, type, isKey, options]`. Types: `int long double decimal string bool datetime bytes`. `["Id","int",1]` is a key, numbered automatically. Options make rules the database enforces:

| Option | Rule |
|---|---|
| `["required",1]` | a value must be given |
| `["unique",1]` | no two rows may have the same value |
| `["maxlength",80]` | at most 80 characters |
| `["nullable",1]` | the value may be missing (a number can be empty) |
| `["default",1]` | the value to use when none is given |
| `["references","Authors"]` | the value must be the key of a row in `Authors` |
| `["ondelete","cascade"]` | deleting the author deletes the books too |

**Step 2 — add rows.** `insert(table, values)` takes a list of `[column, value]` pairs and returns the new key. `count` counts the rows.

**Step 3 — read rows.** A row is a list of `[column, value]` pairs; `dbValue(aRow,"Title")` reads one column, and returns `""` for a missing value.

**Step 4 — search.** `where(table, condition, parameters)` takes SQL such as `Year > {0}` and the values for `{0}`, `{1}`... as a list. **Always pass values as parameters**: they are never mixed into the SQL text, so a user typing `x' OR '1'='1` cannot break your query (this attack is called *SQL injection*).

**Step 5 — change and delete.** `update(table, key, values)` changes columns of one row; `remove(table, key)` deletes it.

**Step 6 — mistakes are errors.** The database refuses a duplicate in a `unique` column and a foreign key that points to nothing. Catch the error with `try`/`catch`.

## Part 2: relations, queries, transactions, files

{{file:docs/tutorials/e02_library_queries.ring}}

{{output:docs/tutorials/e02_library_queries.ring}}

### Relations

`children("Authors", key, "Books")` gives the books of an author; `parent("Books", key, "Authors")` gives the author of a book; `include("Authors","Books")` gives every author with their books in one call.

### Queries as data

For more than a simple condition, write the query as a list:

```ring
oDb.query("Books",[
	["where",["Stars",">=",4.5]],
	["orderby",[["Year","desc"]]],
	["select",["Title","Year"]]
])
```

A condition is `[column, operator, value]` with `= != < <= > >= contains startswith endswith in isnull notnull`, and can be combined with `["and", c1, c2]`, `["or", ...]`, `["not", c]`. `sum`, `min`, `max`, `average`, `countWhere` and `groupCount` summarise.

### Transactions

A **transaction** groups changes: `begin()`, several changes, then `commit()` to keep them or `rollback()` to cancel all. The program adds two drafts, sees six books, rolls back and sees four again.

### A file database

`"Data Source=" + cFile` stores the database in a file. The program closes it, opens it again and finds the four books: the data survives the program.

## What you learned

- describe the schema as data, let the database enforce the rules,
- parameters, never pasted text,
- relations with foreign keys,
- queries, aggregates, transactions, files.

## Exercises

1. Add a `Members` table and a `Loans` table (a member borrows a book) and list who has which book.
2. Write a function that lists the authors with no books.
3. Use `migrate()` after adding a `Pages` column to the schema ([Entity Framework](ef.html#migrations)).
4. Use `RingEntityDb` for the same data and compare ([Entity Framework](ef.html#real-entity-classes)).

## Next

[Tutorial 18: A library written in C#](tut-18-csharp-library.html).
