---
title: "Tutorial 103: Dates and times"
lead: Dates are full of traps — leap years, the end of the month, time zones, a "03/04" that means two different days. This lesson uses DateOnly, TimeOnly, DateTimeOffset and TimeSpan to make date calculations that do not break.
---

## What you will learn

- `DateOnly` and `TimeOnly`: say in the type that you have only a date, or only a time,
- `TimeSpan`: the length between two moments,
- `DateTimeOffset`: a moment together with its distance from UTC,
- what `AddMonths` and `AddYears` do at the end of a month,
- counting days and computing an age,
- reading a date with an exact format.

[Tutorial 3](tut-03-numbers-dates.html) made `DateTime` values and [tutorial 68](tut-68-timezones.html) converted between time zones. This lesson adds the types that make a program clearer and safer.

## The program

{{file:docs/tutorials/t103_dates_and_times.ring}}

{{output:docs/tutorials/t103_dates_and_times.ring}}

## How it works

### Date and time apart

A `DateTime` always has both a date and a time, so a birthday is *midnight on that day* and an opening hour is *that hour on 1 January of year 1*. Neither is true. `DateOnly` is a day (year, month, day) and `TimeOnly` a time of day, so the program cannot mix them up. `DateOnly` knows the `DayOfWeek` and the `DayOfYear` (the 28th of February is day 59) and `AddDays` goes over the end of the month and over a leap day. `TimeOnly.AddHours(3)` after 22:30 gives 01:30: a time of day goes round the clock and has no date to move to.

These structs have several constructors, so they are made by names (`dnNew("DateOnly",[ :year = 2024, :month = 2, :day = 28 ])`, the function `makeDate`). A method that formats with a pattern is `Format("yyyy-MM-dd")` (the plain `ToString()` has no parameters, see [Core concepts](concepts.html)).

### TimeSpan

Subtracting two `DateTime` values gives a `TimeSpan`: `Days`, `Hours` and `Minutes` are its *parts* (2 days, 9 hours and 30 minutes) while `TotalHours` and `TotalMinutes` are the *whole length* in one unit (57.5 hours, 3450 minutes). Mixing the two is a classic mistake: `Hours` never goes above 23. `TimeSpan.FromMinutes(135)` makes one from a number and prints as `02:15:00`.

### DateTimeOffset

`12:00` in Cairo (UTC+3) and `10:00` in London (UTC+1) in June are the **same moment**. A `DateTimeOffset` keeps the local time *and* the offset, so `Equals` knows they are equal and `UtcDateTime` gives 09:00 for both. Use it for anything that happens at a real moment — a log entry, an order, a meeting — and store it with its offset, or in UTC. A plain `DateTime` with no offset does not know which time zone it is in, and that is the source of many bugs ([tutorial 68](tut-68-timezones.html)).

### The end of the month

`AddMonths(1)` to 31 January cannot give 31 February, so .NET gives the **last day that exists**: 29 February in 2024. 31 March plus one month is 30 April. `AddYears(1)` to 29 February 2024 gives 28 February 2025. Remember it for a bill that is due *every month on the 31st*: adding one month to the *previous due date* drifts (31 Jan, 29 Feb, 29 Mar...); add *n months to the first date* instead.

### Ages and counts

An age is not the difference of the years: the birthday of this year may not have come yet. The program takes the difference of the years and then subtracts 1 if the birthday of this year is later than the day. `DayNumber` is the number of the day since 1 January of year 1, so the difference of two `DayNumber` values is the number of days between them (12 358 here).

### Reading a date

`03/04/2024` is the 3rd of April in Egypt and the 4th of March in the USA. When a program reads a date that a person typed, give the **exact format** (`TryParseExact` with `dd/MM/yyyy` and the invariant culture) instead of trusting the culture of the computer ([tutorial 33](tut-33-cultures.html)). `TryParseExact` answers `[ success, date ]`, and the wrong `31/04/2024` is refused because April has 30 days. The method is static, so it is called with `dnStatic(type, method, [arguments])`.

## What you learned

- `DateOnly` and `TimeOnly` make the meaning clear,
- `TimeSpan` parts against totals,
- `DateTimeOffset` is a real moment,
- `AddMonths` goes to the last day that exists,
- how to count an age,
- `TryParseExact` for dates that people type.

## Exercises

1. Write `lastDayOfMonth(year, month)` with `DateOnly` and `AddMonths`.
2. Print the next 6 due dates of a bill that is due on the 31st (add months to the first date).
3. Write `daysUntil(date)` that counts the days to the next birthday.
4. Show the same moment as a `DateTimeOffset` in three offsets.

## Next

[Tutorial 104: Text readers and writers](tut-104-text-readers-writers.html)
