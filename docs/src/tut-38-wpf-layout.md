---
title: "Tutorial 38: WPF layout and styles"
lead: WPF windows arrange themselves. This lesson uses a Grid with rows and columns, a Style that gives every button the same look, and a keypad whose keys are made in a loop.
---

## What you will learn

- the `Grid` and its row and column definitions (`Auto`, `*`),
- `Grid.Row`, `Grid.Column`, `Grid.ColumnSpan`,
- resources and styles,
- building XAML with a loop,
- many events with one function.

## Layout in WPF

WPF does not use pixel positions. A **panel** arranges its children:

| Panel | Arrangement |
|---|---|
| `StackPanel` | one after another, vertically or horizontally |
| `Grid` | rows and columns |
| `DockPanel` | edges and a rest |
| `WrapPanel` | like text: wraps to the next line |
| `Canvas` | exact positions |

The window can be resized and everything follows. The `Grid` is the most useful: you divide the space and put each element into a cell.

## The program

{{file:docs/tutorials/g38_wpf_layout.ring}}

![The keypad](img/shots/tut-g38-typed.png "After typing 4, 2, 7")

{{output:docs/tutorials/g38_wpf_layout.ring --selftest}}

## How it works

### The grid

```xml
<Grid.RowDefinitions>
	<RowDefinition Height="Auto"/>   <!-- the display: as high as its content -->
	<RowDefinition Height="*"/>      <!-- four rows that share the rest equally -->
	...
</Grid.RowDefinitions>
<Grid.ColumnDefinitions>
	<ColumnDefinition Width="*"/> ... three equal columns
</Grid.ColumnDefinitions>
```

`Auto` is as big as the content needs, `*` takes a share of what is left (`2*` would take double). A fixed number is pixels. The keypad's four rows therefore grow and shrink with the window.

### Placing elements

`Grid.Row="2" Grid.Column="1"` puts an element into the cell in row 2, column 1 (counting from 0). `Grid.ColumnSpan="3"` lets the display stretch over all three columns.

### Resources and styles

```xml
<Window.Resources>
	<Style TargetType="Button">
		<Setter Property="Margin" Value="4"/>
		<Setter Property="FontSize" Value="22"/>
		<Setter Property="Background" Value="#5B3FD1"/>
		...
	</Style>
</Window.Resources>
```

A `Style` with `TargetType="Button"` and no name applies to **every** button in the window: change the look in one place. A single button can still override a setting: the **C** key says `Background="#D14F3F"` itself. Styles are WPF's answer to "I wrote the same three properties on twenty controls".

### XAML from a loop

The program builds the XAML text with a Ring loop: nine buttons whose row and column come from the key number (the same arithmetic as in [tutorial 35](tut-35-tictactoe.html)). The loop is simply text assembly: `'<Button x:Name="key' + nIndex + '" Grid.Row="' + nRow + '" ...'`. That keeps the program short; for a fixed layout you would write the XAML in a file.

### Many events, one function

After the window exists, a loop connects every digit key: `setClickEvent("pressKey(" + nIndex + ")")`. All ten keys call the same function with their own digit. `pressKey` appends to the entered text (at most 12 digits), `showEntered` writes it into the display (`0` when empty).

### Testing

A test raises the click event on a key: `RaiseEvent(new RoutedEventArgs().New_([ :routedEvent = new WpfButtonBase().ClickEvent ]))`, and checks the display: `42`, backspace gives `4`, clear gives `0`. It also reads the `Margin` of a key and finds `4`: the style was applied.

## What you learned

- `Grid` rows and columns with `Auto` and `*`,
- `Grid.Row`, `Grid.Column`, `Grid.ColumnSpan`,
- one `Style` for all controls of a type,
- XAML assembled by a loop, many events with one function.

## Exercises

1. Make the equal row heights `2*` for the display and `*` for the keys.
2. Add a style for `TextBlock` with a bigger font.
3. Add a `.` key and a `+` key that appends the symbol (use another row in the grid).
4. Give the window a minimum size (`MinWidth`, `MinHeight`) and resize it to see the layout follow.

## Next

[Tutorial 39: A REST client](tut-39-rest-client.html).
