---
title: "Route templates"
lead: A web program decides what to do from the path of the address. A route template describes such a path with named parts — users/{id}/orders/{orderId?} — and the routing classes of ASP.NET Core match paths against it and read the values. This lesson uses them with required, optional, default and catch-all parts, and chooses between several routes.
---

## What you will learn

- the syntax of a **route template**,
- required parts, optional parts (`?`), default values (`=`), catch-all parts (`*`),
- `TemplateParser` and `TemplateMatcher`,
- reading the **values** of the parts,
- why the **order** of routes matters,
- what a template does *not* do.

The tutorial [A web service with a database](tut-16-web-service.html) and the tutorial [A tiny web framework](tut-55-miniweb.html) made small web servers with simple routes. Real programs have many routes with parts that change (`/users/42`, `/users/43`). Templates are the standard way to write them, and the same classes work in your own Ring program.

> [!NOTE] The routing classes are part of the ASP.NET Core runtime, so the program has `"RingDotNet.Web"` in its `using { }` ([Getting started](getting-started.html)).

## The program

{{file:samples/UsingDotNet/tutorials/ch07_routes.ring}}

{{output:samples/UsingDotNet/tutorials/ch07_routes.ring}}

## How it works

### The syntax

A template is a path whose parts are either **literal text** (`users`, `orders`: matched without regard to case) or **parameters** in braces:

| Written | Meaning |
|---|---|
| `{id}` | required: one part of the path |
| `{orderId?}` | **optional**: it may be missing at the end |
| `{page=1}` | has a **default value**: it may be missing at the end, and then the value is `1` |
| `{*path}` | **catch-all**: everything that is left, with its slashes |
| `{id:int}` | has a **constraint** (here: a whole number) |

`TemplateParser.Parse(text)` reads a template into an object whose `Parameters` list each part with its `Name`, `IsOptional`, `IsCatchAll` and `DefaultValue` (a text, or the null object when there is no default). Step 1 prints them. The template `items/{id:int}` keeps the constraint as part of the parameter (`InlineConstraints`); **a matcher does not apply constraints**: the router that uses the template checks them afterwards (the program would test that `id` is a number before it uses it).

### Matching

`TemplateMatcher` is made from the template and a dictionary of **defaults**. `TryMatch(path, values)` answers *yes* or *no* and fills `values` (a `RouteValueDictionary`) with the part names and their values. The path is a `PathString` and must start with `/`. In step 2: `/users/42/orders/7` matches with `id = 42` and `orderId = 7`; `/users/42/orders` matches because `orderId` is optional (and gets no value); `/users/42` does **not** match this template, because the literal part `orders` is missing; `/users/42/orders/7/extra` does not match because there is a part too many; and the capital letters in `/USERS/5/ORDERS/9` do not matter.

Defaults are important for `{page=1}`: the matcher needs them in its dictionary, so the program copies the defaults of the parameters into one (`oDefaults`). With that, `/products/shoes` matches with `page = 1`, and `/products/shoes/3` with `page = 3`. The values come back as text, even for numbers; convert them (`number()`) and check them.

### The catch-all

`{*path}` takes **all the rest**, including the slashes: `/files/docs/guide/intro.md` gives `path = docs/guide/intro.md`. It is used for files, proxies and single-page applications. Because it takes everything, the program that uses it **must check the value** (no `..`, no absolute path) before it opens a file (the tutorial [Paths and the environment](tut-59-paths.html)).

### Many routes

A program has a list of routes and uses the **first one that matches**, as in step 4. So the order is part of the program: put the most specific routes first and the general ones last. `/users/42` goes to `users/{id}`, `/users/42/orders/7` to the route with orders, and `/about` to `{page}`. Notice `/users`: it does not fit `users/{id}` (the id is missing), so it falls through to `{page}` and shows a page called *users*. A route `users` listed before `{page}` makes the choice explicit. When no route matches, the answer is *404 Not Found*.

### What a template does not do

A template describes the **path**. It does not read the query string (`?page=2`, the tutorial [URLs and encodings](tut-64-urls.html)), the method (GET or POST), the headers or the body. A program matches the path first, then looks at the method and the rest. ASP.NET also uses the templates the other way round, to **make** addresses from values (`TemplateBinder`), so a link is never written by hand.

## What you learned

- templates with literal and parameter parts,
- optional (`?`), default (`=`) and catch-all (`*`) parameters,
- `TemplateParser`, `TemplateMatcher` and `RouteValueDictionary`,
- values are text and must be checked,
- the first matching route wins, so the order matters.

## Exercises

1. Make the table of routes for a small shop (`/`, `/products`, `/products/{id}`, `/cart`, `/checkout`) and test ten paths.
2. Add a check to the `{id:int}` route: refuse the match when the value is not a number.
3. Put the routes in the web server of the tutorial [A tiny web framework](tut-55-miniweb.html) and answer 404 when none matches.
4. Write `isSafePath(value)` for a catch-all `{*path}` and test `../secret.txt`.

## Next

[A project: a link shortener](tut-150-shortener.html)
