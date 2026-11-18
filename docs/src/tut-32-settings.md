---
title: "Tutorial 32: Settings"
lead: Programs should remember how the user likes them. This lesson stores settings in a JSON file with defaults, handles a damaged file, and shows where programs keep such files.
---

## What you will learn

- the special folders of the user,
- defaults, loading and saving settings,
- a Ring class that hides the details,
- what to do when the file is missing or damaged.

## Where do settings live?

Windows has a folder for every kind of file; .NET finds them with `Environment.GetFolderPath`:

| Name | For |
|---|---|
| `MyDocuments` | files the user creates |
| `ApplicationData` | settings that follow the user to other computers |
| `LocalApplicationData` | settings and caches of this computer |
| `Desktop` | the desktop |

A program normally keeps its settings in a file *inside its own folder* under `ApplicationData`, for example `…\ApplicationData\MyProgram\settings.json`. The tutorial uses the temp folder so that it leaves nothing behind.

## The design

| Rule | Why |
|---|---|
| every setting has a **default** | the first run, and a missing key, work |
| the file is **JSON**, readable by people | users and support can read and edit it |
| loading **never fails the program** | a damaged file must not stop the application |
| saving happens when the user changes something | a crash does not lose the choices |

## The program

{{file:docs/tutorials/t32_settings.ring}}

{{output:docs/tutorials/t32_settings.ring}}

## How it works

### A class for settings

Everything about settings is in one Ring class, `Settings`, so the rest of the program only says `oSettings.getValue("name")` and `oSettings.setValue("fontSize",14)`. The class keeps a list of `[key, value]` pairs: its starting content *is* the list of **defaults**, so the keys that exist are defined in one place.

> [!NOTE] The method that reads the file is called `readFile`, not `load`: `load` is a Ring keyword and cannot be a name.

### Saving

`save` writes a JSON object by hand: texts in quotes, numbers without. For real data with arbitrary text use `JsonSerializer` ([tutorial 6](tut-06-json-xml.html)), which also escapes quotes and line breaks.

### Loading

`readFile` first checks that the file exists. Then, inside `try`, it parses the JSON and, for every **known** key, asks `TryGetProperty(key)`, which returns `[found, element]`: if found, the value replaces the default, read as a text (`GetString`) or a number (`GetInt32`) depending on the default. Keys that are in the file but unknown are ignored; keys missing from the file keep their default. That makes it safe to **add a new setting in a later version**.

### The damaged file

The program writes `this is not json {` to the file and creates a `Settings` object. The parse raises an error, the `catch` remembers it in `cLoadError`, and the defaults stay in place. A real program would also tell the user, or keep the bad file as `settings.json.bad` and start fresh.

## What you learned

- the user's special folders,
- defaults first, then the file on top,
- unknown and missing keys are fine,
- loading must never crash the program.

## Exercises

1. Move the file to `ApplicationData\TutorialApp\settings.json` (create the folder if needed with `Directory.CreateDirectory`).
2. Add a `recentFiles` setting that holds a list of up to five names.
3. Make `setValue` refuse an unknown key with an error.
4. Use the settings in a window: remember its position and size, and restore them when it opens ([tutorial 13](tut-13-editor.html)).

## Next

[Tutorial 33: Cultures](tut-33-cultures.html).
