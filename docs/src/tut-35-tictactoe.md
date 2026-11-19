---
title: "A project: Tic-Tac-Toe"
lead: A complete game. The lesson is the structure: the state and the rules in plain functions that can be tested, and a thin layer of buttons that shows the state.
---

## What you will learn

- separating the **rules** from the **window**,
- representing a game as data,
- creating controls in a loop,
- testing a game without clicking.

## The structure

| Layer | Contains | Knows about windows? |
|---|---|---|
| **State** | `aBoard` (nine cells), `cTurn`, `lOver` | no |
| **Rules** | `winnerOf(aBoard)`, `boardFull(aBoard)` | no |
| **Moves** | `play(nCell)`, `newGame()` | yes: they update the buttons and the status |
| **Window** | nine buttons, a label, *New game* | yes |

The rules take the board **as a parameter** and *return* an answer. They do not read or write buttons. That makes them easy to test and easy to reuse: the same `winnerOf` could drive a computer opponent.

## The program

{{file:samples/UsingDotNet/tutorials/ch12_tictactoe.ring}}

![A game in progress, X has won](img/shots/tut-g35-won.png "X took the top row")

{{output:samples/UsingDotNet/tutorials/ch12_tictactoe.ring --selftest}}

## How it works

### The board as data

A list of nine texts, `""` for an empty cell, `"X"` or `"O"`. Cell numbers go 1–9 across and down:

```text
1 2 3
4 5 6
7 8 9
```

### The rules

There are only eight ways to win: three rows, three columns, two diagonals. `winnerOf` keeps them as a list of eight lists of three cell numbers. For each line it asks: is the first cell not empty, and are the other two the same? The first line where that is true gives the winner. Compare this with eight nested `if`s: the *data* describes the game, the code is short.

### Nine buttons in a loop

```ring
for nCell = 1 to 9
	nRow = floor((nCell - 1) / 3)
	nColumn = (nCell - 1) % 3
	oButton = uiButton(oForm," ",10 + nColumn * 93,46 + nRow * 93,90,90,"play(" + nCell + ")")
	aButtons + oButton
next
```

The position comes from arithmetic: the row is the cell number divided by 3, the column is the remainder. The click code is the **text** `"play(5)"`, built with the cell number: each button calls `play` with its own number. The buttons are kept in `aButtons` so that `play` can write the X or O into the right one.

### A move

`play(nCell)` ignores the move when the game is over or the cell is taken. Otherwise it puts the letter into the board *and* on the button, checks for a winner or a full board, and changes the turn. The status label always tells what happens next.

### Testing

The test first checks the **rules** with boards made on the spot: an empty board, a row, a column, a diagonal, a full board with no winner. Then it **plays** games by calling `play` — X takes the top row, the extra move is refused, `newGame` resets, and a full game ends in a draw. No mouse involved, and the tests run in a fraction of a second.

The checks of this program are in a separate file, `selftest/ch12_tictactoe.ring`:

{{file:samples/UsingDotNet/tutorials/selftest/ch12_tictactoe.ring}}

## What you learned

- state, rules, moves, window: four layers,
- data that describes the game (the eight lines),
- controls from a loop, with click code built as a text,
- tests that play.

## Exercises

1. Highlight the three winning buttons.
2. Add a score: how many games X and O have won.
3. Write `bestMove(aBoard, cPlayer)` for a computer opponent: win if you can, block if you must, otherwise take the centre.
4. Make the board size 4 × 4 with four in a row.

The [TicTacToe](gallery-apps.html#tic-tac-toe) application is the full-size version.

## Next

[A project: a quiz](tut-143-quiz.html)
