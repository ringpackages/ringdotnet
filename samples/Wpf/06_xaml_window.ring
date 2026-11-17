# A window described in XAML: parse it, find the named elements, handle events

load "../../libraries/dotnetlib/dotnetlib.ring"
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


cXaml = '<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Title="From XAML" Width="320" Height="180">'
cXaml += '<StackPanel Margin="15"><TextBlock x:Name="message" FontSize="18" Text="Press the button"/>'
cXaml += '<Button x:Name="press" Content="Press me" Margin="0,10,0,0"/></StackPanel></Window>'
oWindow = wpfXaml(cXaml)
oMessage = wpfFind(oWindow,"message")
oPress = wpfFind(oWindow,"press")
oPress.setClickEvent("oMessage.Text = 'The XAML button was pressed'")

wpfTest(oWindow,"selfTest()")
wpfRun(oWindow)
wpfEnd()

# --------------------------------------------------------------------------

func selfTest
	dnAssert("title from XAML",oWindow.Title,"From XAML")
	oEvent = dnNewWith("RoutedEventArgs",[ :routedEvent = new WpfButtonBase().ClickEvent ])
	oPress.RaiseEvent(oEvent)
	dnAssert("event handler",oMessage.Text,"The XAML button was pressed")
