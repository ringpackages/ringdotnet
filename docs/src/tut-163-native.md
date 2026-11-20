---
title: "Native DLLs"
lead: Windows has thousands of functions in DLLs such as kernel32 and user32, and many programs come with a DLL of their own. .NET calls them with P/Invoke. Ring does not declare them, but a small C# library does, and then Ring uses the functions like any other class. This lesson shows it with five functions of the Windows API.
---

## What you will learn

- what **P/Invoke** is and why the bridge cannot do it alone,
- how to write `[DllImport]` for a function, and how the types map,
- numbers, texts, buffers and structures that go to a native function,
- how to give the functions to Ring in four steps,
- what to do when the call fails.

## The problem

The bridge calls the members that .NET already has: a method of a class, a property, a constructor. A function of a native DLL is **not** a .NET member until C# declares it. The declaration is called **P/Invoke** (*platform invoke*): `[DllImport("kernel32.dll")]` before a method with the same name and the same parameters as the native function.

So the plan is the one of the tutorial [A library written in C#](tut-18-csharp-library.html): a few lines of C# declare the functions and give them public methods, the generator wraps that library, and Ring calls the methods.

> [!NOTE] This lesson uses the DLLs of Windows, so it runs on Windows only (the program says so on another system). Other systems have their own libraries (`libc`, `libm`) and the same idea works with their names.

## The steps

1. **Declare** the functions in C# with `[DllImport]` and give them public methods.
2. **Build** the library: `dotnet build Native -c Release -o Native/bin`.
3. **Wrap and load** it: `wrapassembly.ring`, `dnLoad`, `dnImportFrom`.
4. **Use** it: `new Win32()` and the methods.

## The C# library

It is in `samples/UsingDotNet/tutorials/Native`:

{{file:samples/UsingDotNet/tutorials/Native/Win32.cs}}

{{file:samples/UsingDotNet/tutorials/Native/Native.csproj}}

## The Ring program

{{file:samples/UsingDotNet/tutorials/ch13_native.ring}}

{{output:samples/UsingDotNet/tutorials/ch13_native.ring}}

## How it works

### Declaring a function

The documentation of a Windows function shows its C signature, for example `int MulDiv(int nNumber, int nNumerator, int nDenominator)` in `kernel32.dll`. The C# declaration repeats it with `static extern`. The names of the parameters do not matter, the **order and the types** do. Here the Windows types become C# types like this:

| In C (Windows) | In C# | In Ring |
|---|---|---|
| `int`, `DWORD`, `long` | `int`, `uint`, `int` | a number |
| `ULONGLONG`, `QWORD` | `ulong` | a number |
| `BOOL` | `bool` with `[return: MarshalAs(UnmanagedType.Bool)]` | 1 or 0 |
| `LPCWSTR` (a text that is only read) | `string`, with `CharSet = CharSet.Unicode` | a text |
| `LPWSTR` (a buffer that the function fills) | `StringBuilder` with a capacity | a text |
| a pointer to a structure | a `struct` with `[StructLayout]`, passed with `ref` | – |
| `HANDLE`, `HWND`, any pointer | `IntPtr` | not given to Ring (keep it inside C#) |

Windows has two versions of a function that takes a text: `GetEnvironmentVariableA` for old 8-bit text and `GetEnvironmentVariableW` for Unicode (*wide*). Name the **W** version and use `CharSet.Unicode`.

### What Ring sees

Ring never sees a pointer or a structure: the public methods of `Win32` take and return **numbers and texts**, and everything else stays in C#. That is the rule to follow for your own library too, because a method with simple types is the easiest to wrap and to call.

- `Scale(10,3,4)` passes three numbers and gets one.
- `UpperCase` shows a function that **changes** its text. Windows writes into the memory that it gets, so C# makes a copy in native memory (`Marshal.StringToHGlobalUni`), calls the function, reads the result back and frees the copy.
- `Variable` shows a **buffer**: the function writes the text into a `StringBuilder` that has room, and returns the length (0 when the variable does not exist).
- `MemoryMegabytes` shows a **structure**: the function fills a `MemoryStatus`, and C# has set its `Length` first, which that function requires. The documentation of every function that takes a structure says which field must be set.

### When the call fails

A native function reports an error with a return value: `0` or `false`. The details are kept by Windows, and `SetLastError = true` in `[DllImport]` tells .NET to remember them. `Marshal.GetLastWin32Error()` reads the number, and `new Win32Exception(number)` makes an exception with the text of Windows for it. `MemoryMegabytes` does this. Ring then catches it like every other .NET error (the tutorial [When things go wrong](tut-07-errors.html)).

### Some rules

- **Check the signature twice.** A wrong type does not give a message: a native function that gets the wrong kind of value may return nonsense, or stop the program. Copy the declaration from the documentation of the function ([pinvoke.net](https://www.pinvoke.net) has many).
- **The bit size matters.** A 64-bit program needs 64-bit DLLs, and `IntPtr` has the size of a pointer. Use `long` and `IntPtr` where the documentation says a handle or a size.
- **Free what you allocate.** Memory from `Marshal.AllocHGlobal` or `StringToHGlobalUni` is not managed: a `try ... finally` frees it, as `UpperCase` does.
- **Keep native things in C#.** A callback that native code makes (for example `EnumWindows`) must be a .NET delegate. Give it to the library, collect the answers there, and return a list or a text to Ring.

## What you learned

- a native function needs a C# declaration, `[DllImport]`, before Ring can use it,
- the public methods of the library use numbers and texts, and C# does the marshalling,
- buffers and structures are filled inside C#,
- `SetLastError` and `Win32Exception` bring the error of the system to Ring.

## Exercises

1. Declare `GetTickCount64` in `kernel32.dll` (it returns a `ulong`), give it a public method `UptimeSeconds()` and print how long the computer has been running.
2. Use `GetSystemMetrics(1)` to print the height of the screen, and `GetSystemMetrics(80)` for the number of monitors.
3. Declare `CharLowerW` the same way as `CharUpperW`, and write `SwapCase` in C# that uses both on one letter at a time.
4. Call `MulDiv` with 0 as the denominator. What does it return? Look the answer up in the documentation of the function.

## Next

[Testing your programs](tut-28-testing.html)
