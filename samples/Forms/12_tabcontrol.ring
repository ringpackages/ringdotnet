# Tabs with different content

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
using {
	"System.Drawing"
	"System.Windows.Forms"
}


oForm = uiForm("Tabs",360,220)
oTabs = new TabControl()
oTabs.Dock = "Fill"
for cName in ["General","Network","About"]
	oPage = new TabPage()
	oPage.Text = cName
	oTabs.TabPages.Add(oPage)
	uiLabel(oPage,"This is the " + cName + " page",15,15,300,24)
next
oForm.Controls.Add(oTabs)
oTabs.setSelectedIndexChangedEvent("oForm.Text = 'Tabs - ' + oTabs.SelectedTab.Text")

uiTest(oForm,"oTabs.SelectedIndex = 2 dnAssert('title follows the tab',oForm.Text,'Tabs - About') dnAssert('three tabs',oTabs.TabCount,3)")
uiRun(oForm)
uiEnd()
