# Tutorial 15: WPF - describe the window in XAML, find elements by name, bind a slider to a text
load "dotnet.ring"
dnUseDesktop()
using {
	"System.Windows"
	"System.Windows.Controls"
	"System.Windows.Controls.Primitives"
	"System.Windows.Media"
	"System.Windows.Shapes"
	"System.Windows.Data"
	"System.Windows.Threading"
	"System"
}

oWindow = ""
oSlider = ""
oShape = ""
oValue = ""
oGreet = ""
oNameBox = ""

func main
	# 1. The window is described in XAML: a text format of elements and attributes
	cXaml = '<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Title="WPF tutorial" Width="360" Height="340">'
	cXaml += '<StackPanel Margin="15">'
	cXaml += '<TextBlock FontSize="20" Text="Hello from XAML"/>'
	cXaml += '<TextBox x:Name="nameBox" Margin="0,10,0,0" Text="Ring"/>'
	cXaml += '<Button x:Name="greet" Content="Greet" Margin="0,8,0,0"/>'
	cXaml += '<TextBlock x:Name="greeting" FontSize="16" Margin="0,8,0,0"/>'
	cXaml += '<Slider x:Name="size" Minimum="20" Maximum="120" Value="60" Margin="0,14,0,0"/>'
	cXaml += '<TextBlock x:Name="sizeText" Margin="0,4,0,0"/>'
	cXaml += '<Ellipse x:Name="circle" Fill="SteelBlue" Width="60" Height="60" Margin="0,8,0,0"/>'
	cXaml += '</StackPanel></Window>'
	oWindow = wpfXaml(cXaml)

	# 2. Find the elements by their x:Name
	oNameBox = wpfFind(oWindow,"nameBox")
	oGreet = wpfFind(oWindow,"greeting")
	oSlider = wpfFind(oWindow,"size")
	oValue = wpfFind(oWindow,"sizeText")
	oShape = wpfFind(oWindow,"circle")

	# 3. Events work like Windows Forms events
	wpfFind(oWindow,"greet").setClickEvent("oGreet.Text = 'Hello, ' + oNameBox.Text + '!'")

	# 4. Data binding: the text follows the slider, with no code at all
	oBinding = new WpfBinding().New_1("Value")
	oBinding.Source = oSlider
	oValue.SetBinding(oValue.TextProperty,oBinding)

	# 5. Events can also change other elements: the circle follows the slider
	oSlider.setValueChangedEvent("oShape.Width = oSlider.Value oShape.Height = oSlider.Value")

	wpfTest(oWindow,"selfTest()")
	wpfRun(oWindow)
	wpfEnd()

func selfTest
	wpfFind(oWindow,"greet").RaiseEvent(new RoutedEventArgs().New_1(new WpfButtonBase().ClickEvent))
	dnAssert("greeting",oGreet.Text,"Hello, Ring!")
	oSlider.Value = 100
	dnAssert("binding",oValue.Text,"100")
	dnAssert("the circle follows the slider",oShape.Width,100)
