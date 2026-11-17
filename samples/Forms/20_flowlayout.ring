# Buttons in a flow layout panel that wraps

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
dnImport("System.Drawing")
dnImport("System.Windows.Forms")


oForm = uiForm("Flow layout",300,200)
oFlow = new FlowLayoutPanel()
oFlow.Dock = "Fill"
oForm.Controls.Add(oFlow)
for x = 1 to 12
	oButton = new Button()
	oButton.Text = "Button " + x
	oButton.Size = new Size(80,28)
	oFlow.Controls.Add(oButton)
next

uiTest(oForm,"dnAssert('12 buttons',oFlow.Controls.Count,12)")
uiRun(oForm)
uiEnd()
