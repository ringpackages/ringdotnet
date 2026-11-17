# A context (right-click) menu

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
using {
	"System.Drawing"
	"System.Windows.Forms"
}


oForm = uiForm("Context menu",300,140)
oPanel = uiPanel(oForm,15,15,265,70)
oPanel.BackColor = uiColor("Lavender")
oMenu = new ContextMenuStrip()
for cColor in ["Red","Green","Blue"]
	oItem = dnNew@("ToolStripMenuItem",[ :text = cColor ])
	oItem.setClickEvent("oPanel.BackColor = uiColor('" + cColor + "')")
	oMenu.Items.Add(oItem)
next
oPanel.ContextMenuStrip = oMenu
uiLabel(oForm,"Right-click the panel",15,95,265,24)

uiTest(oForm,"oMenu.Items.Item(2).PerformClick() dnAssert('panel is blue',oPanel.BackColor.Name,'Blue')")
uiRun(oForm)
uiEnd()
