---
title: ASP.NET Core
lead: A Kestrel web server whose routes are Ring functions — HTML pages, JSON APIs, forms — plus all of the ASP.NET Core classes for everything else.
---

## A web server in a few lines

```ring
load "dotnet.ring"
using { "RingDotNet.Web" }                       # starts the ASP.NET Core mode and loads the web server

oServer = new WebServer("http://localhost:5080")
oServer.onGet("/","home")
oServer.onPost("/api/echo","echo")
oServer.run()                                  # serves until stop()

func home oRequest
	return "<h1>Hello</h1>" + oRequest.path()

func echo oRequest
	return [201,"text/plain","you sent " + oRequest.body()]
```

`using { "RingDotNet.Web" }` starts the ASP.NET Core runtime and loads the web server of RingDotNet (it calls `dnUseWeb()` for you). A **handler** is a Ring function that receives the request and returns the response.

![The page served by the Ring web server](img/shots/web-page.png "samples/UsingDotNet/applications/WebApi — a page rendered by a Ring handler")

## Handlers and responses

A handler returns one of:

| Return value | Response |
|---|---|
| a text | status 200, `text/html` |
| `[status, contentType, text]` | exactly that |
| `webJson(value)` | status 200, `application/json` |

`webJson` turns a Ring list into a JSON array and a list of `[name, value]` pairs into a JSON object (nested values too):

```ring
func listTodos oRequest
	aList = []
	for aTodo in aTodos
		aList + [["id",aTodo[1]],["text",aTodo[2]]]
	next
	return webJson(aList)
```

![The JSON API response](img/shots/web-json.png "GET /api/todos")

## The request

| Method | Returns |
|---|---|
| `oRequest.method()` | `"GET"`, `"POST"` ... |
| `oRequest.path()` | `/api/todos` |
| `oRequest.queryString()` | `?id=1` |
| `oRequest.query("id")` | one query value |
| `oRequest.body()` | the body as text |
| `oRequest.header("Accept")` | a request header |
| `oRequest.form("name")` | a form field of a POST |
| `oRequest.setHeader(name, value)` | add a response header |
| `oRequest.context()` | the ASP.NET `HttpContext`, for everything else |

## The WebServer

| Method | Does |
|---|---|
| `new WebServer(url)` | starts Kestrel; port `0` picks a free port |
| `onGet(path, handler)`, `onPost`, `onPut`, `onDelete` | routes (`route(method, path, handler)` for any method) |
| `notFound(handler)` | the handler for unknown paths (default: `Not found: GET /x`) |
| `url()` | the real address (when the port was 0) |
| `run()` | serve until `stop()` |
| `serveOne(milliseconds)` | handle one waiting request; true if one was handled |
| `stop()`, `close()` | stop serving, stop the server |

An error raised by a handler becomes a **500** response with the message. `nRequests` counts the requests served.

## One Ring thread

Kestrel runs on .NET threads and Ring code may only run on the Ring thread. So the requests are **queued** and `serveOne()` / `run()` take them off the queue on the Ring thread. This is the reason you can use any Ring code and global state in a handler without locks — and also why handlers do not run in parallel.

You can mix serving with your own loop (for example next to a GUI: name `"System.Windows.Forms"` and `"RingDotNet.Web"` in the same `using` block, or call `dnUseAll()`):

```ring
while true
	oServer.serveOne(100)          # handle a request if one arrives within 100 ms
	doOtherWork()
end
```

## A complete application

`samples/UsingDotNet/applications/WebApi` is a to-do list with a web page and a JSON API. It tests itself by calling its own server with `HttpClient`:

{{source:samples/UsingDotNet/applications/WebApi/WebApi.ring}}

{{output:samples/UsingDotNet/applications/WebApi/WebApi.ring --selftest}}

## All of ASP.NET Core

The ASP.NET Core classes are wrapped too: `Microsoft.AspNetCore.*` (Http, Routing, Authentication, Authorization, Mvc, Builder, Hosting, StaticFiles...), `Microsoft.Extensions.*` (DependencyInjection, Configuration, Logging, Hosting, Caching...) and `Microsoft.Net.Http.Headers`. Class names that clash with other namespaces start with `Asp`. Extension methods (`AddSingleton`, `AddAuthentication`, `BuildServiceProvider`...) are methods of the classes that they extend ([Core concepts](concepts.html#extension-methods)).

```ring
using { "Microsoft.AspNetCore.Http" }

oPath = new PathString().@New([ :value = "/api/items" ])
? oPath.Value                                   # /api/items
? oPath.StartsWithSegments(new PathString().@New([ :value = "/api" ]))

oQuery = new QueryString().Create([ :name = "name", :value = "ring dotnet" ])
? oQuery.Value                                  # ?name=ring%20dotnet
```

## What is not supported

- MVC controllers and Razor pages **written in C#** — the web server is the Ring one.
- Handlers that run in parallel (there is one Ring thread).
- Calling Ring from middleware you wrote in .NET.

## Where to go next

- [Entity Framework Core](ef.html): the database side of a web program.
- The tutorial chapters [Networking and the web](tutorials.html#networking-and-the-web) and [Security](tutorials.html#security).
