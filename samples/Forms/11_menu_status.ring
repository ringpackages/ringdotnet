# A menu bar and a status bar

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
dnImport("System.Drawing")
dnImport("System.Windows.Forms")


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

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

# --------------------------------------------------------------------------

func say cText
	oMessage.Text = cText

func selfTest
	oMenuItem = oForm.MainMenuStrip.Items.Item(0).DropDownItems.Item(1)
	oMenuItem.PerformClick()
	dnAssert("menu click",oMessage.Text,"Open file")
	dnAssert("menu count",oForm.MainMenuStrip.Items.Count,2)
