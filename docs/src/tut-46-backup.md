---
title: "A project: a backup tool"
lead: Copy a folder into a zip file named by date, keep only the newest few, and restore the latest. Folders, zip, sorting and cleanup in one small program.
---

## What you will learn

- zipping and unzipping folders,
- names that sort in time order,
- keeping the newest *N* files (retention),
- restoring and verifying,
- the shape of a program that is safe to run again and again.

## The design

| Need | Decision |
|---|---|
| a backup must not overwrite the previous one | every backup has its own file: `backup-<date and time>.zip` |
| the files should be easy to find and to sort | the stamp is `year-month-day_hourminute`: sorting the *names* sorts by *time* |
| disk space is limited | keep only the newest *N* (here 3) and delete the older ones |
| a backup that was never restored is not a backup | the program **restores** the newest one and checks it |

## The program

{{file:docs/tutorials/t46_backup.ring}}

{{output:docs/tutorials/t46_backup.ring}}

## How it works

### Names that sort

`2024-05-03_0900` sorts correctly as *text* because the biggest unit comes first and every part has a fixed width (`05`, not `5`). That is why `sort(list of names)` puts the oldest backup first. A stamp like `3-5-2024` would sort wrongly. A real program makes the stamp from the clock: `new DateTime().Now.Format("yyyy-MM-dd_HHmm")`; the tutorial passes fixed stamps so that the output is repeatable.

### Making a backup

`ZipFile.CreateFromDirectory(folder, zipFile)` compresses the folder, with its subfolders, into a zip. It raises an error if the zip file already exists: another reason for a unique name.

### Retention

`keepNewest(folder, 3)` lists the backups oldest first and deletes all but the last three: the loop `for nIndex = 1 to len(aList) - nKeep` visits only the surplus ones. It returns how many it removed, so the caller can report it. Always **list first, then delete**: a bug here deletes data, so keep the logic small and test it on a demo folder, as this program does.

### Restoring

`ZipFile.ExtractToDirectory(zip, folder)` unzips into a folder (which must not exist yet). The program restores the newest backup and checks two facts: the report file has the *latest* text, and the number of files is the same as in the original. A real backup tool should do this check after every backup.

### A program that is safe to repeat

Run it twice and nothing breaks: new backups get new names, old ones are trimmed, the restore folder is new. Programs that run on a schedule must behave like this.

## What you learned

- zip with `ZipFile`,
- fixed-width date stamps sort as text,
- retention by deleting from the front of a sorted list,
- restore and verify.

## Exercises

1. Use the real clock for the stamp and run the program twice.
2. Skip a backup when no file changed since the last one (compare file dates or hashes: the tutorial [A project: find duplicate files](tut-31-duplicates.html)).
3. Put the list of folders to back up in a settings file (the tutorial [Settings](tut-32-settings.html)).
4. Add a window with a *Back up now* button and a list of the backups.

## Where to go next

This was the last tutorial of the chapter **Files and streams**. The next chapter is **Processes and performance**: it starts with [Asking the computer](tut-74-system.html). The [Tutorials](tutorials.html) page lists all the chapters, and you can start any of them.
