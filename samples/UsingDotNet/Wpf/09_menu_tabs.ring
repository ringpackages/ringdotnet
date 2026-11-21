# A menu and tab pages

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

cLast = ""
oWindow = wpfWindow("Menu and tabs",360,240)
oDock = new DockPanel()
oWindow.Content = oDock
oMenu = new Menu()
oFile = new MenuItem()
oFile.Header = "File"
oOpen = new MenuItem() {
	Header = "Open"
	setClickEvent("cLast = 'open'")
}
oFile.Items.Add(oOpen)
oMenu.Items.Add(oFile)
oDock.Children.Add(oMenu)
oDock.SetDock(oMenu,"Top")
oTabs = new WpfTabControl()
for cName in ["First","Second"]
	oTab = new TabItem() {
		Header = cName
		Content = wpfLabel("Page " + cName)
	}
	oTabs.Items.Add(oTab)
next
oDock.Children.Add(oTabs)

wpfRun(oWindow)
