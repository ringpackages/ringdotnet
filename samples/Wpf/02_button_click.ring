# A button counts its clicks (routed Click event)

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


nClicks = 0
oWindow = wpfWindow("Click counter",300,150)
oPanel = new StackPanel()
oWindow.Content = oPanel
oInfo = wpfLabel("0 clicks")
oButton = wpfButton("Click me","clicked()")
oPanel.Children.Add(oInfo)
oPanel.Children.Add(oButton)

wpfTest(oWindow,"selfTest()")
wpfRun(oWindow)
wpfEnd()

# --------------------------------------------------------------------------

func clicked
	nClicks++
	oInfo.Content = "" + nClicks + " clicks"

func selfTest
	oEvent = new RoutedEventArgs().New_1(new WpfButtonBase().ClickEvent)
	oButton.RaiseEvent(oEvent)
	oButton.RaiseEvent(oEvent)
	dnAssert("two clicks",oInfo.Content,"2 clicks")
