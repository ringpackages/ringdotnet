---
title: "Other calendars"
lead: A date is one moment, but people write it in different calendars. .NET knows the Hijri (Umm al-Qura), Persian, Hebrew, Japanese and Thai Buddhist calendars. This lesson reads one day in each, converts a Hijri date back, and prints dates in Arabic.
---

## What you will learn

- the `Calendar` classes of `System.Globalization`,
- reading a `DateTime` in another calendar (`GetYear`, `GetMonth`, `GetDayOfMonth`),
- converting a date of another calendar to a `DateTime` (`ToDateTime`),
- month lengths and why Ramadan moves through the year,
- month and day names in the language of a culture (`ar-SA`).

## One moment, many calendars

A .NET `DateTime` always stores a **Gregorian** date. A **calendar object** is a translator: you give it the `DateTime` and ask for the year, month and day *as that calendar counts them*. The classes you need are `UmAlQuraCalendar` (the Hijri calendar used in Saudi Arabia), `HijriCalendar`, `PersianCalendar`, `HebrewCalendar`, `JapaneseCalendar`, `ThaiBuddhistCalendar` and `GregorianCalendar`. All are in the namespace `System.Globalization`, so the program starts with `using { "System", "System.Globalization" }`.

## The program

{{file:samples/UsingDotNet/tutorials/ch03_calendars.ring}}

{{output:samples/UsingDotNet/tutorials/ch03_calendars.ring}}

## How it works

### Reading a date

Every calendar has the same three methods, so one helper (`dateText`) works for all of them. 11 March 2024 is **1 Ramadan 1445** in the Umm al-Qura calendar, 21 Esfand 1402 in the Persian calendar, and the year 2567 in the Thai Buddhist calendar. The Japanese calendar counts years within an *era*: 2024 is year 6 of Reiwa.

### Going back

`calendar.ToDateTime(year, month, day, hour, minute, second, millisecond)` builds the `DateTime` from a date in that calendar: `oHijri.ToDateTime([ :year = 1445, :month = 9, :day = 1, :hour = 0, :minute = 0, :second = 0, :millisecond = 0 ])` is 2024-03-11. Step 3 uses it to print the start of each Hijri month: the lengths come from `GetDaysInMonth([ :year = 1445, :month = nMonth ])` and are 29 or 30 days.

> [!NOTE] A calendar method with several forms is one Ring method that takes one value or a list of named values: `GetDaysInMonth([ :year = 1445, :month = 9 ])`. `ToDateTime` takes seven values here.

### Why Ramadan moves

The Hijri year has 354 or 355 days, about eleven days fewer than the Gregorian year. Step 5 lists the first day of Ramadan for five years: 11 March 2024, 1 March 2025, 18 February 2026... it moves about eleven days earlier each year and goes round the whole Gregorian year in about 33 years.

### Names in the language of a culture

A `CultureInfo("ar-SA")` has Arabic names *and* uses the Umm al-Qura calendar by default. `oDate.Format([ :format = "dddd, d MMMM yyyy", :provider = oArabic ])` prints the weekday, day, month and year of the *culture's own calendar*: «الاثنين, 1 رمضان 1445». With `en-US` the same date prints as «Monday, 11 March 2024». The format letters come from the tutorial [Numbers, dates and times](tut-03-numbers-dates.html) and the cultures from the tutorial [Cultures](tut-33-cultures.html).

### Leap years

`GregorianCalendar.IsLeapYear` follows the rule *every 4 years, except every 100, except every 400*: 2024 and 2000 are leap years, 2100 is not.

> [!WARNING] The Umm al-Qura calendar is only defined for a range of years (about 1318–1500 Hijri, that is 1900–2077). Outside the range a calendar method raises an error. Catch it with `try` / `catch` (the tutorial [When things go wrong](tut-07-errors.html)). Real moon sighting can also differ from the tables by a day.

## What you learned

- calendars are translators of a `DateTime`,
- `GetYear`, `GetMonth`, `GetDayOfMonth`, `GetDaysInMonth`, `ToDateTime`,
- Arabic names and calendars with `CultureInfo("ar-SA")`,
- how a calendar year differs from the Gregorian one.

## Exercises

1. Print today's date in the Hijri and the Persian calendar.
2. Find how many days are left until the next 1 Ramadan.
3. Use `PersianCalendar` to list the months of the current Persian year with their lengths.
4. Show a date with `Format` in `fa-IR` and `he-IL`.

## Next

[Working days](tut-135-workdays.html)
