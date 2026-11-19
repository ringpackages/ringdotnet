---
title: "A spell checker"
lead: How does a program know that "brwn" probably means "brown"? This lesson keeps a dictionary in a set, measures how different two words are with the edit distance, and suggests the closest words.
---

## What you will learn

- a **set** (`StringSet`) for fast "is it known?" questions,
- the **edit distance** (Levenshtein) and the table that computes it,
- sorting suggestions by distance and then by name,
- finding words with their positions in a text,
- why algorithms with tables ("dynamic programming") are worth knowing.

## The program

{{file:docs/tutorials/t66_spelling.ring}}

{{output:docs/tutorials/t66_spelling.ring}}

## How it works

### The set

A list answers "is this word in it?" by looking at the items one by one: ten times more words, ten times more work. A **set** (`StringSet`, a .NET `HashSet`) answers with `Contains` in about the same time however big it is. A real dictionary has hundreds of thousands of words, and a set is the right place for it (the tutorial [Collections and LINQ](tut-04-collections.html)).

### The edit distance

The **edit distance** between two words is the smallest number of single-letter changes — *insert*, *delete* or *replace* — that turn one into the other: `kitten → sitting` is 3 (`k→s`, `e→i`, add `g`). Words with a small distance are probably typing mistakes of each other.

The program computes it with a **table**. `aTable[i][j]` holds the distance between the first `i` letters of the first word and the first `j` letters of the second. The first row and column are easy (turning the empty word into `j` letters takes `j` insertions). Every other cell is the cheapest of three ways:

| From | Meaning | Cost |
|---|---|---|
| the cell above | delete a letter | +1 |
| the cell on the left | insert a letter | +1 |
| the cell diagonally | replace a letter | +0 if the letters are equal, else +1 |

The corner at the end is the answer. Each cell is computed from three neighbours that are already known, so the work is `length1 × length2` steps. This technique — fill a table so that nothing is computed twice — is the same idea as the cache in the tutorial [Speed — measure first](tut-53-speed.html).

### Suggestions

`suggest` gives every dictionary word a score (its distance to the typed word), sorts by score and then alphabetically (`strcmp`), and returns the first few. `brwn` has distance 1 to `brown` and 2 to `brain` and `crown`.

### Checking a text

`Regex.Matches("[A-Za-z]+")` finds the words and, for each one, its `Index`, so the program can say *where* the mistake is. It converts the word to lower case, asks the set, and only for unknown words does the (more expensive) search for suggestions. Do the cheap test first.

> [!NOTE] Plain edit distance counts a swap of two neighbour letters (`teh` for `the`) as 2 changes. The *Damerau* variant counts it as 1; it is a good exercise.

## What you learned

- a set for membership tests,
- edit distance and its table,
- ranking suggestions,
- cheap checks first.

## Exercises

1. Add the swap of neighbours (Damerau distance) and see `teh → the` become 1.
2. Read the dictionary from a text file with one word per line.
3. Print the checked text with `[brackets]` around the unknown words.
4. Suggest only words that start with the same letter, and measure how much faster it is (the tutorial [Speed — measure first](tut-53-speed.html)).

## Where to go next

This was the last tutorial of the chapter **Text and data formats**. The next chapter is **Numbers, dates and money**: it starts with [Number types](tut-101-number-types.html). The [Tutorials](tutorials.html) page lists all the chapters, and you can start any of them.
