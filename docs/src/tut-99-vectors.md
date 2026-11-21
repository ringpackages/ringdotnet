---
title: "Vectors and matrices"
lead: Points, directions, distances and rotations are everywhere in graphics, games and simulations. System.Numerics has small, fast types for them. This lesson uses Vector3 and Vector2 for lengths, sums, dot and cross products, and Matrix3x2 for moving and rotating a point.
---

## What you will learn

- `Vector2`, `Vector3`: a point or a direction,
- `Length`, `Distance`, `Normalize`,
- `Add`, `Subtract`, `Multiply`, `Negate` and `Lerp`,
- the **dot product** and the **cross product** and what they tell you,
- `Matrix3x2`: a move, a rotation, and both together.

The tutorial [Drawing and animation](tut-14-animation.html) moved shapes with Ring numbers. With vectors you describe a position as one value, and a transformation as one matrix, so the same code works for one point or for a thousand.

## The program

{{file:samples/UsingDotNet/tutorials/ch03_vectors.ring}}

{{output:samples/UsingDotNet/tutorials/ch03_vectors.ring}}

> [!NOTE] This program uses a few generic functions (`dnNew`, `dnStatic`, `dnNewGeneric`, `callMethod`, `getProp`) where a class cannot be used. The lesson [The generic functions](tut-160-generic-calls.html) explains them.

## How it works

### Vectors

A `Vector3` holds three numbers `X`, `Y`, `Z`. It can be a **position** (a point in space) or a **direction** with a length (a speed, a force). `Vector2` has two numbers and `Vector4` four. They are value types (structs): `new Vector3().@New([ :x = 3, :y = 4, :z = 0 ])` makes one by names, and `oV.X` reads a component. The numbers are *single-precision* floats (about 7 digits), so a result such as `0.6` can really be `0.6000000238`; the program rounds before printing (`roundNumber`), and so should yours when you compare.

### Operations

The operations are **static methods**: `Add(a, b)`, `Subtract(a, b)`, `Multiply(a, number)`, `Negate(a)`. In Ring you call them on any object of the class (`oVector = new Vector3()`, then `oVector.Add(oA, oB)`). `Length()` is the distance from zero (3, 4, 0 has length 5), `Distance(a, b)` the distance between two points, and `Normalize(a)` the direction of `a` with length 1 — the *unit vector*, useful when you want a direction without a size. `Lerp(a, b, t)` is the point at the fraction `t` between `a` and `b` (0.5 is the middle): the base of every smooth movement.

### Dot product

`Dot(a, b)` is one **number**. It is 0 when the two directions are at a right angle, positive when they point more or less the same way, negative when they point in opposite ways. For two vectors of length 1 it is the cosine of the angle between them, so it answers questions such as *"is the enemy in front of me?"* without any trigonometry.

### Cross product

`Cross(a, b)` is a **vector** at a right angle to both `a` and `b`. The cross product of the x axis and the y axis is the z axis (step 3). It is used for the *normal* of a surface, for the axis of a turn, and for the sign of a turn in 2D.

### Matrices

A matrix describes a transformation of space as a block of numbers. `Matrix3x2` works in the plane: `CreateTranslation(x, y)` moves, `CreateScale` scales and `CreateRotation(angle)` rotates around the origin, with the angle in **radians** (half a turn is `3.14159...`, a quarter is half of that). `Vector2.Transform(point, matrix)` applies it. Turning (1, 0) by 90 degrees gives (0, 1); moving it by (10, 5) gives (11, 5).

`Matrix3x2.Multiply(first, second)` combines two transformations into one: *first turn, then move* gives (10, 6), because the point is turned to (0, 1) and then moved. The **order** matters — moving first and turning second gives another point — which is the most common mistake with matrices. These methods have several forms, so the bridge chooses the form from the arguments (`new Matrix3x2().CreateRotation(...)`). `Matrix4x4` does the same in three dimensions (with `CreatePerspective`, `CreateLookAt`...) and `Quaternion` describes 3D rotations without the problems of angles.

> [!NOTE] These types are made for speed in .NET code. Each call from Ring crosses the bridge, so use them for the *logic* of your program, and let .NET do the heavy loops (for example a LINQ query, the tutorial [Collections and LINQ](tut-04-collections.html)) when you have thousands of points.

## What you learned

- vectors as points and directions,
- length, distance, unit vectors and `Lerp`,
- the dot product (a number) and the cross product (a vector),
- matrices that move and rotate, and combining them,
- the order of transformations matters.

## Exercises

1. Write `angleBetween(a, b)` with `Dot`, `Length` and `Acos` (the tutorial [Numbers, dates and times](tut-03-numbers-dates.html)).
2. Move a point along a straight line from A to B in 10 steps with `Lerp` and print the points.
3. Rotate the four corners of a square by 45 degrees and print them.
4. Try *move first, then turn* and compare the result with step 6.

## Next

[Randomness](tut-69-random.html)
