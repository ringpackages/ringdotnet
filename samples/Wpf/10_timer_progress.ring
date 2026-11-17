# A DispatcherTimer fills a progress bar

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
dnImport("System.Diagnostics")


nPercent = 0
oWindow = wpfWindow("Progress",320,120)
oPanel = new StackPanel()
oWindow.Content = oPanel
oBar = new WpfProgressBar()
oBar.Height = 24
oBar.Margin = new Thickness(15,15,15,15)
oBar.Maximum = 100
oPanel.Children.Add(oBar)
oText = wpfLabel("0%")
oPanel.Children.Add(oText)
oTimer = new DispatcherTimer()
oTimer.Interval = new TimeSpan().FromMilliseconds(20)
oTimer.setTickEvent("advance()")
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
