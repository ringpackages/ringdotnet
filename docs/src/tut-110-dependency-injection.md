---
title: "Dependency injection"
lead: A part of a program should ask for what it needs and not create it. A service container makes the objects and decides how long each one lives. This lesson uses the container of .NET with its three lifetimes — singleton, transient and scoped — and a service that needs another service.
---

## What you will learn

- what **dependency injection** (DI) is and why programs use it,
- `ServiceCollection` and the service provider,
- the three **lifetimes**: singleton, transient, scoped,
- scopes (`CreateScope`) and what *one request* means,
- factories that ask the provider for other services,
- the rules that avoid mistakes.

Every ASP.NET Core program is built on this container, so what you learn here is what a web program (the tutorial [A web service with a database](tut-16-web-service.html)) is using inside.

## The program

{{file:samples/UsingDotNet/tutorials/t110_dependency_injection.ring}}

{{output:samples/UsingDotNet/tutorials/t110_dependency_injection.ring}}

## How it works

### The idea

Without DI, a function that sends mail creates its own mail client, and a test of that function sends real mail. With DI, the function **asks** the container for a mail client; the program registers the real one, and a test registers a fake one. The code that *uses* a service does not know how it is made, and the code that *makes* it does not know who uses it.

The container is a `ServiceCollection` (the list of registrations); `BuildServiceProvider` turns it into a **provider** that makes the objects. A service is asked for with its type: `oProvider.GetService(type)`. The keys are .NET types, so in this lesson three ordinary types stand for three services: `ArrayList`, `Random` and `MemoryStream`. Ring classes cannot be registered (they are not .NET types), but a Ring function can be the **factory** that makes the object: `AddSingleton(serviceType, factory)` with `dnCallback("makeSingleton")`. `AddSingleton`, `AddTransient`, `AddScoped` and `BuildServiceProvider` are extension methods, so they are called with `dnStatic` (the tutorial [Caching](tut-109-memory-cache.html)).

### Singleton

**One object for the whole program**, made the first time somebody asks. Asked twice, the factory ran once and both answers are the *same object* (`Equals` of these types compares the object itself). Use it for things that are expensive to make or must be shared: a cache (the tutorial [Caching](tut-109-memory-cache.html)), a configuration (the tutorial [Configuration](tut-111-configuration.html)), a logger. A singleton must be safe for use by many threads at once.

### Transient

**A new object every time.** Asked twice, the factory ran twice and the objects are different. Use it for light things that must not share state.

### Scoped

**One object for each scope.** A *scope* is one unit of work: in a web server, one request. `CreateScope` makes one; the objects asked for **through the scope** are the same inside it and different in another scope. In the output the factory ran twice for two scopes, the same scope gives the same object and another scope gives another. When the scope is disposed, the scoped objects that need it are disposed too (files, connections). `CreateScope` is an extension method and the scope's provider is a plain object, so it is used with `callMethod("GetService",[type])`.

### Services that need services

A factory receives the provider as its first value, so it can ask for what it needs. The scoped `MemoryStream` of the program asks for the singleton `ArrayList` and writes the name of its scope in it; both scopes reach the **same** list, which then holds two entries. This is how a singleton shares data between requests — and why it must be safe for that.

### Rules of thumb

- A long-lived service must **not hold a shorter-lived one**. A singleton that keeps a scoped object keeps it for ever and shares it between requests ("captive dependency"); .NET can check this when the provider is built in development mode.
- Make the **simplest lifetime that works**: transient for light, stateless things, scoped for what belongs to one request, singleton only for what must be shared.
- Ask for services in **one place** (the start of the program or the request), and pass them down as values, instead of asking the container everywhere (that is the *service locator* style, which hides what a function needs).

## What you learned

- DI: a part asks for what it needs, a container makes it,
- `ServiceCollection`, `BuildServiceProvider`, `GetService`,
- singleton, transient and scoped lifetimes and scopes,
- Ring functions as factories,
- a factory can ask the provider for other services,
- the captive dependency mistake.

## Exercises

1. Register a fourth service and print how many times its factory ran for 10 requests (10 scopes).
2. Make a scope, get a scoped `MemoryStream` from it, write to it and dispose the scope.
3. Register the same type twice and see which one `GetService` returns (the last one).
4. Look up `GetServices` (many) and `GetRequiredService` (an error when missing) in the [class reference](api.html).

## Where to go next

This was the last tutorial of the chapter **Databases and services**. The next chapter is **Windows Forms**: it starts with [Your first window](tut-11-first-window.html). The [Tutorials](tutorials.html) page lists all the chapters, and you can start any of them.
