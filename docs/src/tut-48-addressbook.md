---
title: "Tutorial 48: A project: an address book with a database"
lead: A real application: contacts stored in a database, shown in a data grid, searched as you type, added, changed and deleted. Windows Forms and Entity Framework working together.
---

## What you will learn

- connecting a database to a window,
- a `DataGridView` as a *view* of the database (not the data itself),
- searching with SQL parameters while typing,
- keeping the grid, the fields and the database consistent,
- tests for a complete application.

## The design

Three layers, as in [tutorial 35](tut-35-tictactoe.html):

| Layer | Holds |
|---|---|
| **Database** (`oDb`) | the truth: the contacts, stored in a SQLite file |
| **Grid data** (`oTable`) | a copy of the rows that match the search, for display |
| **Window** | the grid, the search box, the fields and the buttons |

The golden rule: **the database changes first, then the grid is reloaded**. The grid is never edited directly, so it can never disagree with the database.

## The program

{{file:docs/tutorials/g48_addressbook.ring}}

![The address book](img/shots/tut-g48.png "Four contacts; the first is chosen and its fields are filled")

{{output:docs/tutorials/g48_addressbook.ring --selftest}}

## How it works

### The database

A table `Contacts` with a required `Name` (at most 60 characters), `Phone` and `City`. The program uses a file `addressbook.db` next to it, so the contacts are there the next time; a test uses memory (`:memory:`) so it leaves nothing behind. ([Tutorial 17](tut-17-databases.html) explains the schema.)

### The grid and `reload`

`DataGridView.DataSource = oTable` shows a `DataTable`. `reload()` is the heart of the program: it clears the table, asks the database for the rows that match the search text, and adds one row per contact. It is called at the start and after every change. The status line says `3 of 4 contacts`.

### Search as you type

`oSearch.setTextChangedEvent("reload()")` reloads on every key. The query uses SQL parameters:

```ring
oDb.where("Contacts","Name LIKE {0} OR City LIKE {0}",["%" + cFind + "%"])
```

`LIKE` with `%` means "contains"; SQLite compares case-insensitively for ordinary letters, so `cairo` finds `Cairo`. The text is passed as a **parameter**, never pasted into the SQL: a visitor who types `'; drop table` gets no result, not a disaster.

### Hiding the key

The key column `Id` is needed to know *which* contact a row is, but the user should not see it. The grid creates its columns only after it is bound and shown, so the program hides the column in the `DataBindingComplete` event (`hideKey`), when the columns exist.

### From grid to fields

`setSelectionChangedEvent("rowChosen()")` fills the text boxes from the selected row. `currentId()` reads the hidden key of the **selected row** (`SelectedRows`) — the key tells `update` and `remove` which database row to change.

### The buttons

| Button | Does |
|---|---|
| **Add** | checks the name, inserts, clears the fields, reloads |
| **Update** | updates the chosen contact with the fields, reloads |
| **Delete** | asks `uiAsk`, removes, clears, reloads |

`reload()` clears the grid, and with it the selection: after an update the program does not know which row the user had. A friendlier version remembers the key and selects that row again (exercise 2).

### The test

The test adds three contacts through the fields and the **Add** button, checks the database count and the grid rows, tries a contact without a name, searches `cairo`, selects a row and checks that the fields follow, updates, deletes (the test `uiAsk` answers yes) and checks the database and the grid again. This test is the best documentation of how the program should behave.

## What you learned

- the database is the truth, the grid is a view,
- one `reload()` after every change,
- search with `LIKE` and parameters,
- `DataBindingComplete` for column settings,
- test through the same controls the user uses.

## Exercises

1. Sort the contacts by name (`["orderby",...]` with `query`, [tutorial 17](tut-17-databases.html)).
2. After an update, select the row with the same key again.
3. Add a `Notes` table with several notes per contact and show them in a second grid ([tutorial 27](tut-27-entities.html)).
4. Export the contacts to CSV ([tutorial 30](tut-30-tables.html)).

## Next

[Tutorial 49: Login, sessions and cookies](tut-49-login.html).
