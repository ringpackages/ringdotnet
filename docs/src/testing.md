---
title: Testing
lead: Every feature has a test, every sample and application tests itself, and your own programs can do the same.
---

## The test suite

```bash
sh samples/UsingDotNet/tests/run.sh B:/ring/bin/ring.exe
```

`samples/UsingDotNet/tests/run.sh` runs:

1. every `samples/UsingDotNet/tests/test_*.ring` (language bridge, collections, LINQ, system, IO, net, services, web, data, entity framework, keyboard, WPF...),
2. the console samples,
3. every Windows Forms and WPF sample with `--selftest`,
4. every application with `--selftest`,

and prints `0 failed` when everything passes. It needs the package `bin` folder on the PATH; the script adds it for you.

Programs run four at a time, and the windows of the programs that run themselves are invisible and not in the taskbar, so the whole run takes about three minutes and does not take over your screen. While you work, run the **quick tier**, which is only the tests and the console samples and takes about 25 seconds:

```bash
sh samples/UsingDotNet/tests/run.sh B:/ring/bin/ring.exe --quick
```

Options: `--jobs N` runs N programs at the same time (`--jobs 1` runs them one after the other, which is easier to read when something fails), and `--show` keeps the windows visible so you can watch them (or set the environment variable `RINGDOTNET_SHOW`). Run everything before a commit.

| Test file | Covers |
|---|---|
| `test_foundation.ring`, `test_runtime.ring` | the bridge: types, overloads, properties, enums, errors |
| `test_collections.ring`, `test_linq.ring` | typed collections, LINQ |
| `test_system.ring`, `test_io.ring`, `test_net.ring`, `test_services.ring` | the class library |
| `test_desktop.ring`, `test_keyboard.ring` | Windows Forms, key handling |
| `test_wpf.ring` | WPF |
| `test_web.ring` | ASP.NET Core server |
| `test_data*.ring` | Entity Framework: schema, relations, transactions, migrations, providers, queries, hooks, entities |
| `test_userassembly.ring` | your own assemblies |

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

Add three lines to a Windows Forms program and it becomes its own test: with `--selftest` it shows the form, runs the test code, closes the form and prints the result.

```ring
oForm = uiForm("Click counter",260,130)
...
uiTest(oForm,"selfTest()")          # runs selfTest() once the form is shown, when --selftest is used
uiRun(oForm)                        # shows the form; the form closes itself after the test
uiEnd()                             # prints SELFTEST OK, or the failures

func selfTest
	oForm.Controls.Item(1).PerformClick()
	dnAssert("one click",oCount.Text,"1 clicks")
```

```bash
ring main.ring               # the normal program
ring main.ring --selftest    # the test: prints SELFTEST OK
```

WPF programs use `wpfTest`, `wpfRun` and `wpfEnd`. `uiMessage()` prints instead of showing a dialog in a test, and `uiAsk()` answers yes unless `uiAnswer` says otherwise.

## Typing keys in tests

`uiSendKeys(oForm,"12{+}30{ENTER}")` types into the focused control of **your own form**. It posts window messages through the real Windows Forms key processing, so it behaves like a user and can never type into another program (which `SendKeys` could). Keys: `{LEFT} {RIGHT} {UP} {DOWN} {ENTER} {ESC} {BACKSPACE} {TAB} {DELETE}`, `{+}` for a plus sign.

## Testing the screenshots

The screenshots in this documentation are made by `docs/tools/shoot_all.sh`: it starts each sample, finds its window, captures it with `PrintWindow` and closes it.
