---
title: "HttpClient in depth"
lead: Headers in both directions, status codes that are answers and not errors, EnsureSuccessStatusCode, cancelling a request, and saving a download to a file without holding it in memory. A small server in the same program makes it work without the internet.
---

## What you will learn

- one `HttpClient` for the whole program, and `DefaultRequestHeaders`,
- reading response headers and the content type,
- status codes: an answer of `404` is not an error,
- `EnsureSuccessStatusCode` when "not OK" must stop the program,
- cancelling a request that takes too long,
- saving a download with `CopyToAsync`.

The tutorial [A REST client](tut-39-rest-client.html) made a first REST client; the tutorial [HTTP](tut-09-http.html) explained HTTP. This lesson adds what you need for real services.

## The program

The service is a small `WebServer` that runs in the same program (the client code is the same for a real service; only the address differs).

{{file:samples/UsingDotNet/tutorials/ch07_http_client.ring}}

{{output:samples/UsingDotNet/tutorials/ch07_http_client.ring}}

## How it works

### One client

Create **one** `HttpClient` and use it for all requests: it keeps connections open and is meant to be shared. Creating a client for each request wastes connections. `DefaultRequestHeaders.Add("X-Client", …)` adds headers that go with **every** request (a user agent, an API key, `Accept`). The timeout of ten seconds protects the program from a server that never answers.

### Headers

Step 1 shows both directions. The request carried `X-Client`; the page read it with `oRequest.header("X-Client")`. The page set its own header with `oRequest.setHeader("X-Server","ring")`, and the client reads it with `oResponse.Headers.GetValues("X-Server")` (a header can have several values, so it gives a collection: `.toList()[1]` is the first). Headers about the *body* are on `oResponse.Content.Headers`: `ContentType` says what kind of data it is and in which encoding.

### Status codes

`oResponse.StatusCode` is a text (`OK`, `Created`, `NotFound`, `InternalServerError`), `ReasonPhrase` the standard words, and `IsSuccessStatusCode` is true for the 200s. A `404` is **an answer from the server**: the request worked, the thing is not there. Your program decides what that means.

### EnsureSuccessStatusCode

When *anything but success* means "stop", call `oResponse.EnsureSuccessStatusCode()`: it raises an `HttpRequestException` that says which code came, and your `try` / `catch` handles it in one place (the tutorial [When things go wrong](tut-07-errors.html)).

### Cancelling

A `CancellationTokenSource` (the tutorial [Tasks that wait](tut-83-tasks-waiting.html)) with `CancelAfter(300)` and its token in `GetAsync([ :requestUri = …, :cancellationToken = oSource.Token ])` cancels a request that is not finished after 300 ms. In the tutorial the `/slow` page is simply never served, so only the cancel can end it; the task ends *canceled* and `Wait` raises an error. This is how a window program offers a **Cancel** button: the click calls `oSource.Cancel()`.

> [!NOTE] The little server lives in this program and handles requests only while the program calls `serveOne`. The helper `fetchPage` keeps serving until its own request is finished, so it also serves requests of earlier, canceled calls. A real server runs elsewhere and does not need that.

### Saving a download

`oResponse.Content.CopyToAsync(oStream)` copies the body into a file stream in pieces; `Wait(NULL)` waits for it. A big file is never held in memory as a whole. Dispose the stream afterwards. For a really big download ask for the headers first (`HttpCompletionOption.ResponseHeadersRead`) so that the body is not buffered before you copy it.

## What you learned

- one shared `HttpClient`, default headers,
- request and response headers, `ContentType`,
- `StatusCode`, `ReasonPhrase`, `IsSuccessStatusCode`,
- `EnsureSuccessStatusCode`,
- cancelling with a token,
- `CopyToAsync` to a file.

## Exercises

1. Add a header `Authorization` with a fake token and let the server answer `401` when it is missing.
2. Download the file with `ResponseHeadersRead` and print the `ContentLength` from the headers before copying.
3. Send three requests together and wait with `WhenAll` (the tutorial [Tasks that wait](tut-83-tasks-waiting.html)).
4. Retry a request three times with a pause when the status is `503`.

## Next

[A REST client](tut-39-rest-client.html)
