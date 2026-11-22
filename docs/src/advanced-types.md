---
title: Advanced .NET types
lead: Generic types and methods, nested types, operators, spans, ref structs, pointers and asynchronous streams — the parts of .NET that are not plain classes with plain methods.
---

The [core concepts](concepts.html) cover classes, methods, properties, enums and errors. This page is for the types that need a little more: each section says what Ring gives and what it gets back. Most programs never need them; they are here for the libraries that do (a serializer with `Deserialize<T>`, a date library with operators, a byte-level API with `Span<T>`).

## Generic types

A generic type also has a Ring class: the class of its definition (`List`, `Dictionary`, `HashSet`, `SortedSet`...). Its objects are made with the type arguments in the named list, together with the constructor parameters if there are any, and the same class wraps every closed type of the definition that .NET gives back (a `Dictionary<string, int>` returned by a method is a `Dictionary`). When another type has the name already (`Queue` and `Stack` of `System.Collections`), the name of the generic one ends with the number of its type arguments.

```ring
dnImport("System.Collections.Generic")
oNumbers = new HashSet([ :typeArguments = ["System.Int32"] ])
oNumbers.Add(4)
oNumbers.Add(4)
? oNumbers.Count    # 1
oScores = new Dictionary([ :typeArguments = ["System.String","System.Int32"], :capacity = 10 ])
```

A generic type that no simple type closes (`TAssertions : Assertions<TAssertions>`, `T : struct, Enum`) has its class too, made from the open definition; the objects are made the same way, with real type arguments.

The members have the type argument as `object`, so Ring values go in and out as they are; the static members of a generic type need a closed type and are not in the class (use `dnNewGeneric`, `callMethod` on `dnType` with the closed name).

## Generic methods

Generic **methods** work too (the bridge infers the type arguments from the values), which is what makes LINQ possible.

When a type argument appears only in the result (`JsonSerializer.Deserialize<T>(json)`), the values cannot tell it, so you give it: in the named form with `:typeArguments`, a list of type names, or with `callGeneric` on a type object (`dnType`) or on an object that wraps an instance.

```ring
dnImport("System.Text.Json")
oJson = new JsonSerializer()
oTags = oJson.Deserialize([ :typeArguments = ["System.Collections.Generic.List`1[[System.String]]"], :json = '["a","b"]' ])
? oTags.Count    # 2
oType = dnType("System.Text.Json.JsonSerializer")
oTags = oType.callGeneric("Deserialize",["System.Collections.Generic.List`1[[System.String]]"],['["a","b"]'])
? oTags.Count    # 2
```

## Nested types

A nested type has a class too, named after the types around it: `SqlMapper.GridReader` of Dapper is `SqlMapperGridReader`, `Control.ControlCollection` of Windows Forms is `ControlCollection` (its name in the manifest).

## Exceptions and attributes

Exceptions and attributes have classes too: an exception that .NET gives back (`oError.InnerException`, the `Exception` of a task) is wrapped by the class of its type (`ArgumentException`, `AggregateException`) with its properties and methods. A .NET error that a call raises is still a Ring error with the message; the class is for the exception *objects*. Only the types marked obsolete are left out.

## Operators and conversions

The operators of a .NET type work in Ring: a class with `op_Addition`, `op_Equality`, `op_LessThan` and the like gets the Ring `operator` method, so `+ - * / % = != < > <= >= & | ^ << >>` and the unary minus call them. The object may come on either side (`5 + oBig`); when the type has no `op_Equality` or `op_LessThan`, `=` uses `Equals` and `<` uses `IComparable` or `IComparable<T>` (a type that only has `CompareTo` gets the operators `< > <= >=`). A cast of C# is `convertTo`.

```ring
dnImport("System")
dnImport("System.Numerics")
oOneHour = new TimeSpan().FromHours(1)
oHalfHour = new TimeSpan().FromMinutes(30)
oSum = oOneHour + oHalfHour          # TimeSpan + TimeSpan
? oSum.TotalMinutes                    # 90
? oOneHour > oHalfHour               # 1
oBig = new BigInteger().Parse("42")
? oBig.convertTo("System.Int64")     # the explicit conversion of BigInteger
```

## Indexers with several indexes

An indexer with several indexes (`matrix[row, column]`) takes the indexes as a list: `oMatrix.Item([1,2])` reads and `oMatrix.SetItem([1,2],4.5)` writes. A type that has a one-index indexer too keeps its plain form: `Item(1)`.

## Delegate types with extension methods

A delegate is a callback in Ring (`dnCallback`) and has no class of its own. A delegate type that extension methods extend does have one, as a library of parser combinators does (`Parser<T>` of Sprache): an object of that type has the extension methods as its methods, and `Invoke` calls the delegate itself.

```ring
# the Sprache package, wrapped as in "Your own assemblies" and loaded with dnLoad and dnImportFrom
oDigits = dnStatic("Sprache.Parse","Digit",[]).AtLeastOnce().Text()
? oDigits.Parse("12345")           # 12345
```

## Spans

A parameter of type `Span<T>` or `ReadOnlySpan<T>` takes what Ring has for an array: a text (`char`), a byte string or a list (`byte`, numbers), or an object that is an array. A `Span<T>` that the method fills takes a number, the size of a new buffer, or a buffer you made; the filled buffer is part of the answer, after the result and the `out` values (a list of bytes is a byte string, a list of chars a text).

A `Span<T>` that comes back is an array (a text for `char`, a byte string for `byte`), and a span passed by reference (`ref` or `out`) is read from the array you give and answered as an array, after the result.

```ring
dnImport("System")
aResult = dnStatic("System.Convert","TryToBase64Chars",["Ring",16])   # [done, chars, number of chars]
? left(aResult[2],aResult[3])                                          # UmluZw==
```

## Ref structs

A constructor can take a `Span<T>` or a ref struct the same way (`new Message("hello",3)`). A ref struct of a library (`MessagePackWriter`, `Utf8JsonReader`, a parser cursor) cannot be held by Ring, so the bridge makes it for the call from one value, with its public `op_Implicit`, a constructor whose first parameter takes it, or a static factory with one value (`FromString`, `Create...`, `Parse...`, `Wrap...`) (a text, bytes, an object such as an `IBufferWriter`); what the method does to the struct is lost, and a ref struct that has no such value, or that is only an `out` parameter, is still out of reach.

A ref struct that a method **returns** cannot be held by Ring either, so the bridge reads it in one go and answers what it holds: an **array** when it has a `ToArray` method, a **list of its items** when it is an enumerator or has `GetEnumerator` (`foreach`: `EnumerateLines`, `EnumerateCodePoints`; an item that is a span is a text or an array), or a **text** when it has one method without parameters that returns a string (`ToString`, `utf8_to_string`). A struct that only holds values (a buffer lease with `Length`, `Data`, `Flags`) is answered as its **properties**, a list of `[name, value]` pairs (`aLease["Length"]`; a span property is an array or a text). A ref struct that has `Dispose()` is disposed after it was read, like `foreach` does. A result that is a reference to a ref struct (`ref readonly TensorSpan<T>`) is read the same way.

```ring
aLines = dnStatic("System.MemoryExtensions","EnumerateLines",["one" + nl + "two"])
? len(aLines)      # 2
? aLines[2]        # two
```

## Properties, fields and references

A property (or field) of those types is read the same way: a `Span` property is an array (a text for `char`), a ref struct property is read like a ref struct result, a pointer is its address, and a `ref` property is its value (`oMemory.Span`, `oStream.PositionPointer`). These properties are read-only in Ring. A method that returns by reference (`ref int Number(int i)`) answers the value too; Ring cannot write through the reference.

## Pointers

A pointer parameter (`byte*`, `char*`, `void*`, `int*`) takes an address or a buffer. A **number** is the address (from `NativeMemory.Alloc`, `Marshal.AllocHGlobal`, a native library); a **text**, a **byte string**, a **list** of numbers or a **ByteBuffer** is a buffer that is pinned for the call, so the method can read it (a text and a byte string end with a zero, for C strings) and a ByteBuffer is the live array that the method may fill. The address of a buffer is valid during the call only: a method that keeps the pointer needs memory that you allocate. A pointer that a method returns is its address, a number.

```ring
dnImport("System")
nMemory = dnStatic("System.Runtime.InteropServices.NativeMemory","Alloc",[16])      # a void*: a number
dnStatic("System.Buffer","MemoryCopy",["hello",nMemory,16,5])                        # the text is the source buffer
? dnStatic("System.Runtime.InteropServices.Marshal","PtrToStringAnsi",[nMemory,5])   # hello
dnStatic("System.Runtime.InteropServices.NativeMemory","Free",[nMemory])
```

## Asynchronous streams

Ring has no `await foreach`, so an `IAsyncEnumerable<T>` that a method returns is read in one of two ways. `toList()` waits for every item and gives a Ring list; `asyncEnumerator()` gives the enumerator, `asyncNext()` waits for the next item (true while there is one), `Current` is the item and `asyncDispose()` ends the enumerator, which is the way to read a long or endless stream one item at a time.

```ring
# a channel of numbers: ReadAllAsync() returns an IAsyncEnumerable<int>
oChannel = dnType("System.Threading.Channels.Channel").callGeneric("CreateUnbounded",["System.Int32"],[])
oWriter = oChannel.getProp("Writer")
for n = 1 to 3
	oWriter.callMethod("TryWrite",[n * 10])
next
oWriter.callMethod("TryComplete",[])
oStream = oChannel.getProp("Reader").callMethod("ReadAllAsync",[])

oEnum = oStream.asyncEnumerator()
while oEnum.asyncNext()
	? oEnum.Current                 # 10, 20, 30
end
oEnum.asyncDispose()
```

## Where to go next

- [Core concepts](concepts.html): the names, overloads, properties and enums that every program uses.
- [Collections & LINQ](collections-linq.html): the generic collections, and the generic methods of LINQ.
- [The generator](generator.html): how the classes are made, and the audit that counts what Ring can and cannot use.
- [Rules and limits](gotchas.html): read it before a long program.
