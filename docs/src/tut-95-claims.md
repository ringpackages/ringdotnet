---
title: "Identities and claims"
lead: Programs that have users need a way to say who the user is and what the user may do. .NET describes a user with claims — small statements such as a name, an e-mail address and a role. This lesson builds an identity, finds claims, checks roles and writes a permission check.
---

## What you will learn

- a **claim**: a type and a value,
- `ClaimsIdentity` (claims from one source) and `ClaimsPrincipal` (the user),
- `FindFirst`, `FindAll` and `HasClaim`,
- roles and `IsInRole`,
- a permission check where the rules are data.

ASP.NET Core uses exactly these classes for every login, so what you learn here is what a web program (the tutorial [A web service with a database](tut-16-web-service.html)) receives after the user signed in. The tutorial [Login, sessions and cookies](tut-49-login.html) made a login with a password hash; this lesson is about what happens *after* the login.

## The program

{{file:samples/UsingDotNet/tutorials/ch08_claims.ring}}

{{output:samples/UsingDotNet/tutorials/ch08_claims.ring}}

> [!NOTE] This program uses a generic function (`dnNew`) where a class cannot be used. The lesson [The generic functions](tut-160-generic-calls.html) explains them.

## How it works

### Claims, identities, principals

A **claim** is one statement about a user: `Name = Ann`, `Email = ann@example.com`, `Role = Editor`. The type is just a text; .NET has standard names (`ClaimTypes.Email` is a long address-like text) but your own short names work in your own program. A user can have several claims of the same type, like the two roles here.

An **identity** is a list of claims that came from one source (a password login, a certificate, a token) together with the name of that source (`AuthenticationType`). A **principal** is the user as the program sees them, and can hold several identities. `IsAuthenticated` is true when the identity has an authentication type.

The constructors have several forms, so an identity is made with named values: `new ClaimsIdentity().@New([ :authenticationType = "Password" ])`.

### Finding claims

`FindFirst(type)` returns the first claim of that type (or null), `FindAll(type)` all of them as a collection (`toList()` gives a Ring list), and `HasClaim` answers yes or no. `HasClaim` has two forms, so it takes a list of names: `[ :type = "Role", :value = "Editor" ]`.

### Roles

`IsInRole("Editor")` looks for a claim of the **role type** of the identity. The default role type is a long standard name, so an identity that uses its own type must say which one it is (`:roleType = "Role"`); the same goes for the type that `Name` reads (`:nameType = "Name"`). That is the usual reason for the question *"why does IsInRole say no?"*.

### Rules as data

Step 4 keeps *what a role may do* in a Ring list (`:Editor = ["read", "write"]`, ...) and the function `mayDo` asks: does any role of the user allow this action? The user has the roles Editor and Reviewer, so `read`, `write` and `comment` are allowed and `delete` is not. Rules in a list can be changed, saved (the tutorial [Settings](tut-32-settings.html)) and tested without changing the code, and this is the same idea as the *policies* of ASP.NET.

> [!WARNING] A claim is only as trustworthy as its source. Claims that come from the user (a form field, a cookie that is not signed) prove nothing. Build the identity on the server, from your own database, after you checked the password (the tutorial [Login, sessions and cookies](tut-49-login.html)) — and check the permission on the server for every action, not only by hiding a button.

## What you learned

- claims, identities and principals,
- `FindFirst`, `FindAll`, `HasClaim` and `IsInRole`,
- `roleType` and `nameType`,
- a permission check driven by a list of rules.

## Exercises

1. Add the claim `Department = Sales` and write a rule that allows `delete` only for the Sales department.
2. Make `hasAllRoles(oPrincipal, aRoles)`.
3. Serialize the claims of a user to JSON (the tutorial [JSON as a tree](tut-80-json-nodes.html)) and build the identity again from the JSON.
4. Make an identity with no authentication type and look at `IsAuthenticated`.

## Next

[Rate limiting](tut-114-rate-limiting.html)
