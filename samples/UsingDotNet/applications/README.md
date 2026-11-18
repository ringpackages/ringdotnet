# RingDotNet applications

Small Windows Forms applications written in Ring with RingDotNet. Many are ports of the RingQt applications in `ring/applications`.

Run one: `cd Calculator` then `ring main.ring`.

Every application can test itself: `ring main.ring --selftest` drives the form, checks the results with `dnAssert()` and prints `SELFTEST OK`. `samples/UsingDotNet/tests/run.sh` runs all of them.

They use the helpers of `libraries/dotnetlib/gui.ring` (`uiForm`, `uiButton`, `uiLabel`, `uiTextBox`, `uiTimer`, `uiMenu`, `UiCanvas`, `uiTest`, `uiRun`...), loaded together with `dnImport("System.Windows.Forms")`.


## The applications (41)

AddressBook, AnalogClock, AsciiTable, BMICalculator, Calculator, Calendar, ColorMixer, Countdown, DiceRoller, EightQueens, EpochTime, FifteenPuzzle, FileExplorer, Game2048, GameOfLife, Hangman, ImageViewer, JulianDay, LightsOut, LoanCalculator, LoginForm, MemoryGame, Minesweeper, Notepad, NumberGuess, Paint, PasswordGenerator, Pong, RockPaperScissors, Snake, Sokoban, Stopwatch, Sudoku, TemperatureConverter, Tetris, TicTacToe, TodoList, TowersOfHanoi, TypingQuiz, UnitConverter, WordCounter

Ports of RingQt applications: Calculator, Stopwatch, TicTacToe, FifteenPuzzle, LightsOut, Game2048, MemoryGame, Snake, TowersOfHanoi, AnalogClock, RockPaperScissors, BMICalculator, GameOfLife, Minesweeper, EpochTime, AsciiTable, Calendar, EightQueens, Sudoku, Pong, Tetris, Sokoban, TypingQuiz, JulianDay. The others are new: Notepad, Paint, TodoList, ColorMixer, NumberGuess, Hangman, DiceRoller, UnitConverter, PasswordGenerator, WordCounter, Countdown, LoanCalculator, ImageViewer, LoginForm, TemperatureConverter, FileExplorer, AddressBook.
