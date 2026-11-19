---
title: "When things go wrong"
lead: Files go missing, text is not a number, networks fail. This lesson shows how .NET reports problems, how to catch them, and how to write programs that handle them calmly.
---

## What you will learn

- what an *exception* is and how Ring shows it,
- `try` / `catch` and reading the error text,
- asking first (`Exists`, `TryParse`) instead of catching,
- raising your own errors,
- cleaning up even when something fails.

## Exceptions

When .NET cannot do what you asked, it **throws an exception**: it stops the normal flow and reports the problem. In Ring a .NET exception is a Ring error. Without `try`, it ends your program with a message. With `try` ... `catch` you decide what happens.

```ring
try
	new Int32().Parse("abc")
catch
	? cCatchError
done
```

`cCatchError` holds the message. It starts with `DotNet Error:` followed by the *name of the exception* (`System.FormatException`) and an explanation. The name tells you the **kind** of problem.

## The program

{{file:docs/tutorials/t07_errors.ring}}

{{output:docs/tutorials/t07_errors.ring}}

## How it works

### 1. Catch the error

The first block shows the message: `System.FormatException: The input string 'abc' was not in a correct format.`

### 2. React to the kind of error

`substr(cCatchError,"FileNotFoundException") > 0` asks if the name appears in the text. Different problems get different answers: a missing file may be told to the user; a full disk may stop the program.

### 3. Ask first

Catching is for the unexpected. If you can *check* a condition, do that: `File.Exists(cName)` returns false instead of raising an error. It is shorter, faster and clearer.

### 4. TryParse

The same idea for numbers. `TryParse` returns `[worked, value]`; you decide.

### 5. Your own errors

`raise("text")` creates an error. Use it when *your* function is called with a request it cannot honour (`withdraw(100,250)`). The caller sees the text in `cCatchError`.

### 6. Clean up

Open files, connections and readers must be closed even when an error happens. The simple pattern: put the work in `try`, and do the cleanup *after* the `try` block. The program checks if the writer exists, closes it and deletes the file.

### More detail

While developing, set the environment variable `RINGDOTNET_TRACE=1` and the error text includes the .NET stack trace, which shows exactly where it happened.

## Good habits

| Do | Do not |
|---|---|
| check with `Exists`, `TryParse`, `IsNullOrWhiteSpace` first | wrap the whole program in one `try` |
| catch where you can *do* something about it | catch and ignore |
| show a friendly message, log the technical one | show `cCatchError` to end users |
| close what you open | leave files open |

## Exercises

1. Write `readNumber(cText)` that returns the number, or `-1` if the text is not a number, using `TryParse`.
2. Read a file that may not exist: print `missing` if it does not, the number of lines if it does. Do it twice: once with `Exists`, once with `try`.
3. Write `divide(a,b)` that raises `"Division by zero"` when `b` is 0, and catch it.
4. Cause a `DirectoryNotFoundException`: write a file into a folder that does not exist. Read the message.

## Next

[Hashing and encryption](tut-08-security.html)
