---
title: "Configuration"
lead: A program needs settings that are not in its code — a port, a name, a path, a database address. The configuration system of .NET reads them from several sources into one tree of keys, and later sources override earlier ones. This lesson reads a JSON file, adds values from memory and from the environment, and converts the values to numbers and yes/no.
---

## What you will learn

- the idea of **layered** configuration (the last source wins),
- keys as paths: `App:Port`,
- `ConfigurationBuilder` and the sources: JSON file, memory, environment variables,
- `GetValue` with a type and a default,
- sections (`GetSection`, `GetChildren`),
- where secrets belong.

The tutorial [Settings](tut-32-settings.html) saved the settings of a program in a file. This is the system that ASP.NET Core and most .NET programs use, and it works the same way for a web service and for a console tool.

> [!NOTE] The configuration providers (JSON, environment variables) are part of the ASP.NET Core runtime, so the program has the line `"RingDotNet.Web"` in its `using { }`: that starts the runtime with it ([Getting started](getting-started.html)).

## The program

{{file:samples/UsingDotNet/tutorials/t111_configuration.ring}}

{{output:samples/UsingDotNet/tutorials/t111_configuration.ring}}

## How it works

### Layers

A `ConfigurationBuilder` collects **sources**; `Build()` reads them and gives the configuration. The sources are added in order and **later sources override earlier ones**. So the usual setup is: the defaults in a JSON file that comes with the program, then the settings of one computer or one environment (testing or production), then environment variables, then the command line. The code that reads a value does not know or care which source gave it. Every source is added by an extension method, so each one is called with `dnStatic` (the tutorial [Caching](tut-109-memory-cache.html)): `AddJsonFile(builder, path)`, `AddInMemoryCollection(builder, dictionary)`, `AddEnvironmentVariables(builder, prefix)`.

### Keys

All the sources are turned into **one flat set of keys** with `:` between the levels: the JSON `{ "App": { "Port": 8080 } }` gives the key `App:Port`, and a list becomes numbered keys (`App:Features:0`, `App:Features:1`). A key that does not exist gives *null* (`isNull()` on the result), not an error. Keys are **not case sensitive**. The indexer is read with `callMethod("get_Item",[key])`.

### Types

Every value is a **text**. `ConfigurationBinder.GetValue(configuration, type, key)` converts it: `Int32` for the port (8080, which you can add 1 to), `Boolean` for the debug flag (`false` or `true`). With a fourth value the call gives a **default** when the key is missing (`Retries` is 3). A text that cannot be converted raises an error, so a typo in a settings file is found when the program reads it.

### Sections

`GetSection("Database")` is a part of the tree; its `Key` is the name (`Database`) and `GetChildren()` lists the values and sub-sections directly inside it, each with `Key` and `Value`. A section can be given to a part of the program that does not need to know the rest of the settings.

### Memory and environment

`AddInMemoryCollection` takes a `Dictionary<string,string>` and is the best source for **tests** and defaults: the program needs no file. After it, `App:Port` is 9090 (it was 8080 in the file), `App:Name` is unchanged, and the new key `App:Extra` exists. **Environment variables** are how servers and containers change settings without a new file. With a prefix (`RDN111_`) only the variables that start with it are read, the prefix is removed, and **`__` (two underscores) means `:`**, because `:` is not allowed in the name of an environment variable on every system. So `RDN111_Database__Host` changes `Database:Host`, while `Database:Timeout` still comes from the file.

> [!WARNING] A settings file that is kept with the code (in git, in a backup, on a shared disk) is **not** the place for passwords, keys and tokens. Read them from environment variables, from a secrets store or from a file outside the project, and never print the whole configuration in a log.

## What you learned

- configuration comes from layers, the last one wins,
- keys are paths with `:`, values are text,
- `AddJsonFile`, `AddInMemoryCollection` and `AddEnvironmentVariables`,
- `GetValue` with a type and a default,
- sections and children,
- secrets do not belong in the code.

## Exercises

1. Add a second JSON file with the name `settings.local.json` that overrides some keys, and add it after the first.
2. Print the whole tree (every key and value) with a recursive function that uses `GetChildren`.
3. Write `setting(cKey, xDefault)` that reads a value and keeps the default when the key is missing.
4. Read the command line (`AddCommandLine` with `sysargv`, the tutorial [A command-line tool](tut-50-cli.html)) as the last source.

## Next

[Caching](tut-109-memory-cache.html)
