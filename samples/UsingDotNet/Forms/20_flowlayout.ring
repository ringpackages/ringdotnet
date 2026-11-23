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

# adds twelve buttons to the flow panel; they wrap to the next row when the row is full
func addButtons

	for nButton = 1 to 12
		oButton = new Button() {
			Text = "Button " + nButton
			Size = new Size(80,28)
		}
		oFlow.Controls.Add(oButton)
	next
