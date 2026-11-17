# A window described in XAML: parse it, find the named elements, handle events

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
dnImport("System.Windows")
dnImport("System.Windows.Controls")
dnImport("System.Windows.Controls.Primitives")
dnImport("System.Windows.Media")
dnImport("System.Windows.Shapes")
dnImport("System.Windows.Data")
dnImport("System.Windows.Threading")
dnImport("System")


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
	oEvent = new RoutedEventArgs().New_1(new WpfButtonBase().ClickEvent)
	oPress.RaiseEvent(oEvent)
	dnAssert("event handler",oMessage.Text,"The XAML button was pressed")
