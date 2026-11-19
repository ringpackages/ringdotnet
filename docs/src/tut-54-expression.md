---
title: "An expression calculator"
lead: How does a program understand "2 * (3 + 4)"? This lesson turns the text into tokens with a regular expression and reads them with a small recursive-descent parser that knows operator precedence and reports clear errors.
---

## What you will learn

- the two steps of every language tool: **tokens**, then **grammar**,
- how a parser respects precedence (`*` before `+`) and parentheses,
- writing a grammar as a few short rules and one function per rule,
- error messages that say what is wrong,
- using the .NET `Math` class for functions like `sqrt`.

## The grammar

Each rule becomes one function. A rule only calls the rules *below* it, and that is how precedence works: the rule for `+` and `-` calls the rule for `*` and `/` to get its operands, so the multiplications are done first.

```text
expression = term    { ("+" | "-") term }
term       = power   { ("*" | "/") power }
power      = unary   [ "^" power ]
unary      = "-" unary | primary
primary    = number | "(" expression ")" | name "(" expression { "," expression } ")"
```

`{ ... }` means "zero or more times", `[ ... ]` "optional". Parentheses return to the top rule, so `(1 + 2) * 3` works. `power` calls itself on the right side, which makes `2 ^ 3 ^ 2` mean `2 ^ (3 ^ 2)`.

## The program

{{file:samples/UsingDotNet/tutorials/ch04_expression.ring}}

{{output:samples/UsingDotNet/tutorials/ch04_expression.ring}}

## How it works

### Tokens

`tokenize` uses one regular expression, `\s*(\d+\.?\d*|[A-Za-z]+|[-+*/^(),]|\S)`: skip spaces, then take a number, a name, an operator — or *any other* character, which is reported as `unknown character '$'`. `Regex.Matches` gives all the pieces; `Groups.Item(1).Value` is the piece without the spaces.

### The parser

`aTokens` is the list and `nPos` the position. `peek()` looks at the next token without taking it; the functions `expression`, `term`, `power`, `unary` and `primary` follow the grammar one to one. `expect(")")` checks that the closing parenthesis is there.

### Errors

When something is wrong the parser stores a message in `cError` and the loops stop. Look at the three last lines of the output: `2 * (3 +` ends too early, `4 $ 4` has a strange character, `1 / 0` is a division by zero. A calculator that answers *what* is wrong is much better than one that says "syntax error".

### Functions

`sqrt(16) + max(3, 9)` is a name followed by a list of expressions. `callFunction` collects the arguments and calls the matching method of `Math` (`Sqrt`, `Max`...). Adding `sin` or `log` is one more `on` line.

> [!TIP] This technique is how real tools read formulas, configuration files, query languages and even programming languages. A grammar of ten lines and ten small functions can read most small languages.

## What you learned

- tokens and grammar,
- one function per grammar rule,
- precedence through the order of the rules,
- clear error messages,
- `Math` functions from a parser.

## Exercises

1. Add `%` (remainder) at the same level as `*` and `/`.
2. Add variables: `x = 5` stores a value and later expressions can use `x`.
3. Show the **position** of the error (the number of the token) in each message.

## Where to go next

This was the last tutorial of the chapter **Collections and algorithms**. The next chapter is **Files and streams**: it starts with [Paths and the environment](tut-59-paths.html). The [Tutorials](tutorials.html) page lists all the chapters, and you can start any of them.
