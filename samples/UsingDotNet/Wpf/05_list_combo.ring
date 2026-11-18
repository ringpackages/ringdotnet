# A list box and a combo box with selection events

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


cPicked = ""
oWindow = wpfWindow("Lists",320,240)
oPanel = new StackPanel()
oWindow.Content = oPanel
oList = new WpfListBox()
oCombo = new WpfComboBox()
for cName in ["Ring","Python","Lua"]
	oList.Items.Add(cName)
	oCombo.Items.Add(cName)
next
oList.setSelectionChangedEvent("cPicked = 'list:' + oList.SelectedItem")
oCombo.setSelectionChangedEvent("cPicked = 'combo:' + oCombo.SelectedItem")
oPanel {
	Children.Add(oList)
	Children.Add(oCombo)
}

wpfTest(oWindow,"oList.SelectedIndex = 1 dnAssert('list',cPicked,'list:Python') oCombo.SelectedIndex = 2 dnAssert('combo',cPicked,'combo:Lua') dnAssert('count',oList.Items.Count,3)")
wpfRun(oWindow)
wpfEnd()
