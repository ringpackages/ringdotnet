---
title: Testing
lead: Every feature has a test, every sample and application tests itself, and your own programs can do the same.
---

## The test suite

```bash
sh samples/UsingDotNet/tests/run.sh ring.exe
```

`samples/UsingDotNet/tests/run.sh` runs:

1. every `samples/UsingDotNet/tests/test_*.ring` (language bridge, collections, LINQ, system, IO, net, services, web, data, entity framework, keyboard, WPF, your own assemblies...),
2. the console samples,
3. every tutorial program (the ones with a window test themselves with `--selftest`, the others just have to run without an error),
4. every Windows Forms and WPF sample with `--selftest`,
5. every application with `--selftest`,

and prints `0 failed` when everything passes. It needs the package `bin` folder on the PATH; the script adds it for you.

Programs run four at a time, and the windows of the programs that run themselves are invisible and not in the taskbar, so the whole run takes about four minutes and does not take over your screen. The tutorials about packages run `dotnet publish`: they need the .NET SDK and, the first time, the internet to get the packages; they run one at a time, because several builds together fail. A tutorial that makes errors on purpose says `# errors on purpose` on its first lines, and then only an error that was not caught fails it. While you work, run the **quick tier**, which is only the tests and the console samples and takes about 25 seconds:

```bash
sh samples/UsingDotNet/tests/run.sh ring.exe --quick
```

Options: `--jobs N` runs N programs at the same time (`--jobs 1` runs them one after the other, which is easier to read when something fails), and `--show` keeps the windows visible so you can watch them (or set the environment variable `RINGDOTNET_SHOW`). Run everything before a commit.

| Test file | Covers |
|---|---|
| `test_foundation.ring`, `test_runtime.ring`, `test_after_error.ring` | the bridge: types, overloads, properties, enums, errors, a call after a caught error |
| `test_collections.ring`, `test_linq.ring` | typed collections, LINQ |
| `test_system.ring`, `test_io.ring`, `test_net.ring`, `test_services.ring` | the class library |
| `test_access.ring` | Microsoft Access through ODBC (`System.Data.Odbc`): makes an `.accdb` file with ADOX, tables, parameters, NULL, Unicode, transactions. Windows with the 64-bit Access Database Engine only; it prints `SKIPPED` and passes anywhere else |
| `test_desktop.ring`, `test_keyboard.ring` | Windows Forms, key handling |
| `test_wpf.ring` | WPF |
| `test_web.ring` | ASP.NET Core server |
| `test_data*.ring` | Entity Framework: schema, relations, transactions, migrations, providers, queries, hooks, entities |
| `test_userassembly.ring` | your own assemblies: generated classes, interfaces, explicit implementations, extension methods, enum parameters, renamed classes |
| `test_import_folder.ring`, `test_classindex.ring`, `test_interface_members.ring` | loading generated classes from a folder, the class index, interfaces that inherit members |
| `test_native_call.ring`, `test_handles.ring`, `test_overload_choice.ring`, `test_named.ring`, `test_guard.ring` | the native call path, the release of handles, the choice of an overload, named arguments, the managed pointers |

## dnAssert

```ring
load "dotnet.ring"

dnAssert("max",new Math().Max(3,9),9)
dnAssert("name",oForm.Text,"Hello")
dnTestSummary()
```

```output
TESTS: 2 passed, 0 failed
```

A failing assertion prints `FAIL: name expected <9> got <3>` and counts a failure. `dnTestSummary()` returns the number of failures.

## Programs that test themselves

The checks of a window program are kept in a file of their own, so the program stays as short as the lesson that shows it. The program is the usual one:

```ring
oForm = uiForm("Click counter",260,130)
...
uiRun(oForm)
```

and next to it, in the folder `selftest`, the file with the same name (`selftest/main.ring`) holds the checks:

```ring
func selfTest
	oForm.Controls.Item(1).PerformClick()
	dnAssert("one click",oCount.Text,"1 clicks")
```

```bash
ring main.ring               # the normal program
ring main.ring --selftest    # the test: prints SELFTEST OK
```

With `--selftest`, `uiRun` loads that file, shows the form, runs `selfTest()` once the form is shown, closes the form and prints the result. The form must be in the global variable `oForm` (WPF: `oWindow`, with `wpfRun`). A program without a `selftest` file runs normally; the functions `uiTest(oForm, code)` and `uiEnd()` (`wpfTest`, `wpfEnd`) do the same steps by hand for a program that keeps its checks inside. `uiMessage()` prints instead of showing a dialog in a test, and `uiAsk()` answers yes unless `uiAnswer` says otherwise.

## Typing keys in tests

`uiSendKeys(oForm,"12{+}30{ENTER}")` types into the focused control of **your own form**. It posts window messages through the real Windows Forms key processing, so it behaves like a user and can never type into another program (which `SendKeys` could). Keys: `{LEFT} {RIGHT} {UP} {DOWN} {ENTER} {ESC} {BACKSPACE} {TAB} {DELETE}`, `{+}` for a plus sign.

## Testing the screenshots

The screenshots in this documentation are made by `docs/tools/shoot_all.sh`: it starts each sample, finds its window, captures it with `PrintWindow` and closes it.

## Where to go next

- [Rules and limits](gotchas.html): the points to know before a long program.
- The tutorial chapter [Libraries, testing and release](tutorials.html#libraries-testing-and-release) shows tests in a real project.
