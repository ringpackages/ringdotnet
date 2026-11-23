# A context (right-click) menu

load "dotnet.ring"

using {
	"System.Drawing"
	"System.Windows.Forms"
}

oForm = uiForm("Context menu",300,140)
oPanel = uiPanel(oForm,15,15,265,70)
oPanel.BackColor = uiColor("Lavender")
oMenu = new ContextMenuStrip()
for cColor in ["Red","Green","Blue"]
	oItem = new ToolStripMenuItem().@New([ :text = cColor ])
	oItem.setClickEvent("oPanel.BackColor = uiColor('" + cColor + "')")
	oMenu.Items.Add(oItem)
next
oPanel.ContextMenuStrip = oMenu
uiLabel(oForm,"Right-click the panel",15,95,265,24)

uiRun(oForm)
