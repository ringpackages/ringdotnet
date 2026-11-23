---
title: Callbacks & events
lead: Run Ring code from .NET — as a delegate passed to a method, or as the handler of an event such as Click.
---

## Callbacks with dnCallback()

Pass `dnCallback(code)` wherever a .NET delegate is expected: `Action`, `Func`, `Predicate`, `Comparison`, `EventHandler`, `Task` continuations... The bridge builds a delegate of the **exact type**. When .NET invokes it, the Ring code runs, as with events in RingQt. It can read `aDotNetArgs` (the list of the delegate arguments) and set `xDotNetResult` (converted to the delegate's return type).

```ring
nTotal = 0
oList.@ForEach(dnCallback("nTotal += len(aDotNetArgs[1])"))                # ForEach is a Ring keyword: @ForEach
oList.Sort([ :comparison = dnCallback("xDotNetResult = len(aDotNetArgs[1]) - len(aDotNetArgs[2])") ])
oList.FindAll(dnCallback("xDotNetResult = left(aDotNetArgs[1],1) = 'a'"))
```

### A function name instead of code

If the text is just a **function name**, that function is called with the argument list as its only parameter, and its return value is the result:

```ring
oList.@ForEach(dnCallback("show"))

func show aArgs
	? aArgs[1]
```

### Good to know

- The code is compiled **once** into a function (`dncallbackN`); the same text reuses it, so a callback in a loop or timer costs nothing extra.
- An error raised by the Ring code reaches the .NET caller as an exception, and then your Ring `try` / `catch`.
- The Ring function can **return a .NET object** where the delegate returns one (a `Func<T>` that makes the objects of a container): `return dnNew("System.Text.StringBuilder",[])`. The code is Ring code, so the object is made the way every program makes it.
- Callbacks run **synchronously on the Ring thread during a call**. A callback fired later or from another thread (timers, tasks) is ignored with a message on stderr.

{{source:samples/UsingDotNet/introduction/test04_callbacks.ring}}

{{output:samples/UsingDotNet/introduction/test04_callbacks.ring}}

## Events

Every public .NET event gets two methods, as in RingQt: `setXXXEvent(code)` and `clearXXXEvent()`. The code runs when the event is raised and can read `aDotNetArgs`, which is `[sender, eventArgs]` (both .NET objects). Each event has one handler; setting it again replaces it.

```ring
using { "System.Collections.ObjectModel" }

oList = new ObservableStringList() {
	setCollectionChangedEvent("? 'changed: ' + aDotNetArgs[2].getProp('Action')")
	Add("one")
}
```

{{output:samples/UsingDotNet/introduction/test05_events.ring}}

### Click and friends

Windows Forms and WPF controls are events all the way down:

```ring
oButton = new Button() {
	Text = "Click me"
	setClickEvent("oForm.Text = 'Clicked!'")
}
oForm.Controls.Add(oButton)
```

The same event can be set with a function name, which is cleaner for longer handlers:

```ring
oButton.setClickEvent("clicked()")
...
func clicked
	nClicks++
	oCount.Text = "" + nClicks + " clicks"
```

> [!WARNING] The code of an event runs **outside** the function that set it up, so it can only see **global variables**. Create the widgets and the state of the program as globals at the top, then assign them inside `func main`. See [Rules and limits](rules-and-limits.html).

### Mouse and keyboard events

The event arguments are normal .NET objects:

```ring
oPicture.setMouseMoveEvent("? 'x=' + aDotNetArgs[2].X + ' y=' + aDotNetArgs[2].Y")
oForm.setKeyDownEvent("keyPressed(aDotNetArgs[2].KeyCode)")
```

{{source:samples/UsingDotNet/Forms/16_mouse_events.ring}}

![Mouse events](img/shots/forms-16_mouse_events.png "samples/UsingDotNet/Forms/16_mouse_events.ring")

### Timers

Timers raise `Tick` on the Ring thread (Windows Forms timers do; `System.Threading.Timer` runs on a pool thread and cannot call Ring):

```ring
oTimer = uiTimer(1000,"tick()")        # the helper: every 1000 ms
oTimer.Start()
```

## Calling Ring from .NET code you wrote

Your own assembly can call Ring as well: when a parameter is typed `object`, the bridge passes the callback unchanged and your code can call `RingDotNet.Bridge.CallRing(callback, returnType, args)`. This is how the Entity Framework hooks (`onSaving`, `onLog`) and value converters are built — see [Entity Framework reference](ef-reference.html#hooks).

## Where to go next

- [The .NET class library](foundation.html): the classes you will call most often (text, dates, files, processes).
- The tutorial chapter [Windows Forms](tutorials.html#windows-forms) is full of event handlers.
