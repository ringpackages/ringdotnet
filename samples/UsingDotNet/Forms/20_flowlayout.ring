# Buttons in a flow layout panel that wraps

load "dotnet.ring"
using {
	"System.Drawing"
	"System.Windows.Forms"
}

oForm = uiForm("Flow layout",300,200)
oFlow = new FlowLayoutPanel()
oFlow.Dock = "Fill"
oForm.Controls.Add(oFlow)
addButtons()

uiRun(oForm)

# --------------------------------------------------------------------------

# the loop variables live in a function: a top-level variable named like an attribute (x) would break obj.X
func addButtons
	for nButton = 1 to 12
		oButton = new Button() {
			Text = "Button " + nButton
			Size = new Size(80,28)
		}
		oFlow.Controls.Add(oButton)
	next
