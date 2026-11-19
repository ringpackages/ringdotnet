---
title: "Calendars and dates"
lead: Dates are harder than they look — months of different length, leap years, weekends. This lesson builds a text calendar, an age calculator and a business-day counter, using what .NET already knows.
---

## What you will learn

- `DaysInMonth`, `DayOfWeek`, `DayOfYear`,
- adding months and years safely,
- computing an age, business days and the next birthday,
- `Subtract` and `TimeSpan`.

## Why not do it yourself

Imagine adding one month to 31 January by hand. Is it 31 February? Does the answer depend on the year? `DateTime` knows all of this. The rule of this lesson: **let `DateTime` do the calendar arithmetic**; you only decide *what* to ask.

## The program

{{file:samples/UsingDotNet/tutorials/t43_calendar.ring}}

{{output:samples/UsingDotNet/tutorials/t43_calendar.ring}}

## How it works

### The month calendar

`DaysInMonth(year, month)` gives the number of days (29 for February 2024). `DayOfWeek` of the first day tells in which column it starts: the week starts on Monday, so the column number is the position of the weekday name in the list `Monday ... Sunday`, minus one. The program then prints the days with `right("  " + day,2)` so that the numbers line up, and starts a new line after the seventh column.

### Age

An age is *complete years, months and days*. The simple subtraction `year - birthYear` is wrong before the birthday. The method:

1. subtract years, months and days separately,
2. if the days are negative, borrow the length of the **previous month** and take one month away,
3. if the months are negative, borrow 12 months and take one year away.

On 2024-03-14 a person born on 1990-03-15 is `33 years, 11 months, 28 days` (28 because February 2024 has 29 days); one day later exactly `34 years`.

### Business days

A `while` loop visits every day from the start up to (not including) the end and counts the days that are not `Saturday` or `Sunday`. `CompareTo` is negative while the first date is earlier. Between 20 December 2024 and 6 January 2025 there are 17 days and 11 business days. (Holidays are not weekends: a real program has a list of holiday dates and skips those too.)

### The next birthday

Build this year's birthday; if it is already past (`CompareTo` negative), add one year. `Subtract(today).Days` is the number of days to wait.

### Safe additions

| Call | Result | Why |
|---|---|---|
| `AddMonths(1)` on 2024-01-31 | 2024-02-29 | February has no 31st: the last day is used |
| `AddYears(1)` on 2024-02-29 | 2025-02-28 | 2025 has no leap day |
| `AddDays(100)` | 2024-05-10 | days are simple |

Always use these methods, never `AddDays(30)` for a month.

### Day of the year

`DayOfYear` counts from 1 on 1 January: 25 December 2024 is day 360 (2024 is a leap year).

## What you learned

- let `DateTime` do the calendar work,
- ages need borrowing,
- business days need a loop and a weekday check,
- additions clamp to the end of the month.

## Exercises

1. Print the calendar of the *current* month (`DateTime.Now`) and mark today with `[ ]`.
2. Find the next Friday the 13th after today.
3. Add a list of holidays to `businessDays` and skip them.
4. Write `isLeapYear(year)` by your own rule and test it against `DateTime.IsLeapYear`.

## Next

[Other calendars](tut-76-calendars.html)
