---
title: "International domain names"
lead: Domain names can contain letters of any alphabet — and that makes it possible to build a name that looks exactly like another one. This lesson converts names to and from Punycode with IdnMapping, shows what makes a name invalid, builds a look-alike of apple.com, and detects it by checking the alphabets of each part.
---

## What you will learn

- how names with Arabic, German, Chinese... letters travel as **Punycode** (`xn--`),
- `IdnMapping`: `GetAscii`, `GetUnicode`, `UseStd3AsciiRules`,
- `Uri.Host` and `Uri.IdnHost`,
- what makes a name invalid,
- **homograph attacks** with look-alike letters,
- a check of the **alphabets** in each part of a name.

The tutorial [URLs and encodings](tut-64-urls.html) took URLs apart and the tutorial [Unicode and encodings](tut-52-unicode.html) looked at Unicode text. This lesson is where the two meet — and where it becomes a security question.

## The program

{{file:docs/tutorials/t117_domain_names.ring}}

{{output:docs/tutorials/t117_domain_names.ring}}

## How it works

### Punycode

The system of domain names (DNS) was made for the letters `a` to `z`, the digits and the hyphen. A name with other letters is sent as **Punycode**: the text `xn--` and then the letters of the part encoded with ASCII characters only. `bücher.example` becomes `xn--bcher-kva.example` and the Arabic name becomes `xn--4gbrim.example`. Each part (label) of the name is converted alone, so `.example` stays as it is. `IdnMapping.GetAscii(name)` converts to Punycode, `GetUnicode(name)` converts back, and the round trip is exact. A name that is already plain ASCII does not change. A person sees the Unicode form; the network, the HTTP client and the certificate use the Punycode form.

### Uri

`new Uri("https://bücher.example/path")` keeps both: `Host` is the name as written and **`IdnHost`** is the ASCII form that goes to DNS. When you compare host names or look up a certificate for one, use `IdnHost`.

### Invalid names

A label is at most 63 characters, it must not be empty (`empty..label`), and it must not start or end with a hyphen. `GetAscii` raises an error for these, so the program uses `try` / `catch` (the tutorial [When things go wrong](tut-07-errors.html)) to answer *valid* or *not valid*. The default mapper allows a space; with `UseStd3AsciiRules = True` the mapper follows the strict rules (letters, digits and hyphens only) and refuses it. For names that come from a user, use the strict mapper.

### Look-alike letters

The Cyrillic letter `а` (U+0430) and the Latin letter `a` (U+0061) are **different letters that look the same** in almost every font. So `аpple.com` — written with the Cyrillic first letter — is a different name from `apple.com`, and a person cannot see the difference. An attacker who registers the look-alike can send mail and links that seem to come from the real company. This is a **homograph attack**. The Punycode form shows the truth at once: `xn--pple-43d.com` is obviously not `apple.com`. Other pairs exist: Latin `o` and Greek `ο`, Latin `l` and capital `I` in many fonts, the digit `0` and the letter `O`.

### Checking the alphabets

A defence that browsers use: a name is shown in Unicode only when each part uses **one alphabet**. The program gets the code of every letter (a text is converted to UTF-32, four bytes for a letter), decides from the range of the code which alphabet it belongs to (Latin 0041–024F, Greek 0370–03FF, Cyrillic 0400–04FF, Arabic 0600–06FF; a real program uses the Unicode *script* data), and reports a part that **mixes** alphabets. `аpple.com` mixes Cyrillic and Latin in one part, so it is suspicious; `bücher` is one alphabet; the Arabic name under `.example` is fine because each *part* is checked alone. The name to show to a person is the Unicode form when it is safe, otherwise the Punycode form.

> [!WARNING] This check is only a first step. A whole-script look-alike (every letter Cyrillic, such as an all-Cyrillic word that looks Latin) passes it. Real systems also use lists of confusable letters, the rules of the registry of the top-level domain, and a warning when a name is new or rare. When your program shows or compares a name that **a stranger chose** — a link in a message, a sender address, a download URL — show the Punycode form or warn the user.

## What you learned

- Punycode and `IdnMapping`,
- `Host` against `IdnHost`,
- the rules for valid names and the strict mapper,
- homograph attacks,
- checking the alphabets of each part.

## Exercises

1. Write `sameSite(a, b)` that compares two URLs by their `IdnHost`, ignoring case.
2. Add the Hebrew range (0590–05FF) and the Greek look-alike `ο` (U+03BF) to the check and test `gοogle.com`.
3. Write `safeLink(text, address)` that warns when the visible text and the real address have different hosts.
4. Read the e-mail address of a message (the tutorial [E-mail messages](tut-94-mail-messages.html)) and check the part after `@`.

## Next

[MIME types](tut-121-mime-types.html)
