---
title: "A tiny web framework"
lead: Real web frameworks map addresses like /users/ali to functions and fill templates with values. This lesson builds both ideas in a few dozen lines on top of WebServer.
---

## What you will learn

- routes with **parameters**: `/users/:name/posts/:id`,
- one *catch-all* handler (`notFound`) that decides with a router,
- a template with `{{name}}` places and automatic escaping,
- calling a function by its name (`call`),
- testing the whole thing in one program.

## The idea

`WebServer` maps a fixed address to a handler. A real site has addresses with changing parts: `/users/ali`, `/users/sara/posts/7`. Instead of one route for each user, a framework keeps a **pattern** (`/users/:name`) and, for each request, finds the pattern that fits and **extracts the parameters** (`name = ali`).

## The program

{{file:docs/tutorials/t56_miniweb.ring}}

{{output:docs/tutorials/t56_miniweb.ring}}

## How it works

### The router

`Router.add(method, pattern, handlerName)` stores the pattern split into parts. `find(method, path)` splits the real path too, and compares part by part: a part that starts with `:` matches anything and is saved as a parameter, any other part must be equal. A path with a different number of parts can never match. The result is `[handler, parameters]` — or an empty list.

### One handler for everything

`oServer.notFound("dispatch")` registers a handler for every request that has no ordinary route. Here that is every request, so `dispatch` is the only entry of the application: it asks the router, answers `404` when nothing fits, and otherwise calls the page function **by its name**: `call cHandler(oRequest,aParams)`.

### Pages and templates

A page function gets the request and the parameters and returns the answer of `render`. `render("<h1>User {{name}}</h1>", aParams)` replaces each `{{key}}` with its value — **escaped**: the fourth request of the output asks for the user `<b>sara`, and the page shows `&lt;b&gt;sara`. If the value were put into the page as it is, a visitor could write HTML or scripts into your site (the tutorial [A small web site](tut-26-website.html) and the tutorial [Login, sessions and cookies](tut-49-login.html) explain why this matters).

### Order in a Ring file

The `class Router` is at the end of the file. In Ring, functions written *after* a class belong to that class, so classes go last.

## What you learned

- patterns with `:parameters`,
- a router that finds the page and the values,
- `notFound` as the single entry point,
- templates with escaping,
- `call` for a function name.

## Exercises

1. Add a route `POST /users/:name` for a form, and look at `oRequest.form("field")`.
2. Support a `*` part that matches the rest of the path (`/files/*`).
3. Put the templates in files in a `views` folder and read them with `File.ReadAllText`.

## Next

[Route templates](tut-120-routes.html)
