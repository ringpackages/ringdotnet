---
title: "A project: rename many files"
lead: A tool that renames hundreds of files must not make a mistake. This project makes the new names with rules (replace, regular expression, lower case, numbering), shows a preview, refuses when two files would get the same name, renames, and keeps a log so that everything can be undone.
---

## What you will learn

- a **rule** as data and one function that applies a list of rules,
- splitting a name from its **extension**,
- a **preview** before any change,
- **conflict** checks: the same new name for two files, an empty name,
- `File.Move` to rename, and a **log** that makes **undo** possible,
- why the folder order of files must be sorted,
- a project made of small functions that a test can call.

The tutorial [A project: a backup tool](tut-46-backup.html) did something to files that is easy to repeat. Renaming is different: a wrong rule damages the names, so the tool works in careful steps.

## The program

{{file:samples/UsingDotNet/tutorials/ch05_renamer.ring}}

{{output:samples/UsingDotNet/tutorials/ch05_renamer.ring}}

## How it works

### The four steps

The program lists the names, makes the new names with a rule, **shows them without renaming anything** (the preview), checks the plan for problems, and only then renames. Each step is a function: `fileNames`, `makePlan`, `findConflicts` and `applyPlan`. The plan is a Ring list of `[old, new]` pairs, so it can be printed, checked, saved and undone.

### Rules are data

A rule is a small list: `[ "replace", " ", "_" ]`, `[ "regex", "\s*final", "" ]`, `[ "lower" ]` or `[ "number", "holiday-", "jpg", 2 ]`. A rule set is a list of rules that are applied in order to each name, so *replace the spaces and write lower case* is two rules. `applyRule` does one rule and `makePlan` loops over the names and the rules. A new kind of rule is a new `but` branch in one function, and a window with a menu of rules can build the same lists.

### Name and extension

`splitName` finds the **last** dot and splits there, so `report final.txt` is `report final` and `txt`, and a name without a dot has no extension. Most rules change only the name part; the rule `lower` changes the extension too (`JPG` becomes `jpg`) and `number` sets the extension it was given. The program puts the dot back when the extension is not empty.

### Regular expressions

`Regex.Replace(text, pattern, replacement)` is called with `dnStatic`. The pattern `\s*final` means *any spaces and then the word final*, so `report final.txt` becomes `report.txt` and no space is left behind (the tutorial [Regular expressions in depth](tut-29-regex.html)).

### Numbering

The rule `number` ignores the old name: it makes `holiday-01`, `holiday-02`... with a counter that is kept in `makePlan`, and the width (2) pads the number with zeros so that the names sort correctly. The program selects the files that have the word *holiday* first and makes a plan for those only.

### Conflicts

Two files cannot have one name. Step 5 uses a rule that turns `report final (copy).TXT` and `report final.txt` into the same name, and `findConflicts` reports it. **Nothing is renamed when there is a problem**: a tool that stops in the middle of a rename leaves a mess that is hard to repair. The check compares names in lower case, because Windows and macOS do not tell `A.txt` from `a.txt`.

### Rename and undo

`File.Move([ :sourceFileName = ..., :destFileName = ... ])` renames a file. `applyPlan` skips the files whose name does not change and returns the **log**: the pairs that were really renamed. `undoLog` goes through the log from the last pair to the first and moves each file back. The test at the end compares the names with the first list: they are the same. A real tool saves the log in a file, so the user can undo even after the program was closed.

> [!NOTE] The order of the files that `GetFiles` returns is not defined, so `fileNames` sorts the list. Without it the preview would change from one computer to another and the numbering would not be the same.

## What you learned

- rules as data and a function that applies them,
- the preview, the conflict check and the log,
- renaming with `File.Move`, and undo,
- sorting the names of a folder.

## Exercises

1. Add the rule `extension` that changes only the extension.
2. Add a rule that puts the date of the file (`LastWriteTime`) in front of the name.
3. Save the log as a text file and write `undoFromFile(path)`.
4. Add a *dry run* switch that prints the plan and does not call `applyPlan`.

## Next

[A project: compare two files](tut-145-diff.html)
