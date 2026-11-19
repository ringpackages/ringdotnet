---
title: "Tutorial 114: Rate limiting"
lead: A service that answers every request can be brought down by one client that asks too often. A rate limiter says yes or no to each request at once. This lesson uses a token bucket, a concurrency limiter with leases, statistics and the retry time, and keeps one limiter for each client.
---

## What you will learn

- why a service needs a **rate limiter**,
- the **token bucket**: a burst is allowed, the long-run pace is limited,
- the **concurrency limiter** and leases,
- `AttemptAcquire` and `IsAcquired`,
- statistics and the retry time,
- one limiter for each client.

A web program ([tutorial 16](tut-16-web-service.html)) uses limiters to answer *429 Too Many Requests*, a client that calls an API ([tutorial 84](tut-84-http-client.html)) uses one to stay below the limit of the server, and a program that sends mail uses one so that it is not marked as spam.

> [!NOTE] `System.Threading.RateLimiting` is part of the ASP.NET Core runtime, so the program has `"RingDotNet.Web"` in its `using { }` ([Getting started](getting-started.html)). The namespace has no generated Ring classes: the objects are made with `dnNew(type, [options])` and used with `callMethod` and `getProp` ([Core concepts](concepts.html)).

## The program

{{file:docs/tutorials/t114_rate_limiting.ring}}

{{output:docs/tutorials/t114_rate_limiting.ring}}

## How it works

### Yes or no at once

`AttemptAcquire(1)` asks for one **permit** and answers immediately with a **lease**; `IsAcquired` says whether the permit was given. The limiter never waits in this call: what a *no* means is the program's decision (an error to the client, a pause, a message). (`AcquireAsync` can wait in a queue; with `QueueLimit = 0`, as here, nothing waits.)

### The token bucket

The bucket holds up to `TokenLimit` tokens (3). Each request takes one. Tokens come back at a fixed pace: `TokensPerPeriod` tokens every `ReplenishmentPeriod`. So a client can make a **burst** — here 3 requests at once — and then only as many as the pace allows. This is the usual shape of real traffic, which is why the token bucket is the most common limiter. With `AutoReplenishment` on, a timer of the limiter adds the tokens; the program turns it **off** and calls `TryReplenish()` itself, so that the example does not depend on a timer. `TryReplenish` adds tokens only when the period has passed since the last time, which is why the program waits a little first. How many tokens come back depends on how long the pause was; the output states only what is always true.

### Statistics

`GetStatistics()` gives `CurrentAvailablePermits` (how many are left), `TotalSuccessfulLeases` and `TotalFailedLeases`. The totals show how much traffic was turned away: 4 granted and 2 refused here (the first three requests and the one after the pause were granted; requests 4 and 5 were refused). Show them on a status page and in the log.

### The concurrency limiter

It limits not the **rate** but how many requests are **in progress at the same time**: with a limit of 2, the third request is refused until one of the first two ends. A request keeps its **lease** while it works and gives it back with `Dispose()`; then the place is free again, and the next request is allowed. Use it for a slow shared resource: a database with 10 connections, a report that uses a lot of memory. Always dispose the lease in every path, including errors (`try` / `catch`, [tutorial 7](tut-07-errors.html)), or the places are lost one by one.

### The retry time

A refused lease can say **when to try again**: `TryGetMetadata("RETRY_AFTER")` answers `[ found, TimeSpan ]` ([tutorial 81](tut-81-network-tools.html)). A web server puts the seconds in the `Retry-After` header of the *429* response, and a well-made client waits that long and does not hammer the server.

### One limiter for each client

A single bucket for the whole service lets one noisy client use up the allowance of everybody. The program keeps a bucket **for each client** in a Ring list (the key is an address or a user id): the first client is refused after 2 requests while the second still has its allowance. In a real service the list is a dictionary, and old clients are removed so that it does not grow for ever ([tutorial 109](tut-109-memory-cache.html) shows a cache with expiration for this).

> [!WARNING] The limiter lives **inside the program**: two copies of a service have two separate buckets, so a client can make twice as many requests. For a limit that holds across servers, count in a shared store (a database or a cache server). And the address of a client behind a proxy is the address of the proxy ([tutorial 102](tut-102-ip-networks.html)).

## What you learned

- limiters answer yes or no at once with `AttemptAcquire`,
- a token bucket allows bursts and limits the pace,
- a concurrency limiter uses leases that must be disposed,
- statistics and the retry time,
- one limiter for each client.

## Exercises

1. Write `handleRequest(cClient)` that returns *200* or *429* and the retry seconds, using one bucket for each client name.
2. Use a `FixedWindowRateLimiter` (a window of 1 second, 5 permits) and make 10 requests with short pauses.
3. Combine a concurrency limiter with a token bucket: a request must pass both.
4. Print the statistics of every client after 100 random requests ([tutorial 69](tut-69-random.html)).

## Next

[Tutorial 115: Microsoft Access databases](tut-115-access.html)
