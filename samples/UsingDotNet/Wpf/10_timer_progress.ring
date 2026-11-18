# A DispatcherTimer fills a progress bar

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
	"System.Diagnostics"
}


nPercent = 0
oWindow = wpfWindow("Progress",320,120)
oPanel = new StackPanel()
oWindow.Content = oPanel
oBar = new WpfProgressBar() {
	Height = 24
	Margin = new Thickness(15,15,15,15)
	Maximum = 100
}
oPanel.Children.Add(oBar)
oText = wpfLabel("0%")
oPanel.Children.Add(oText)
oTimer = new DispatcherTimer() {
	Interval = new TimeSpan().FromMilliseconds(20)
	setTickEvent("advance()")
}
oTimer.Start()

wpfRun(oWindow)
dnAssert("filled",oBar.Value,100)
dnAssert("text",oText.Content,"Done")
wpfEnd()

# --------------------------------------------------------------------------

func advance
	nPercent += 20
	oBar.Value = nPercent
	oText.Content = "" + nPercent + "%"
	if nPercent >= 100
		oTimer.Stop()
		oText.Content = "Done"
		oWindow.Close()
	ok
