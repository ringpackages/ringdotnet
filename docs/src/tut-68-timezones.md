---
title: "Time zones"
lead: Two people in different cities cannot agree on "12 o'clock" without a zone. This lesson stores times in UTC, shows them in local time, handles daylight saving, and follows a flight across the ocean.
---

## What you will learn

- UTC and local time, and why you store UTC,
- `TimeZoneInfo` and converting between zones,
- the effect of **daylight saving time**,
- the duration of a flight, computed in UTC,
- the day that has 23 hours.

## The rule

> **Store and calculate in UTC. Convert to local time only when you show a time to a person.**

UTC (*coordinated universal time*) is the same everywhere and has no daylight saving. A local time is UTC plus an *offset* that depends on the place **and the date**: New York is UTC−5 in winter and UTC−4 in summer. If you keep local times in a database you cannot even tell which of two events came first.

## The program

{{file:samples/UsingDotNet/tutorials/t68_timezones.ring}}

{{output:samples/UsingDotNet/tutorials/t68_timezones.ring}}

## How it works

### Zones

`TimeZoneInfo.FindSystemTimeZoneById("Eastern Standard Time")` finds a zone by its identifier. On Windows the identifiers are names such as `Eastern Standard Time`, `GMT Standard Time`, `Egypt Standard Time` and `Tokyo Standard Time` (Linux and macOS use `America/New_York`). `ConvertTimeFromUtc(utc, zone)` gives the local time and `ConvertTimeToUtc([ :dateTime = local, :sourceTimeZone = zone ])` goes back. `GetUtcOffset(time)` tells the offset *at that moment*, so it includes daylight saving.

### Daylight saving

Steps 1 and 2 show the same UTC moment in July and in January. New York goes from −04:00 to −05:00, London from +01:00 to +00:00 and Cairo from +03:00 to +02:00 (Egypt has used daylight saving time again since 2023); Tokyo is always +09:00. The rules are different in each country and **they change**: Egypt did in 2023. That is why you must use the system's time zone data and never add or subtract hours yourself.

### The flight

The flight leaves Cairo at 22:30 *local* time and lasts 11 h 15 min. The program converts the departure to UTC (19:30), **adds the duration in UTC** (06:45 the next day) and converts the result to New York time (02:45). Never add a duration to a local time that can cross a daylight saving change.

### A day with 23 hours

On 10 March 2024 clocks in New York jump from 02:00 to 03:00. The time 02:30 **does not exist** (`IsInvalidTime` is true), and the day between two midnights has only 23 hours. In autumn the opposite happens: one hour exists twice (`IsAmbiguousTime`). Programs that schedule things at fixed local times must think about this.

> [!TIP] Meetings and alarms: store the **UTC time** plus the **zone id** of the person. Then you can show it correctly in every place and recalculate when the rules change.

## What you learned

- UTC for storing, local time for showing,
- `FindSystemTimeZoneById`, `ConvertTimeFromUtc`, `ConvertTimeToUtc`, `GetUtcOffset`,
- daylight saving rules differ and change,
- durations are added in UTC,
- invalid and ambiguous times.

## Exercises

1. Show the current time in four cities (`DateTime.UtcNow` and `ConvertTimeFromUtc`).
2. Find the hours of the day when offices in New York and Tokyo are both open (9–17).
3. Find a time that is *ambiguous* in New York in November 2024 (`IsAmbiguousTime`).
4. List all the zones with `TimeZoneInfo.GetSystemTimeZones` and print those with a +05:30 offset.

## Next

[Calendars and dates](tut-43-calendar.html)
