---
title: "Login, sessions and cookies"
lead: HTTP forgets who you are between requests. This lesson adds registration and login to a web site: safe passwords, a session cookie that the browser sends back, and a page that only logged-in users can see.
---

## What you will learn

- why web servers need sessions,
- storing users with salted password hashes,
- creating and checking a session token,
- reading and setting cookies,
- the right status codes: `401`, `409`, `400`,
- security details that matter.

## The problem

Every HTTP request stands alone: the server does not know that the request for `/profile` comes from the person who logged in a minute ago. The solution is a **session**:

1. the user logs in with a name and password,
2. the server creates a long random **token** and remembers `token → user`,
3. it sends the token to the browser in a **cookie** (`Set-Cookie`),
4. the browser sends the cookie back with every later request (`Cookie`),
5. the server finds the user by the token.

## The program

{{file:samples/UsingDotNet/tutorials/ch08_login.ring}}

{{output:samples/UsingDotNet/tutorials/ch08_login.ring}}

> [!NOTE] This program uses a few generic functions (`dnNew`, `dnStatic`, `dnNewGeneric`, `callMethod`, `getProp`) where a class cannot be used. The lesson [The generic functions](tut-160-generic-calls.html) explains them.

## How it works

### Registering

`registerUser` reads the form fields. It refuses a missing name or a short password with `400`, creates a random **salt**, and stores the name, the salt and a **hash** of the password (`PBKDF2`, the tutorial [Hashing and encryption](tut-08-security.html)) — never the password itself. The `unique` option of the name column makes the database refuse a duplicate, which the handler turns into `409 Conflict`.

### Logging in

`loginUser` looks up the name, hashes the typed password with **that user's salt** and compares it with the stored hash. If the name does not exist *or* the password is wrong, the answer is the **same**: `401 wrong name or password`. A different message would tell an attacker which user names exist.

When the login is right it creates a 16-byte token from `RandomNumberGenerator` (never from `Random`, which is predictable), stores `[token, user]` and sends the cookie:

```ring
oRequest.setHeader("Set-Cookie","session=" + cToken + "; HttpOnly; Path=/")
```

`HttpOnly` stops scripts in the page from reading the cookie; `Path=/` makes the browser send it to every page of the site.

### Using the session

For each later request the browser sends `Cookie: session=...`. `tokenOf` reads that header (`oRequest.header("Cookie")`), splits it on `;` and finds the part that starts with `session=`. `userOf` looks the token up in the list of sessions. `profilePage` answers `401 please log in` when there is no user, and the profile when there is.

### Logging out

`logoutUser` removes the session from the list and sends an *expired* cookie (`Max-Age=0`) so that the browser forgets it. The old cookie is now worthless: the last line of the output shows `Unauthorized` for the old token.

### The test client

A browser keeps cookies by itself. The test client does it manually: after a login it reads the `Set-Cookie` header of the response (`Headers.TryGetValues("Set-Cookie")`), keeps the part before the first `;`, and adds it as a `Cookie` header to later requests (`oMessage.Headers.Add("Cookie",cCookie)`).

## Security notes

| Do | Because |
|---|---|
| hash passwords with a salt and many rounds | a stolen database must not reveal passwords |
| long random tokens from `RandomNumberGenerator` | a guessable token is a stolen account |
| the same answer for a wrong name and a wrong password | do not reveal who has an account |
| `HttpOnly` cookies | scripts cannot steal them |
| use **HTTPS** (not shown here) and add `Secure` to the cookie | on plain HTTP the cookie travels readable |
| expire sessions after some time | a forgotten login should not live forever |
| escape text put into pages (the tutorial [A small web site](tut-26-website.html)) | otherwise a script can act as the user |

> [!WARNING] This is a teaching example. For a real site use the full features of ASP.NET Core (HTTPS, anti-forgery tokens, rate limiting of login attempts) and think carefully about threats before you store other people's data.

## What you learned

- sessions turn separate requests into a conversation,
- token → user, token in a cookie,
- store hashes, never passwords,
- `401` / `409` / `400`,
- the cookie header in both directions.

## Exercises

1. Add an expiry time to each session (a date) and refuse expired ones.
2. Limit failed logins: after five wrong passwords for a name, answer `429` for a minute.
3. Add a `/change-password` route that needs the old password.
4. Store the sessions in the database so that they survive a restart.

## Next

[Identities and claims](tut-95-claims.html)
