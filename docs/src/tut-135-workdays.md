---
title: "Working days"
lead: Business programs count days that are not weekends and not holidays, group dates into weeks and quarters, and compute ages. This lesson adds working days to a date, counts them between two dates, finds ISO week numbers and the end of a month, and computes an age.
---

## What you will learn

- `DayOfWeek` and a weekend that is kept in **one place**,
- adding **working days**: a loop over `AddDays(1)` that skips weekends and holidays,
- counting working days between two dates,
- **ISO week** numbers and why week 1 can start in December,
- quarters and `DaysInMonth` (with leap years),
- an **age**.

The tutorial [Dates and times](tut-103-dates-and-times.html) and the tutorial [Calendars and dates](tut-43-calendar.html) showed the date types and the calendar of a month. This lesson is about the rules that business programs add.

## The program

{{file:docs/tutorials/t135_workdays.ring}}

{{output:docs/tutorials/t135_workdays.ring}}

## How it works

### The weekend and the holidays

`DayOfWeek` gives the name of the day as a text. The function `isWeekend` compares it with `"Saturday"` and `"Sunday"`; some countries have a weekend on Friday and Saturday, and then only this function changes. The holidays are a Ring list of dates written as *year-month-day*, and `isHoliday` looks for the date in it. Real programs keep the holidays in a file or a table for each country and year (and some holidays, like Easter, move: they come from a rule, not from a fixed date).

### Adding working days

There is no formula that handles weekends *and* holidays, so `addWorkdays` does what a person does: it steps one day at a time and counts only the days that are working days. From a Thursday, 2 working days is the next Monday. The date itself does not count. Around 25 December 2030 (a Wednesday) the result jumps over the holidays and the weekend: 3 working days after the 24th is the 31st.

### Counting between two dates

`countWorkdays` walks from the first date up to, but not including, the second one, and counts the working days: that is a half-open range, the same rule as in most loops. The year 2030 has 261 weekdays and 3 holidays on weekdays, so 258 working days. (Walking day by day is fast enough for a few years; for a very long range count whole weeks first: each week has 5 working days.)

### ISO weeks

The ISO week starts on Monday, and **week 1 is the week with the first Thursday of the year**. So 1 January can belong to the last week of the year before (1 January 2027 is in week 53 of 2026) and the last days of December can belong to week 1 of the next year (30 December 2030 is in week 1 of 2031). That is why the function gives the week **and** the year of the week: `ISOWeek.GetWeekOfYear` and `ISOWeek.GetYear`. A report by week uses the pair, not the calendar year.

### Quarters and month ends

The quarter of a month is `floor((month - 1) / 3) + 1`. `DateTime.DaysInMonth(year, month)` knows the leap years (February 2032 has 29 days), so the last day of a month is the date with that day number; no program should have a table of month lengths.

### An age

The age is the difference of the years, minus one if the birthday of this year has not come. Someone born on 9 March 2000 is 30 on 9 March 2030, and someone born the next day is still 29. Subtracting the days and dividing by 365 is wrong: the leap days add up.

## What you learned

- the weekend and the holidays as data in one place,
- adding and counting working days,
- the ISO week and its year,
- quarters, month lengths and ages.

## Exercises

1. Write `previousWorkday(date)` and `nextWorkday(date)`.
2. Write `lastWorkdayOfMonth(year, month)`.
3. Add Easter Monday: compute Easter Sunday with the Gregorian algorithm and add one day.
4. Print a calendar for one ISO week: the seven dates and which are working days.

## Next

[Cultures](tut-33-cultures.html)
