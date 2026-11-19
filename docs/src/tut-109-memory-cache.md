---
title: "Caching"
lead: A cache keeps the result of slow work for a while, so the next request gets it at once. This lesson uses MemoryCache with absolute and sliding expiration, GetOrCreate with a Ring function that makes the value, and Remove and Clear — and says when a cache is the wrong tool.
---

## What you will learn

- what a cache is and when it helps,
- `MemoryCache`: `Set`, `TryGetValue`, `Remove`, `Clear`, `Count`,
- **absolute** and **sliding** expiration,
- `GetOrCreate`: make the value only when it is missing,
- extension methods and `dnStatic`,
- the rules that keep a cache safe.

The tutorial [Speed — measure first](tut-53-speed.html) measured how fast calls are. The fastest call is the one you do not make: a result that was already calculated, fetched or read can be reused.

## The program

{{file:samples/UsingDotNet/tutorials/ch09_memory_cache.ring}}

{{output:samples/UsingDotNet/tutorials/ch09_memory_cache.ring}}

## How it works

### The cache

`MemoryCache` (namespace `Microsoft.Extensions.Caching.Memory`) is a dictionary with rules. Each value has a **key** (a text such as `"user:1"`) and may have an expiration. `TryGetValue(key)` answers `[ found, value ]` (the tutorial [Network tools](tut-81-network-tools.html) explains the out value). A cache is made with options (`MemoryCacheOptions`), for example a size limit; the defaults are fine for this lesson.

### Extension methods

`Set(key, value)` and `GetOrCreate(key, factory)` are **extension methods** of the static class `CacheExtensions`, not methods of `MemoryCache` itself, so `oCache.Set(...)` raises *"Calling Method without definition"*. Extension methods are called as **static** methods with the object as the first value: `dnStatic("Microsoft.Extensions.Caching.Memory.CacheExtensions","Set",[oCache,key,value,options])`. The program wraps this in the function `cacheSet`. The same applies to many helpers of `Microsoft.Extensions.*` and to LINQ ([Collections & LINQ](collections-linq.html)). The class reference shows these classes: look for a static class with `Extensions` in its name.

### Absolute expiration

`AbsoluteExpirationRelativeToNow = TimeSpan` removes the value a fixed time after it was stored, even if it was used all the time. After 900 ms a value with a limit of 500 ms is gone. Use it when the value goes **stale**: a price list, a weather report, a result of a query that can change.

### Sliding expiration

`SlidingExpiration = TimeSpan` starts the time again every time the value is **read**. In step 3 the session is read every 300 ms and the limit is 1000 ms, so it stays; after 1500 ms without a read it is gone. Use it for things that should live while they are used: sessions, a cache of recent items. A value with only a sliding time can live for ever if it is always used, so combine it with an absolute limit (both can be set) when the data must be renewed.

### GetOrCreate

`GetOrCreate(key, factory)` says: *give me the value, and make it if it is missing*. The factory is the slow work. It is a Ring function that .NET calls during the call, made with `dnCallback("slowReport")`; it receives the arguments in a list and returns the value. For two requests the report is made **once**. (In a program with many threads two requests could both find the value missing and both make it; `MemoryCache` does not stop that, a cache that must make a value exactly once needs a lock.)

### Remove and Clear

When the real data changes (a record is updated in the database), remove its key (`Remove`), or the old value is served until it expires. `Clear` removes everything; `Compact(0.25)` removes a part. A change, then `Remove`, then the next read makes the fresh value: that is the usual pattern.

### When not to cache

A cache gives **old** data on purpose. Do not cache what must be exact (a bank balance, a stock count at the moment of an order), give every value an expiration so that the worst case is a value that is only a few seconds old, and watch the size: a cache without a limit that keeps a value for every user is a memory leak (the tutorial [Memory and the garbage collector](tut-98-memory.html)). Also remember that the cache lives *inside the program*: two copies of the program have two caches that can disagree.

## What you learned

- a cache is a dictionary with expiration rules,
- `Set` and `GetOrCreate` are extension methods, called with `dnStatic`,
- absolute expiration for stale data, sliding expiration for data in use,
- `GetOrCreate` with a Ring function as the factory,
- remove entries when the data changes, and know what not to cache.

## Exercises

1. Cache the result of a slow function (the tutorial [Speed — measure first](tut-53-speed.html)) and measure the time of the first and the second call.
2. Combine a sliding and an absolute expiration for a session.
3. Count how often `GetOrCreate` found the value (a *hit*) and how often it made it (a *miss*) and print the hit rate.
4. Set a size limit (`MemoryCacheOptions.SizeLimit`) and see what happens when entries are added without a size.

## Next

[Dependency injection](tut-110-dependency-injection.html)
