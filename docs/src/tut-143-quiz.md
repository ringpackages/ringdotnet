---
title: "A project: a quiz"
lead: A quiz asks questions, checks the answers, gives feedback, shows a score and remembers the best scores. This project keeps the questions as data, uses radio buttons, lets one button do two jobs, and saves the scores in a file.
---

## What you will learn

- questions as **data**: a list of `[question, answers, right answer]`,
- an array of `RadioButton` controls made in a loop,
- a button with **two jobs** (*Check* and then *Next*) and a state flag,
- feedback that shows the right answer,
- a score screen and a saved list of **best scores**,
- a test that plays the quiz.

This is the pattern of any wizard or exam program: a list of steps, a current step, a state, and a button that moves on.

## The program

{{file:samples/UsingDotNet/tutorials/g143_quiz.ring}}

![The quiz](img/shots/tut-g143.png "A question of the quiz")

{{output:samples/UsingDotNet/tutorials/g143_quiz.ring --selftest}}

## How it works

### The questions are data

`aQuestions` is a list at the top of the program. Each entry has the text of the question, a list of four answers and the number of the right answer. Adding a question means adding a line; the program does not change, and the list could be read from a file or a JSON text (the tutorial [JSON and XML](tut-06-json-xml.html)).

### Radio buttons in a loop

The four `RadioButton` controls are made in a loop and kept in the list `aAnswers`, so the code can say `aAnswers[i].Text = ...` for all of them. Radio buttons that have the same parent are one group, so choosing one turns the others off. `chosen()` returns the number of the button that is on, or 0.

### One button, two jobs

The button says **Check** at first. The first click checks the answer: it adds to the score, shows *Right!* or the right answer, disables the buttons so that the answer cannot be changed, and sets `lAnswered`. The button now says **Next**, and the second click shows the next question, or the result after the last one (the button says **Result** then). The flag `lAnswered` tells which job the click has. A click before any answer is chosen shows *Choose an answer first* and changes nothing.

### The result and the best scores

`showResult` writes the score, hides the radio buttons and appends the score as a line to a file with `File.AppendAllText`. `bestScores` reads the lines, makes numbers, sorts them with `sort` and `reverse` and keeps the first three. The scores stay between runs because they are in a file. (The file is in the folder for temporary files, and the program deletes it at the end of the test so that the output is the same each time.)

### The test plays

The function `play(n)` chooses answer `n` and clicks the button. The test answers the questions: nothing chosen, right, wrong (and the feedback names the right answer), right, right, and the score is 3 of 4. It checks the progress text, the feedback, the button text and the best scores. No mouse is needed, and the test is written in the words of the quiz.

> [!NOTE] The program sets the state in the functions (`showQuestion`, `checkAnswer`) and never in the event code, which is only `nextStep()`. This keeps the events short and the test simple.

## What you learned

- questions as data,
- radio buttons made in a loop,
- one button with a state,
- saving scores in a file,
- a test that plays through the whole quiz.

## Exercises

1. Show the questions in a random order (`random` in a loop, or shuffle the list first).
2. Add a time limit for each question with a timer (the tutorial [Timers and progress](tut-34-timers.html)).
3. Read the questions from a JSON file and write a second file with more questions.
4. Show the list of all the scores, not only the best three, with the date of each.

## Next

[A project: a command runner](tut-37-runner.html)
