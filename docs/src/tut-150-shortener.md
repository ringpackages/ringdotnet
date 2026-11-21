---
title: "A project: a link shortener"
lead: A link shortener turns a long address into a short code and sends visitors to the long address. This project is a web service that makes codes from a counter, answers with a 302 redirect and a Location header, counts the visits, and refuses addresses that are not http or https.
---

## What you will learn

- a web service with `POST /shorten`, `GET /stats` and a **catch-all** handler (`notFound`),
- **base 62** codes made from a counter,
- the **redirect**: status `302 Found` and the header `Location`,
- a client that does **not** follow redirects, so a test can see them,
- answering **400** and **404**,
- why a redirecting service must check where it redirects.

The tutorial [A web service with a database](tut-16-web-service.html) and the tutorial [Route templates](tut-120-routes.html) made services and routes. This project is a small complete one.

## The program

{{file:samples/UsingDotNet/tutorials/ch07_shortener.ring}}

{{output:samples/UsingDotNet/tutorials/ch07_shortener.ring}}

> [!NOTE] This program uses a few generic functions (`dnNew`, `dnStatic`) where a class cannot be used. The lesson [The generic functions](tut-160-generic-calls.html) explains them.

## How it works

### The routes

`onPost("/shorten", "shorten")` makes a short link, `onGet("/stats", "statsOverview")` lists the visits, and `notFound("visit")` handles every other path: the text after the first `/` is a code. The handler of an unknown path is the way to make a service whose addresses are *data*, not a fixed list. (The status names in the output, `Created`, `Found`, `NotFound` and `BadRequest`, are the names of the status codes 201, 302, 404 and 400.)

### Codes

`toCode` writes a number in **base 62** with the digits `0-9`, `a-z` and `A-Z`: 62 symbols that are safe in a URL and short. The counter starts at 1000, so the codes have at least two characters, and three characters are enough for 238,000 links. A code from a counter is predictable: anybody can guess the next one. For links that must be private use random codes (the tutorial [Randomness](tut-69-random.html)) and check that the code is not used.

### One address, one code

`shorten` first looks for the address in the list: the same address gets the same code and the answer `200` (*already known*), and a new one gets `201 Created`. The list is `[code, address, visits]` in memory; a real service stores it in a database (the tutorial [Entity objects and migrations](tut-27-entities.html)).

### The redirect

A redirect is an answer, not a page: the status `302 Found` and the header `Location` with the new address. The handler calls `oRequest.setHeader("Location", address)` and returns `[302, "text/plain", ""]`. A browser then goes to the address by itself. The client of the test is made with `AllowAutoRedirect = False`; the default client would follow the redirect and fetch the long address, which is not what the test wants to see. `visit` also counts the visit.

### Errors

An unknown code is `404`. A missing field or an address that is not valid is `400 Bad Request`. The function `isAllowed` uses `Uri.TryCreate(text, "Absolute")`, which answers `[success, uri]`, and accepts only the schemes `http` and `https`.

### Why check the address

A shortener that redirects to **any** text is dangerous. `javascript:alert(1)` is an address too, and a link or a redirect to it can run a script in some contexts. Another problem is a short, innocent-looking code that leads to a harmful site. A real service checks the scheme (as here), and often the destination too, and it never redirects to an address that a request takes from the *address bar of another visitor* without checking it (an *open redirect*).

> [!NOTE] The service runs on the Ring thread, and the test calls `serveOne` between sending a request and reading the answer. A real service calls `run()` and serves until it is stopped.

## What you learned

- a service with a catch-all handler,
- base 62 codes,
- the 302 redirect and the `Location` header,
- testing redirects with a client that does not follow them,
- checking the address before redirecting.

## Exercises

1. Add `GET /stats/CODE` that shows the visits of one link as JSON (`webJson`).
2. Let the caller choose the code (`code=docs`), and refuse a code that is already used.
3. Add the time of the last visit and show it in the statistics.
4. Make the codes random and check that a code was not used before.

## Next

[E-mail messages](tut-94-mail-messages.html)
