---
title: "Tutorial 27: Entity objects and migrations"
lead: Work with the rows of your tables as real objects that EF Core tracks, and change a database that already holds data without losing it.
---

## What you will learn

- the object style of Entity Framework: `RingEntityDb`,
- navigation properties and `include`,
- tracked objects and `save()`,
- migrations: add columns, tables and indexes to an existing file,
- named, run-once changes with `apply`.

## Two styles, one schema

[Tutorial 17](tut-17-databases.html) used `RingDatabase`: a row is a list of `[column, value]` pairs. `RingEntityDb` uses the **same schema** but turns each table into a real .NET class. A row is an object; related rows are properties of the object.

| | `RingDatabase` | `RingEntityDb` |
|---|---|---|
| a row | `[["Name","Ann"],["Goals",5]]` | an object: `oPlayer.getProp("Name")` |
| a related row | `parent(...)`, `children(...)` | `oPlayer.getProp("Team")`, `oTeam.getProp("Players")` |
| changing | `update(table, key, values)` | `oPlayer.setProp("Goals",8)` then `save()` |
| best for | scripts, quick tools | programs that work with objects for a while |

## Part 1: objects

{{file:docs/tutorials/e03_entities.ring}}

{{output:docs/tutorials/e03_entities.ring}}

### How it works

**Properties.** `oDb.properties("Players")` lists them: one per column (`Id Name Goals TeamId`) and one **navigation** (`Team`), generated from the foreign key `TeamId`. The team has `Players`, a collection of its players.

**Create.** `newEntity("Teams")` gives an empty object, `setProp` sets a property, `add` stores it and fills in the key. For a player, `oAnn.setProp("Team", oRed)` sets the *navigation*, and EF fills in `TeamId` itself (`1`). You can also set `TeamId` directly.

**Read.** `query(table, spec)` returns objects. `["include",["Team"]]` loads the related team in the same query; without it the navigation is empty. Read it with `oPlayer.getProp("Team").getProp("Name")`.

**Tracked.** EF remembers the objects it gave you. Change one (`setProp("Goals",8)`) and call `save()`: EF finds the change and writes only that. `discard()` forgets the tracked objects, so that the next `find` reads from the database again — the program uses it to prove that the change really reached the database.

**Collections.** `oTeam.getProp("Players")` is a .NET collection: `getProp("Count")` and `toList()` work on it.

## Part 2: migrations

You shipped version 1 of a program. Users have data. In version 2 you need a `Phone` column and a `Notes` table. If you only change the schema in the program, the *old file still has the old tables*: new code meets old data. A **migration** brings the file up to date.

{{file:docs/tutorials/e04_migrations.ring}}

{{output:docs/tutorials/e04_migrations.ring}}

### How it works

- `migrate()` compares the **schema in the program** with **the file** and creates what is missing: new columns (`add column Contacts.Phone`), new tables, new indexes. It returns the list of changes. Existing rows are kept; a new column gets its default (`level 1`) or stays empty.
- Calling `migrate()` again changes nothing, so you may call it **every time the program starts**.
- `apply("001-promote", sql)` runs a SQL change **once**. The name is stored in a table (`RingMigrations`); the second call returns `0` and does nothing. Use it for what a schema comparison cannot do: change data, rename or drop things.

> [!NOTE] `migrate()` never drops or changes a column. Removing a column is a decision about losing data: do it deliberately with `apply` and your own SQL. `migrate` works for SQLite files.

> [!TIP] `byKey` returns the tracked row. After a raw SQL change (`apply`, `execute`) call `discard()` before reading, or you will see the old values.

## What you learned

- objects and navigation properties,
- `include` loads related objects,
- change a property, `save()`,
- `migrate()` for schema changes, `apply()` for one-time data changes.

## Exercises

1. Add a `Matches` table (two teams, a score) and print every match with both team names.
2. Move a player to another team by changing the `Team` navigation and saving.
3. Add a `Email` column in version 3 and write the migration steps.
4. Count the goals of each team with a `for` loop over `query("Teams", [["include",["Players"]]])`.

## Next

[Tutorial 115: Microsoft Access databases](tut-115-access.html)
