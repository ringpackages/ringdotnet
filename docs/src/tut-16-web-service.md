---
title: "Tutorial 16: A web service with a database"
lead: Put the ideas of the last tutorials together: a web service that stores notes in a database and speaks JSON, with a client that uses it.
---

## What you will learn

- the shape of a small web API (`GET` list, `POST` add, `DELETE` remove),
- storing data with `RingDatabase` from a web handler,
- answering with JSON and the right status codes,
- validating a request.

## The design

A *REST-style* API uses the HTTP method to say what to do and the address to say what to do it with:

| Request | Meaning | Answer |
|---|---|---|
| `GET /notes` | list the notes | `200` and a JSON array |
| `POST /notes` (the text is the body) | add a note | `201` and the new id, or `400` if the text is empty |
| `DELETE /notes?id=1` | delete a note | `200`, or `404` if there is no such note |

## The program

{{file:docs/tutorials/g06_notes_service.ring}}

{{output:docs/tutorials/g06_notes_service.ring}}

## How it works

### Two start-up calls

`dnUseWeb()` starts the web runtime and `dnUseData()` loads Entity Framework. Both before any other .NET call.

### The database

A `RingDatabase` with a table `Notes`: a numbered key `Id`, a required `Text` (at most 200 characters), and a `Done` flag with a default of 0. `"Data Source=:memory:"` keeps the data in memory, which is perfect for a tutorial; use `"Data Source=notes.db"` for a file. See [tutorial 17](tut-17-databases.html).

### The handlers

Each handler is a Ring function that receives the request and returns the response.

- `listNotes` reads every row with `oDb.all("Notes")`, converts each to a list of `[name, value]` pairs and returns `webJson(aList)`. `webJson` turns pairs into JSON *objects*: `{"id":1,"text":"Buy milk"}`.
- `addNote` reads the body, answers `[400, ...]` when it is empty, otherwise inserts and returns `[201, "application/json", ...]` with the new id.
- `deleteNote` reads the query value (`oRequest.query("id")`), removes the row, and answers `404` when `remove` returns `0`.

> [!NOTE] The handlers use `oDb`, a **global** variable, because they run later, from the web server. Remember: code that Ring runs for .NET sees only globals.

### The client

`send` builds an `HttpRequestMessage` with a method and an address (named arguments again: `[ :method = ..., :requestUri = ... ]`), sends it, lets the server handle it with `serveOne`, and reads the response. In a real client program the server runs somewhere else and you never call `serveOne`.

### Errors become responses

Nothing in a handler ends the program: a bad request gets `400`, a missing note `404`. If a handler raises an error, the server answers `500` with the message, and keeps running.

## What you learned

- methods + addresses + status codes make an API,
- handlers use the database and return JSON,
- validate input and answer with the right status,
- globals for what handlers need.

## Exercises

1. Add `PUT /notes?id=1` that marks a note as done (`update`).
2. Add `GET /notes?id=2` that returns one note, or `404`.
3. Make the server serve an HTML page at `/` that lists the notes, as the [WebApi application](aspnet.html) does.
4. Switch to a file database and restart the program: are the notes still there?

## Next

[Tutorial 17: Databases step by step](tut-17-databases.html).
