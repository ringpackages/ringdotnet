# A tool strip with buttons

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
dnImport("System.Drawing")
dnImport("System.Windows.Forms")


oForm = uiForm("Toolbar",360,160)
oBar = new ToolStrip()
for cName in ["New","Open","Save"]
	oTool = new ToolStripButton()
	oTool.Text = cName
	oTool.setClickEvent("oStatus.Text = 'Clicked ' + '" + cName + "'")
	oBar.Items.Add(oTool)
next
oForm.Controls.Add(oBar)
oStatus = uiLabel(oForm,"",15,50,320,24)

uiTest(oForm,"oBar.Items.Item(1).PerformClick() dnAssert('toolbar click',oStatus.Text,'Clicked Open')")
uiRun(oForm)
uiEnd()
