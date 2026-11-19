---
title: "Protecting data"
lead: Many programs hand a small piece of data to the outside and take it back later: a cookie, a "remember me" value, a link in an e-mail. The Data Protection API encrypts and signs such data for you, without keys to manage. This lesson protects and unprotects text, shows purposes, tampering and key folders, and makes tokens that expire.
---

## What you will learn

- what the **Data Protection API** does and when to use it,
- `Protect` and `Unprotect`,
- **purposes**: tokens for one use cannot be used for another,
- why a changed token is refused,
- keys in a folder, and what happens with other keys,
- time-limited tokens.

The tutorial [Hashing and encryption](tut-08-security.html) and the tutorial [Protecting and signing messages](tut-78-crypto.html) used the cryptography classes directly: you choose the algorithm, the key and the mode, and every choice is a chance for a mistake. The Data Protection API is the **high-level** tool: you give it a text, it gives you a token.

> [!NOTE] The API is part of the ASP.NET Core runtime, so the program has `"RingDotNet.Web"` in its `using { }` ([Getting started](getting-started.html)).

## The program

{{file:samples/UsingDotNet/tutorials/ch08_data_protection.ring}}

{{output:samples/UsingDotNet/tutorials/ch08_data_protection.ring}}

## How it works

### A provider and a protector

`DataProtectionProvider.Create(folder)` makes a provider whose **keys are kept in the folder** as files (it makes the first key itself and renews keys before they expire). `CreateProtector("purpose")` makes a protector for a purpose. `Protect(text)` returns a **token**: encrypted with AES and signed, so nobody can read it and nobody can change it. `Unprotect(token)` returns the text. `Protect` and `Unprotect` for texts are extension methods, so they are called with `dnStatic("...DataProtectionCommonExtensions","Protect",[protector,text])` (the tutorial [Caching](tut-109-memory-cache.html)); `CreateProtector` is a method of the provider object.

Every token of this API starts with `CfDJ8`, the Base64 text of a fixed header, and it does not show the data. A random value is part of each token, so protecting the same text twice gives two different tokens that both open to the same text.

### Purposes

A **purpose** is a text that names what the token is for (`"tutorial.cookies"`, `"tutorial.password-reset"`). A token made for one purpose cannot be opened by the protector of another purpose, even with the same keys. So a user who copies a cookie value into a reset link gets an error. Use a different purpose for every kind of token in your program, written like a namespace (`company.app.feature`).

### Tampering

Changing one character of a token makes `Unprotect` raise a cryptographic error (the signature does not fit). The program catches it with `try` and prints *refused*. You cannot make a *different valid* token without the key, so a token can carry data that the **user must not change**, for example the user id in a cookie. Remember what this does **not** protect against: a token can be **copied** and used again by someone who has it (a *replay*), so tokens that open a door (a reset link) should expire and be used once.

### Keys

The key folder is the secret. A second provider on the **same folder** opens the old tokens (after a restart, or from another copy of the program that shares the folder); a provider with **other keys** refuses them (step 5). That is what you want: protect the folder like a password, back it up, and share it between the servers that must open each other's tokens. In a real program choose a folder outside the project, with strict rights, and never put it in version control. Keys are **renewed** every 90 days by default and old keys stay available for opening old tokens.

### Time-limited tokens

`ToTimeLimitedDataProtector` makes a protector whose `Protect(text, lifetime)` adds an expiration time inside the token. Before the time the token opens; after it, `Unprotect` raises an error. Use it for password-reset links, e-mail confirmations and one-time codes. The check happens inside the token, so the server does not need to keep a list. These methods are in the `DataProtectionAdvancedExtensions` class.

> [!WARNING] This API is for data that **you** give out and take back. It is not a way to store passwords (use a slow password hash, the tutorial [Login, sessions and cookies](tut-49-login.html)) and not a replacement for the encryption of a database.

## What you learned

- `Protect` and `Unprotect` encrypt and sign small values,
- a purpose keeps uses apart,
- a changed token is refused,
- the key folder is the secret and can be shared,
- time-limited tokens expire by themselves.

## Exercises

1. Make a "remember me" cookie: protect the user id and the time, and write a function that reads it back or answers *not valid*.
2. Make a password-reset link that is valid for 15 minutes (the tutorial [A chat over TCP](tut-63-chat.html) shows a small server to send it from).
3. Look at the key file in the folder: it is XML. Which parts are readable and which are not?
4. Protect a long text (10 000 characters) and look at the size of the token.

## Next

[Login, sessions and cookies](tut-49-login.html)
