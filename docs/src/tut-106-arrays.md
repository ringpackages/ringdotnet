---
title: "Arrays"
lead: A Ring list can hold anything and grow, but many .NET methods want an array — a fixed size and one type. This lesson shows how arrays come and go between Ring and .NET, and uses Array.Sort, Reverse, IndexOf, BinarySearch, Copy and Clear and an array with two dimensions.
---

## What you will learn

- how a .NET array differs from a Ring list,
- making a typed array (`List<T>.ToArray()`),
- `toList()` to read an array in Ring,
- the `Array` methods: `Sort`, `Reverse`, `IndexOf`, `BinarySearch`, `Copy`, `Clear`,
- zero-based positions,
- an array with two dimensions.

The tutorial [Collections and LINQ](tut-04-collections.html) used lists and dictionaries, the tutorial [Binary files](tut-45-binary.html) used arrays of bytes and the tutorial [More data structures](tut-92-data-structures.html) other collections. Arrays are the base of all of them.

## The program

{{file:samples/UsingDotNet/tutorials/ch04_arrays.ring}}

{{output:samples/UsingDotNet/tutorials/ch04_arrays.ring}}

> [!NOTE] This program uses a few generic functions (`dnStatic`, `dnNewGeneric`, `dnType`) where a class cannot be used. The lesson [The generic functions](tut-160-generic-calls.html) explains them.

## How it works

### Arrays and lists

A .NET **array** has a fixed length and **one type** (`int[]`, `string[]`, `double[]`), so it is compact and fast and an array of numbers never holds a text. A Ring list can change size and hold any mix. When a method wants an array and you pass a list, the bridge makes an array from the values (an `int[]` for whole numbers, a `string[]` for texts) **for that call only**. The array that the method sorts or changes is a *copy*: in step 1 the Ring list is unchanged after `Array.Sort`. To work on an array you must **have** the array, as a .NET object.

### Making an array

The easy way is a typed list: a `List<Int32>` (made with `dnNewGeneric`), the values added with `Add`, and `ToArray()`. The result is a plain object (`oInts`) with `Length`, `Rank` (the number of dimensions), `toList()` to copy it into a Ring list, and the static `Array` methods. `Array.CreateInstance(type, length)` makes an empty array, but its `SetValue(value, index)` takes an `object`, and a Ring number arrives as a double, which an `Int32` array refuses; use it for `Double` and `String` arrays, or fill an `Int32` array from a list as the program does.

### Array methods

They are static methods of the `Array` class. `Sort` and `Reverse` are called on `new Array()` like any static method; for the others the program uses `dnStatic("System.Array", method, [arguments])`. These names have several forms, so as methods of an object each would take one list of named values; `dnStatic` names the class and the method as texts and passes the values **in order**:

| Call | Does |
|---|---|
| `Sort(array)` | sorts the array in place (numbers by value, texts by the culture, the tutorial [Comparing text](tut-97-comparers.html)) |
| `Reverse(array)` | turns the order round |
| `IndexOf(array, value)` | the position of the first item that is equal, or **-1** |
| `BinarySearch(array, value)` | the position in a **sorted** array, very fast; for a missing value a negative number |
| `Copy(source, target, count)` | copies the first items into another array |
| `Clear(array, start, count)` | sets items to zero (or empty) |

**Positions are zero-based**: the first item of an array is at position 0, the first item of a Ring list at position 1. `IndexOf(19)` is 2 in the sorted array `3 7 19 25 42`, where Ring says 3. Keep this in mind whenever a number goes between Ring and .NET.

### BinarySearch

Looking at every item takes a long time in a big array. `BinarySearch` looks at the middle, decides which half can hold the value and repeats: a million items need about 20 steps. It **needs a sorted array**; in an unsorted one the answer is wrong without any error. For a value that is **not** there, the result is negative: it is the *bitwise complement* of the place where the value would go, so `-(result) - 1` gives the position for inserting it (20 would go at position 3). Test `>= 0` for "found".

### Two dimensions

`Array.CreateInstance(type, rows, columns)` makes a table; its `Rank` is 2 and `Length` is the number of items (12). `GetLength(0)` is the number of rows and `GetLength(1)` the number of columns; in Ring the method is `@GetLength(dimension)`, because the name clashes with the property `Length` ([Core concepts](concepts.html)). Items are written with `SetValue([ :value = v, :index1 = row, :index2 = column ])` and read with `GetValue([ :index1 = row, :index2 = column ])`. For a table of Ring numbers it is often simpler to use a Ring list of lists; use a 2D array when a .NET method wants one.

## What you learned

- an array has a fixed size and one type; a list given to .NET becomes an array copy,
- typed arrays from `List<T>.ToArray()` and back with `toList()`,
- `Sort`, `Reverse`, `IndexOf`, `BinarySearch`, `Copy`, `Clear`,
- positions start at 0,
- `BinarySearch` needs a sorted array and answers a negative number for "not found",
- two dimensions with `CreateInstance` and `@GetLength`.

## Exercises

1. Write `contains(oArray, value)` with `IndexOf`.
2. Fill an array with 100 000 random numbers (the tutorial [Randomness](tut-69-random.html)), sort it and compare `IndexOf` and `BinarySearch` with a `Stopwatch`.
3. Use `BinarySearch` to insert a value into a sorted list at the right place.
4. Fill a 9 x 9 `Double` array with the multiplication table and print it.

## Next

[Sets](tut-107-sets.html)
