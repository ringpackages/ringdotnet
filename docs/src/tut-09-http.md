---
title: "HTTP"
lead: Almost every program talks to another over HTTP. This lesson builds a tiny web server and a web client in one program, so you can see both sides of the conversation.
---

## What you will learn

- what HTTP requests and responses are,
- a web server whose addresses are Ring functions,
- a web client with `HttpClient`,
- why requests are *asynchronous* and what a `Task` is,
- status codes.

## HTTP in one minute

A client sends a **request**: a *method* (`GET` to read, `POST` to send data, `DELETE` to remove), an *address*, optional data. The server sends a **response**: a *status code* (`200` OK, `201` Created, `404` Not Found, `500` error) and a body (text, HTML or JSON).

## The program

{{file:samples/UsingDotNet/tutorials/t09_http.ring}}

{{output:samples/UsingDotNet/tutorials/t09_http.ring}}

> [!NOTE] The port number is chosen by Windows, so it differs on every run.

## How it works

### The server

`using { ..., "RingDotNet.Web" }` (first!) starts the ASP.NET Core runtime. `new WebServer("http://127.0.0.1:0")` starts a server on your computer (`127.0.0.1` is "this computer"); port `0` means "any free port", and `oServer.url()` tells you which one.

Each address is connected to a Ring function with `onGet`, `onPost`, `onDelete`. The function receives the request and **returns the answer**:

| The handler returns | The response |
|---|---|
| a text | status 200, the text as HTML |
| `[status, contentType, text]` | exactly that |
| `webJson(list)` | status 200, JSON |

A path that has no handler answers `404 Not found`.

### The client

`HttpClient.GetAsync(url)` sends a `GET`; `PostAsync(url, content)` sends data. These methods are **asynchronous**: they return at once with a **Task**, an object that stands for "the answer will come". `Wait(NULL)` waits for it, and `getProp("Result")` is the answer (the response). The body is also asynchronous: `ReadAsStringAsync(NULL)` is another Task.

### Why serveOne

The web server runs on .NET's own threads, but your Ring code may only run on the Ring thread. The server therefore puts each request in a queue, and `oServer.serveOne(100)` takes one request off the queue — waiting up to 100 ms — and runs your handler *on the Ring thread*. Here client and server are in the same program, so while the client waits, the program calls `serveOne`. A real server just calls `oServer.run()`, which serves until `stop()`.

### Status codes

`oResponse.StatusCode` is an enum, so Ring gets the text `OK`, `Created`, `NotFound`. `201 Created` is the right answer when a `POST` made something new.

## What you learned

- requests have a method, an address and maybe a body; responses have a status and a body,
- handlers return text, `[status, type, text]` or `webJson`,
- asynchronous calls return a `Task`: wait, then read `Result`,
- `serveOne()` hands requests to Ring.

## Exercises

1. Add a `/hello` variant `/hello?name=Ann` that returns `Hello, Ann`. (`oRequest.query("name")`.)
2. Make `/time` return the real time with `DateTime.Now`.
3. Add a `DELETE /item` handler that answers `404` for unknown items.
4. Call a real web site: `oClient.GetStringAsync("https://example.com")` and print the length of the answer (needs internet).

## Next

[Time, tasks and other programs](tut-10-tasks-processes.html)
