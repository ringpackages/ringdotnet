---
title: "Tutorial 94: E-mail messages"
lead: Build an e-mail in a program — check addresses, set the sender and the recipients, write the subject and the body, and add an HTML version next to the text. This lesson only builds messages; nothing is sent, so it runs without a mail server.
---

## What you will learn

- `MailAddress`: reading `Name <user@host>` and using it as a check,
- `MailMessage`: sender, recipients (`To`, `CC`), subject, body,
- properties named like Ring words (`From`, `To`),
- `AlternateView`: the same message as text and as HTML,
- where sending would happen (`SmtpClient`) and why it is not in the lesson.

## The program

{{file:docs/tutorials/t94_mail_messages.ring}}

{{output:docs/tutorials/t94_mail_messages.ring}}

## How it works

### Addresses

`new MailAddress("Ann Lee <ann.lee@example.com>")` splits the text into `DisplayName`, `User`, `Host` and `Address`. A text that is not an address raises an error, so the function `isAddress` uses `try` / `catch` ([tutorial 7](tut-07-errors.html)) to turn the error into a yes or no. The check is about the **form** (`user@host`); it cannot know whether the mailbox exists. `bob@` and `@example.com` are refused, `bob@example.com` is accepted.

> [!NOTE] .NET is generous with display names: `bob example@x.com` is read as the name *bob* and the address `example@x.com`. If your program needs exactly one address in a text box, also compare `oAddress.Address` with the text.

### The message

`MailMessage` has the parts of a letter: `From`, `To`, `CC`, `Bcc`, `Subject` and `Body`. `To` and `CC` are collections (`MailAddressCollection`): `Add` takes an address text, with or without a display name, and `Count` and `toList()` read them back. `IsBodyHtml` says how the mail program should show `Body`; the default is plain text.

### Properties named like Ring words

`From` and `To` are words of the Ring language (`from` is used in `class X from Y`, `to` in `for i = 1 to 10`). Ring accepts them as the name of an attribute or a method **after a dot**, so `oMessage.From = ...` and `oMessage.To.Add(...)` work like any other property. Ring does not accept some other words there (`get`, `and`, `or`, `not`, `next`, `end`, `if`, `for`, `new`, `load`, `call`, `put`, `give`, `see`); a .NET method with such a name gets a `_` at the end (`Next_`), and a property with such a name is read with `getProp` and `setProp` ([Core concepts](concepts.html), *Plain objects*).

### Text and HTML together

A mail with HTML is shown badly by programs that only show text. The solution is two **alternate views** of the same message: the plain one and the HTML one; the receiving program shows the best one it can. `AlternateView` has no public constructor for a text, only a static method, `CreateAlternateViewFromString(text, encoding, mediaType)`, which is called with `dnStatic(type, method, [arguments])` (the encoding is `dnNull()` for the default).

### Sending

`SmtpClient` connects to a mail server and sends a message (`Send`). It needs a server name, a port, a user and a password, and real recipients, so it is not part of a lesson that must run anywhere. Notes for your own program: use port 587 with `EnableSsl = True`, never write the password in the source (read it from the environment or a settings file, [tutorial 32](tut-32-settings.html)), and check with a test server or a test account first. Microsoft recommends a library such as MailKit for new programs, because `SmtpClient` is limited.

## What you learned

- `MailAddress` splits and checks an address,
- `MailMessage` has sender, recipients, subject and body,
- `From` and `To` work as normal properties,
- alternate views give text and HTML in one mail,
- sending is a separate step that needs a server.

## Exercises

1. Write `addressList(cText)` that splits `a@x.com; b@y.com` into a list of `MailAddress` objects and skips the wrong ones.
2. Add a `Bcc` recipient and print all the recipients of the mail.
3. Add an attachment (`Attachments.Add`) made from a file of [tutorial 5](tut-05-files.html) and print its name.
4. Read about `MailMessage.Headers` and add the header `X-Mailer`.

## Next

[Tutorial 95: Identities and claims](tut-95-claims.html)
