---
title: "A small web site"
lead: Serve real HTML pages from Ring: a home page, an about page and a guestbook with a form. You will meet HTML forms, POST requests and the one security rule every web programmer must know.
---

## What you will learn

- serving HTML pages that share a frame,
- an HTML form and reading its fields,
- redirecting the work by status code (`400` for bad input),
- *cross-site scripting* and why you escape text,
- running the site for real.

## The site

| Address | Page |
|---|---|
| `GET /` | the home page |
| `GET /about` | an about page |
| `GET /guestbook` | the entries, and a form to add one |
| `POST /guestbook` | the form sends its fields here |

## The program

{{file:samples/UsingDotNet/tutorials/ch07_website.ring}}

{{output:samples/UsingDotNet/tutorials/ch07_website.ring}}

To run it as a real site:

```bash
ring ch07_website.ring --serve
```

then open `http://localhost:5090/` in a browser.

![The home page](img/shots/tut-g26-home.png "GET /")

![The guestbook after two entries](img/shots/tut-g26-guestbook.png "GET /guestbook")

> [!NOTE] This program uses a few generic functions (`dnNew`, `dnStatic`, `dnNewGeneric`, `callMethod`, `getProp`) where a class cannot be used. The lesson [The generic functions](tut-160-generic-calls.html) explains them.

## How it works

### One frame for all pages

The function `page(cTitle, cBody)` builds the whole HTML text: a title, a few lines of style, a navigation bar and the body. Every handler calls it, so every page looks the same and a change of design is made in one place. A handler returns a *text*; the server sends it as `text/html`.

### The form

```html
<form method='post' action='/guestbook'>
  <input name='name' placeholder='Your name'>
  <textarea name='message' ...></textarea>
  <button type='submit'>Send</button>
</form>
```

When the visitor presses **Send**, the browser sends a `POST` to `/guestbook` with the body `name=Ann&message=Hello+from+Ann` (spaces become `+`). In the handler, `oRequest.form("name")` returns the decoded field.

### Validation and status codes

If a field is empty the handler answers `[400, "text/html", page(...)]`: **400 Bad Request**, with a page that explains the problem. A browser shows the page; a program calling the site sees the status.

### Escaping: the one rule

> [!WARNING] **Never put text from a visitor into HTML as it is.** If a visitor writes `<script>steal()</script>` as a message and you paste it into the page, the script runs in the browser of everybody who opens the guestbook. This attack is called *cross-site scripting* (XSS). The function `htmlText` replaces `&`, `<` and `>` by `&amp;`, `&lt;` and `&gt;`, so the text is shown, not executed. Use it for **everything** that came from outside.

### State

`aEntries` is a global list: all visitors share it, and it disappears when the server stops. For lasting data use a database as in the tutorial [A web service with a database](tut-16-web-service.html).

### The test client

The program also acts as a visitor: it fetches pages and posts a form with `HttpClient`, using the same `serveOne` pattern as the tutorial [HTTP](tut-09-http.html). Posting a form needs the content type `application/x-www-form-urlencoded`; the client builds the content with named arguments: `dnNew("StringContent",[ :content = ..., :encoding = ..., :mediaType = ... ])`.

## What you learned

- pages are texts; a function can build the common frame,
- forms send fields by POST; `oRequest.form("name")` reads them,
- answer errors with the right status,
- always escape what visitors write.

## Exercises

1. Add a page `/stats` that shows the number of entries and the longest message.
2. Show the newest entry first.
3. Limit a message to 200 characters and refuse longer ones with a `400`.
4. Store the entries in a SQLite file with `RingDatabase`, so that they survive a restart.

## Next

[A tiny web framework](tut-55-miniweb.html)
