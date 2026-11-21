---
title: Collections & LINQ
lead: Typed .NET collections with Ring syntax, indexers, copying to Ring lists, and LINQ queries over Ring lists or any .NET collection.
---

## Typed collections

The common closed generic collections have ready-made classes (`using { "System.Collections.Generic" }`):

| Class | .NET type |
|---|---|
| `StringList`, `NumberList`, `ObjectList` | `List<string>`, `List<double>`, `List<object>` |
| `StringDictionary`, `NumberDictionary`, `ObjectDictionary` | `Dictionary<string, T>` |
| `StringSet` | `HashSet<string>` |
| `StringQueue`, `StringStack` | `Queue<string>`, `Stack<string>` |

```ring
using { "System.Collections.Generic" }

oList = new StringList()
oList.Add("banana") oList.Add("apple") oList.Add("cherry")
oList.Sort(NULL)
? oList.Count
for cItem in oList.toList()            # toList() copies the collection to a Ring list
	? cItem
next

oDict = new StringDictionary()
oDict.SetItem("two","2")               # indexers: Item(index) and SetItem(index, value)
? oDict.Item("two")
aResult = oDict.TryGetValue("three")   # out parameters come back as a list
? aResult[1]                           # 0
```

{{source:samples/UsingDotNet/introduction/test03_collections.ring}}

{{output:samples/UsingDotNet/introduction/test03_collections.ring}}

> [!TIP] To add your own closed generic type, add a line to the `:types` list of its namespace in `tools/dotnettools/dotnetmanifest.ring` and run the generator ([Class generator](generator.html#closed-generic-types) shows the line). Without a class, `dnNewGeneric(...)` gives you the object and `callMethod` works on it.

## Other collection classes

`System.Collections`, `System.Collections.Specialized`, `System.Collections.Concurrent` and `System.Collections.ObjectModel` are wrapped completely: `ArrayList`, `Hashtable`, `SortedList`, `Stack`, `Queue`, `BitArray`, `NameValueCollection`, `ObservableCollection` and so on.

{{source:samples/UsingDotNet/introduction/test10_collections.ring}}

{{output:samples/UsingDotNet/introduction/test10_collections.ring}}

## Sorting and searching with Ring code

Methods that take a delegate (`Predicate`, `Comparison`, `Action`) accept `dnCallback(...)`. The Ring code reads `aDotNetArgs` and sets `xDotNetResult`:

```ring
oList.FindAll(dnCallback("xDotNetResult = left(aDotNetArgs[1],1) = 'a'"))
oList.Sort([ :comparison = dnCallback("xDotNetResult = len(aDotNetArgs[1]) - len(aDotNetArgs[2])") ])
oList.@ForEach(dnCallback("? aDotNetArgs[1]"))
```

See [Callbacks & events](callbacks-events.html).

## LINQ

`using { "System.Linq" }` loads `Enumerable` and a fluent wrapper, `dnQuery(...)`, that works on a **Ring list or any .NET collection**. The lambda is Ring code: it reads `aDotNetArgs[1]` and writes `xDotNetResult`.

```ring
using { "System.Linq" }

aSales = [120, 45, 300, 15, 210, 99, 81]

aTop = dnQuery(aSales).Where("xDotNetResult = aDotNetArgs[1] >= 100").OrderByDescending("xDotNetResult = aDotNetArgs[1]").Take(3).ToList()

? dnQuery(aSales).Count()
? dnQuery(aSales).Sum("")
? dnQuery(aSales).Average("")
? dnQuery(aSales).Max("")
```

{{source:samples/UsingDotNet/introduction/test11_linq.ring}}

{{output:samples/UsingDotNet/introduction/test11_linq.ring}}

### The dnQuery methods

| Group | Methods |
|---|---|
| Filtering and projection | `Where(code)`, `Select(code)`, `SelectMany(code)`, `TakeWhile(code)`, `SkipWhile(code)` |
| Ordering | `OrderBy(code)`, `OrderByDescending(code)`, `ThenBy(code)`, `ThenByDescending(code)`, `Reverse()` |
| Paging | `Take(n)`, `Skip(n)`, `Distinct()` |
| Sets | `Concat(other)`, `Union(other)`, `Intersect(other)`, `Except(other)` |
| Results | `ToList()`, `Count()`, `CountWhere(code)`, `First()`, `FirstWhere(code)`, `Last()`, `ElementAt(n)` |
| Tests | `Any(code)`, `All(code)`, `Contains(value)` |
| Aggregates | `Sum(code)`, `Average(code)`, `Min(code)`, `Max(code)` — an empty `""` means the value itself |

> [!NOTE] The generic LINQ methods of `Enumerable` also work directly: the bridge infers the type arguments from the values you pass, and callbacks become `Func<object, ...>` delegates.

## Where to go next

- [Callbacks & events](callbacks-events.html): the code you pass to `Where`, `Select` and the other LINQ methods is a callback.
- The tutorial chapter [Collections and algorithms](tutorials.html#collections-and-algorithms).
