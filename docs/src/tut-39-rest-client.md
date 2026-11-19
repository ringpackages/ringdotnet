---
title: "Tutorial 39: A REST client"
lead: Most services on the internet speak JSON over HTTP. This lesson calls such a service, reads the answer, checks the status, sends data, and handles a server that is not there.
---

## What you will learn

- what REST means in practice,
- sending `GET` and `POST` requests with a JSON body,
- reading the status and the JSON answer,
- timeouts and errors,
- keeping the request code in one helper function.

## REST in one minute

A **REST service** gives you things (*resources*) at addresses and lets you use the HTTP methods on them:

| Request | Meaning |
|---|---|
| `GET /api/books` | the list of books |
| `GET /api/book?id=2` | one book |
| `POST /api/books` + JSON | add a book |
| `PUT` / `DELETE` | change / remove |

The answers are JSON, and the **status code** tells whether it worked: `200` OK, `201` Created, `404` Not Found, `500` server error. A good client always looks at the status before it trusts the body.

## The program

For this tutorial the service is started in the same program, so that it needs no internet. The *client* code is exactly what you would write for a real service: only `cUrl` would be different.

{{file:docs/tutorials/t39_rest_client.ring}}

{{output:docs/tutorials/t39_rest_client.ring}}

## How it works

### One helper for all requests

`request(method, path, body)` builds the request, sends it, waits and returns `[status, body]`. Everything else calls it. A request is an `HttpRequestMessage` created with **named arguments**: `[ :method = new HttpMethod(cMethod), :requestUri = cUrl + cPath ]`. For a `POST` the body is a `StringContent` with the text, the encoding (`UTF8`) and the **media type** `application/json`, which tells the server how to read it.

> [!NOTE] The content is created in a variable first (`oContent = dnNew(...)`) and then assigned to `oMessage.Content`. Putting `new Encoding().UTF8` inside the right side of an assignment to a property loses the assignment.

### The Task pattern

`SendAsync` returns a `Task` at once; `Wait(NULL)` waits for the answer; `getProp("Result")` is the `HttpResponseMessage`. Reading the body is again asynchronous (`ReadAsStringAsync`). Here, because the server lives in the same program, the helper calls `serveOne` while it waits; with a real server on the internet you would just wait.

### Reading JSON

Step 1 parses the array with `JsonDocument`: `GetArrayLength()`, `Item(i)`, and for each book `GetProperty("title").GetString()` and `GetProperty("year").GetInt32()`. Call `Dispose()` on the document when you are done ([tutorial 6](tut-06-json-xml.html)).

### Status first

Step 3 asks for a book that does not exist. The status is `NotFound` and the body is a message, not JSON. If the client had tried to parse the body as JSON it would have failed. **Check the status, then read the body.**

### Sending data

Step 4 posts `{"title":"Foundation","year":1951}`. The service answers `201 Created` with the new id, and the list has four books.

### Timeouts and errors

`oClient.Timeout = new TimeSpan().FromSeconds(5)` stops waiting after five seconds: without a timeout a dead server can block your program for minutes. Step 5 calls an address where nobody listens; the call raises an error, and the `try` / `catch` turns it into a message for the user. Real programs also retry after a pause and tell the user in plain words ("The service is not available, try again later").

## What you learned

- GET and POST with JSON,
- status before body,
- `Task` + `Wait` + `Result`,
- timeouts and catching network errors,
- one request helper.

## Exercises

1. Add `deleteBook(nId)` using the `DELETE` method (and a handler on the service).
2. Retry a failed request up to three times with a pause (`Thread.Sleep`).
3. Add an `Accept` header (`oClient.DefaultRequestHeaders.Add(...)`).
4. Call a real public API (for example a free JSON placeholder service) and print three fields. You need internet for this one.

## Next

[Tutorial 16: A web service](tut-16-web-service.html)
