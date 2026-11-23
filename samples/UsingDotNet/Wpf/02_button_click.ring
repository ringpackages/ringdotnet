# A button counts its clicks (routed Click event)

load "dotnet.ring"

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
oPanel {
	Children.Add(oInfo)
	Children.Add(oButton)
}

wpfRun(oWindow)

# --------------------------------------------------------------------------

func clicked

	nClicks++
	oInfo.Content = "" + nClicks + " clicks"
