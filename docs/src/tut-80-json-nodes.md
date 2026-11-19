---
title: "JSON as a tree"
lead: JsonDocument reads JSON but cannot change it. JsonNode, JsonObject and JsonArray give you a tree that you can read, edit and build. This lesson changes a configuration, builds a report, merges settings with defaults, and clones a tree.
---

## What you will learn

- parsing JSON into a tree you can edit (`JsonNode`, `JsonObject`, `JsonArray`),
- reading with `Item("key")` and `Item(index)`,
- `SetItem`, `Add`, `Remove` on objects and `Add` on arrays,
- building a document from Ring values,
- merging two documents,
- `DeepClone` and `DeepEquals`.

These classes are in `System.Text.Json.Nodes`. The tutorial [JSON and XML](tut-06-json-xml.html) read JSON with `JsonDocument`; that class is fast but read-only. Use the nodes when you need to **change** JSON: configuration files, request bodies, data you assemble.

## The program

{{file:samples/UsingDotNet/tutorials/ch02_json_nodes.ring}}

{{output:samples/UsingDotNet/tutorials/ch02_json_nodes.ring}}

## How it works

### Reading

`new JsonNode().Parse(text)` gives a node; `AsObject()` and `AsArray()` give the specific class. `oRoot.Item("name")` is the child with that key and `oTags.Item(0)` the first array item (indexes start at 0, as in .NET). Every node has `ToString()` for simple values — numbers arrive as text, so `number(oRoot.Item("port").ToString())` — and `GetPath()`, which names where the node lives (`$.tags[0]`). `GetValueKind()` tells `Object`, `Array`, `String`, `Number`, `True`, `False` or `Null`.

### Changing

| What | Call |
|---|---|
| set an existing value | `oRoot.SetItem("port",9090)` |
| add a key | `oRoot.Add([ :propertyName = "owner", :value = "Ann" ])` |
| remove a key | `oRoot.Remove("debug")` |
| add an array item | `oTags.Add("json")` |

`Add` of an object has several forms, so the key-and-value form takes a list of named values (`propertyName` and `value`). A Ring text or number is converted to a JSON value for you.

### Missing keys

`oRoot.Item("nothing")` does not raise an error: it gives the **.NET null**, which arrives in Ring as an object that answers `isNull()` (the tutorial [Paths and the environment](tut-59-paths.html)). Check with `ContainsKey` when a key is optional.

### Building

Step 5 builds a report: a `JsonObject` with values, a `JsonArray` of `JsonObject`s. `ToJsonString(NULL)` writes compact JSON; with `JsonSerializerOptions` and `WriteIndented = True` it writes indented JSON (the `pretty` helper).

> [!WARNING] A Ring `True` is the **number 1**, so `Add([ :propertyName = "final", :value = True ])` writes `1`. To write a JSON `true`, parse it: `new JsonNode().Parse("true")`. The same applies to `null`: parse `"null"`.

### Merging

`merge(defaults, ours)` copies each key of our settings into the defaults. Where both sides hold an **object** (`database`), it merges them one level deeper, so `database.timeout` from the defaults survives while `database.host` and `pool` come from our settings. The keys of a `JsonObject` are read by parsing its text again with `JsonDocument` and listing `EnumerateObject()`; `DeepClone()` makes sure that the copied values do not belong to two trees at once (a node can have only one parent).

### Cloning and comparing

`DeepClone()` copies a whole tree. Changing the clone (`port` → 1) leaves the original alone. `DeepEquals(a, b)` compares two trees by **content**, not by identity.

## What you learned

- `JsonNode`, `JsonObject`, `JsonArray`,
- `Item`, `SetItem`, `Add`, `Remove`, `ContainsKey`,
- the Ring `True` is a number: parse `true` for JSON,
- merging with a small recursive function,
- `DeepClone` and `DeepEquals`.

## Exercises

1. Read a configuration file (the tutorial [Settings](tut-32-settings.html)) into a node, change one value and save it again.
2. Write `getPath(oRoot, "database.host")` that follows a dotted path.
3. Write `removeNulls(oNode)` that deletes all keys with `null` values, at every depth.
4. Send the JSON of step 5 through the pipe of the tutorial [Two programs talking](tut-79-processes-talk.html).

## Next

[XML in depth](tut-72-xml.html)
