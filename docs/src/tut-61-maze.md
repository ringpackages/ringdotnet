---
title: "A maze"
lead: Make a perfect maze with a stack, find the shortest way through it with a queue, and draw both on a canvas. Two classic algorithms and a picture you can see.
---

## What you will learn

- generating a maze with **depth-first search** and a stack,
- finding the shortest path with **breadth-first search** and a queue,
- storing a grid as a list of lists,
- drawing walls and a path on a canvas,
- testing an algorithm with properties instead of fixed answers.

## The program

{{file:samples/UsingDotNet/tutorials/g62_maze.ring}}

![The maze window](img/shots/tut-g62.png "A 21 x 13 maze: green is the start, red the exit, orange the shortest way")

{{output:samples/UsingDotNet/tutorials/g62_maze.ring --selftest}}

## How it works

### The grid

The maze is `C_ROWS` rows of `C_COLUMNS` cells. `aOpen[row][column]` is a text with the open sides of the cell: `"N"`, `"E"`, `"S"` and `"W"` in any order (for example `"NE"`). A cell that has no letter is closed on all sides. Walls are drawn for every side that is **not** in the text.

### Making the maze: depth-first with a stack

Start in the top left cell and walk: choose a random neighbour that has not been visited, open the wall between the two cells and move there, pushing the new cell on the **stack**. When a cell has no unvisited neighbour, go back by popping the stack. The algorithm ends when the stack is empty — every cell was visited exactly once. This gives long winding corridors and a *perfect* maze: between any two cells there is **exactly one path**. The self test checks this property: a perfect maze with 273 cells has exactly 272 openings.

### Solving: breadth-first with a queue

The solver visits the cells in rings around the start — first the cells one step away, then two steps and so on — using a **queue** (the tutorial [Undo, redo and queues](tut-58-undo.html)). Each cell remembers the cell it was reached from (`aFrom`). The first time the exit is reached, the path found is the **shortest** one, because all closer cells were visited first. Follow the `aFrom` links back from the exit to the start to get the path, and draw it in orange. In a perfect maze there is only one path, but the same code finds the shortest way in a maze with loops.

> [!NOTE] Stack → goes deep first and finds *a* way. Queue → goes level by level and finds the *shortest* way. The only difference between the two algorithms is which end of the list you take the next cell from.

### Drawing

Cells on the path are small orange squares, the start is green and the exit red. Each cell draws only the walls that are not open (north and west for each cell, and the south and east borders at the edge). `oCanvas.line(x1, y1, x2, y2, color, width)` draws a wall.

### Testing

You cannot test a random maze against a fixed picture. The self test checks **properties** instead: the number of openings, the path starts at the exit and ends at the start, every step moves to a neighbour, and **no step crosses a wall**. Tests for properties keep working when you change the generator.

## What you learned

- stack and queue in real algorithms,
- a grid as a list of lists,
- shortest path by breadth-first search,
- testing properties.

## Exercises

1. Add a button that shows the maze being built, one step per timer tick (the tutorial [Watching sorting algorithms](tut-60-sorting.html)).
2. Remove some walls at random (a maze with loops) and check that the solver still finds the shortest way.
3. Let the user move a dot with the arrow keys from the start to the exit.

## Next

[An image filter lab](tut-62-filters.html)
