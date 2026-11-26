---
title: Applications
lead: Complete desktop programs written in Ring — utilities, games and tools. Many are ports of the RingQt applications. Every one tests itself with --selftest.
---

Run one: `cd samples/UsingDotNet/applications/Calculator` then `ring Calculator.ring`. With `ring Calculator.ring --selftest` the application drives its own form, checks the results with `dnAssert()` and prints `SELFTEST OK`.

Ports of RingQt applications: Calculator, Stopwatch, TicTacToe, FifteenPuzzle, LightsOut, Game2048, MemoryGame, Snake, TowersOfHanoi, AnalogClock, RockPaperScissors, BMICalculator, GameOfLife, Minesweeper, EpochTime, AsciiTable, Calendar, EightQueens, Sudoku, Pong, Tetris, Sokoban, TypingQuiz, JulianDay, ChessEndgame (with the models of ML.NET). The others are new: Notepad, Paint, TodoList, ColorMixer, NumberGuess, Hangman, DiceRoller, UnitConverter, PasswordGenerator, WordCounter, Countdown, LoanCalculator, ImageViewer, LoginForm, TemperatureConverter, FileExplorer, AddressBook, plus the WPF applications WpfCalculator and WpfColorMixer.

Applications that are not windows: `samples/UsingDotNet/applications/WebApi` ([ASP.NET Core](aspnet.html)) and `samples/UsingDotNet/applications/Contacts` ([Entity Framework](ef.html)).

{{gallery:apps}}
