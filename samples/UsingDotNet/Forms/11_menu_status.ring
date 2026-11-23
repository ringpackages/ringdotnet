# A menu bar and a status bar

load "dotnet.ring"

using {
	"System.Drawing"
	"System.Windows.Forms"
}

oForm = uiForm("Menu",360,200)
uiMenu(oForm,[
	["File",[["New","say('New file')"],["Open","say('Open file')"],["-",""],["Exit","oForm.Close()"]]],
	["Help",[["About","say('About this program')"]]]
])
oStatus = new StatusStrip()
oMessage = new ToolStripStatusLabel()
oMessage.Text = "Ready"
oStatus.Items.Add(oMessage)
oForm.Controls.Add(oStatus)

uiRun(oForm)

# --------------------------------------------------------------------------

func say cText

	oMessage.Text = cText
