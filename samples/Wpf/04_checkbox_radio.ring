# Check box and radio buttons with their events

load "dotnetlib.ring"
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


cLog = ""
oWindow = wpfWindow("Choices",320,220)
oPanel = new StackPanel()
oWindow.Content = oPanel
oCheck = new WpfCheckBox() {
	Content = "Enable logging"
	setCheckedEvent("cLog += 'on '")
	setUncheckedEvent("cLog += 'off '")
}
oPanel.Children.Add(oCheck)
aRadios = []
for cName in ["Small","Medium","Large"]
	oRadio = new WpfRadioButton()
	oRadio.Content = cName
	oPanel.Children.Add(oRadio)
	aRadios + oRadio
next

wpfTest(oWindow,"oCheck.IsChecked = True oCheck.IsChecked = False dnAssert('events',cLog,'on off ') aRadios[2].IsChecked = True aRadios[3].IsChecked = True dnAssert('exclusive',aRadios[2].IsChecked,0) dnAssert('selected',aRadios[3].IsChecked,1)")
wpfRun(oWindow)
wpfEnd()
