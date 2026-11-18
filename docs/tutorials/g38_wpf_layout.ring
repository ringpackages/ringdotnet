# Tutorial 38: WPF layout and styles - Grid, resources, a Style for all buttons, a keypad
load "dotnet.ring"
using {
	"System.Windows"
	"System.Windows.Controls"
	"System.Windows.Controls.Primitives"
	"System.Windows.Media"
	"System.Windows.Data"
	"System"
}

oWindow = ""
oDisplay = ""
cEntered = ""

func main
	# The window: a Grid with a display row on top and a keypad below.
	#  - Grid.RowDefinitions / ColumnDefinitions divide the space: "Auto" = as big as the content, "*" = share what is left
	#  - Window.Resources holds a Style: every Button inside gets the same look without repeating it
	cXaml = '<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Title="Keypad" Width="260" Height="360" Background="#F4F2FB">'
	cXaml += '<Window.Resources>'
	cXaml += '<Style TargetType="Button"><Setter Property="Margin" Value="4"/><Setter Property="FontSize" Value="22"/>'
	cXaml += '<Setter Property="Background" Value="#5B3FD1"/><Setter Property="Foreground" Value="White"/><Setter Property="BorderThickness" Value="0"/></Style>'
	cXaml += '</Window.Resources>'
	cXaml += '<Grid Margin="8"><Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="*"/><RowDefinition Height="*"/><RowDefinition Height="*"/></Grid.RowDefinitions>'
	cXaml += '<Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>'
	cXaml += '<Border Grid.Row="0" Grid.ColumnSpan="3" Background="White" CornerRadius="6" Margin="4" Padding="10"><TextBlock x:Name="display" FontSize="30" HorizontalAlignment="Right" Text="0"/></Border>'
	# the buttons 1-9 in three rows, then 0 and two special keys
	for nIndex = 1 to 9
		nRow = floor((nIndex - 1) / 3) + 1
		nColumn = (nIndex - 1) % 3
		cXaml += '<Button x:Name="key' + nIndex + '" Grid.Row="' + nRow + '" Grid.Column="' + nColumn + '" Content="' + nIndex + '"/>'
	next
	cXaml += '<Button x:Name="clear" Grid.Row="4" Grid.Column="0" Content="C" Background="#D14F3F"/>'
	cXaml += '<Button x:Name="key0" Grid.Row="4" Grid.Column="1" Content="0"/>'
	cXaml += '<Button x:Name="back" Grid.Row="4" Grid.Column="2" Content="&#x232B;" Background="#888888"/>'
	cXaml += '</Grid></Window>'
	oWindow = wpfXaml(cXaml)
	oDisplay = wpfFind(oWindow,"display")

	# events: the same function for every digit key
	for nIndex = 0 to 9
		wpfFind(oWindow,"key" + nIndex).setClickEvent("pressKey(" + nIndex + ")")
	next
	wpfFind(oWindow,"clear").setClickEvent("clearKeys()")
	wpfFind(oWindow,"back").setClickEvent("backspace()")

	wpfTest(oWindow,"selfTest()")
	wpfRun(oWindow)
	wpfEnd()

func pressKey nDigit
	if len(cEntered) < 12
		cEntered += nDigit
	ok
	showEntered()

func clearKeys
	cEntered = ""
	showEntered()

func backspace
	if len(cEntered) > 0
		cEntered = left(cEntered,len(cEntered) - 1)
	ok
	showEntered()

func showEntered
	if cEntered = ""
		oDisplay.Text = "0"
	else
		oDisplay.Text = cEntered
	ok

func selfTest
	clickKey("key4")
	clickKey("key2")
	dnAssert("two digits",oDisplay.Text,"42")
	clickKey("back")
	dnAssert("backspace",oDisplay.Text,"4")
	clickKey("clear")
	dnAssert("clear shows zero",oDisplay.Text,"0")
	clickKey("key0")
	clickKey("key7")
	dnAssert("zero then seven",oDisplay.Text,"07")
	# the style was applied to all buttons: the keys have the margin of the Style
	dnAssert("the style: Margin of a key",wpfFind(oWindow,"key5").Margin.Left,4)

func clickKey cName
	wpfFind(oWindow,cName).RaiseEvent(new RoutedEventArgs().New_([ :routedEvent = new WpfButtonBase().ClickEvent ]))
