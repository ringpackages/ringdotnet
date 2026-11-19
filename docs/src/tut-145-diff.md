---
title: "A project: compare two files"
lead: A diff shows what changed between two versions of a text: the lines to keep, delete and add. This project finds the longest common subsequence of the lines, builds the diff with it, prints only the changes with context, and measures how similar two files are.
---

## What you will learn

- the **longest common subsequence** (LCS) and how a table finds it,
- building a **diff** from the table: keep, delete (`-`), add (`+`),
- reading a text file as a list of lines (`ReadAllLines`),
- showing only the changes with **context** lines,
- a **similarity** in percent,
- what a moved line looks like in a diff.

Version control, code review and the *compare* command of an editor all show a diff. The method is a classic algorithm, written in plain Ring.

## The program

{{file:docs/tutorials/t145_diff.ring}}

{{output:docs/tutorials/t145_diff.ring}}

## How it works

### Keep, delete, add

To change the old file into the new one, each old line is either **kept**, or **deleted**, and some new lines are **added**. Many answers are possible (delete everything and add everything), so the diff looks for the one that keeps as many lines as possible. The lines that are kept form a list that is in both files in the same order: the **longest common subsequence**.

### The table

`lcsTable` makes a table in which cell `[i][j]` is the length of the LCS of the old lines from `i` on and the new lines from `j` on. It is filled from the end: when the two lines are the same, the cell is the cell diagonally after it plus 1; otherwise it is the larger of the cell below and the cell on the right. The cell `[1][1]` is the answer for the whole files: 6 here. The table has one cell for each pair of lines, so a file of 1,000 lines needs a million cells: real tools use better methods for big files, but the idea is the same.

### The diff

`makeDiff` walks from the top left corner. Two equal lines are kept and both positions move on. Otherwise the table says which way keeps more: when the cell below is at least as large as the cell on the right, the old line is deleted; else the new line is added. When one list ends, the rest of the other is deleted or added. The result is a list of `[mark, line]` pairs: a space, `-` or `+`. The change of `water: 200 ml` to `water: 250 ml` is a deletion and an addition, because a diff compares whole lines.

### Context

A long file has few changes, and a person wants to see only those. `withContext` keeps the changed lines and `nContext` lines around each one, and puts `...` for each run of lines that were left out. The program shows one line of context.

### Similarity

`2 * kept / (old lines + new lines)` is 100 percent for the same files and 0 for files with nothing in common. Here 6 kept lines of 7 and 8 give 80 percent.

### A moved line

When a line moves from the bottom to the top, the diff deletes it at one place and adds it at the other: a diff does not know about moves. The kept part is the longest part that stays in order, so the similarity is lower than a person would say.

> [!NOTE] The program compares lines with `=`, which is exact: upper and lower case differ, and so do spaces at the end of a line. Files with Windows and Unix line endings give the same lines, because `ReadAllLines` splits both. To ignore spaces at the ends, compare `trim(a)` with `trim(b)` and print the original lines.

## What you learned

- the longest common subsequence,
- a diff from the table,
- the changes with context,
- the similarity of two files.

## Exercises

1. Compare two real files and print only the changes with two lines of context.
2. Add the option *ignore case*: compare `lower(a)` with `lower(b)` but print the original lines.
3. Compare the *words* of two sentences instead of the lines.
4. Write the diff in the *unified* format, with `@@ -start,count +start,count @@` before each group.

## Next

[A project: check that files did not change](tut-147-checksums.html)
