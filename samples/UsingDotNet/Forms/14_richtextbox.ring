# Formatting the selected text of a rich text box

load "dotnet.ring"
using {
	"System.Drawing"
	"System.Windows.Forms"
}

oForm = uiForm("Rich text",420,200)
oRich = new RichTextBox()
oRich.Dock = "Fill"
oForm.Controls.Add(oRich)
oRich.Text = "Ring and .NET make a good team"

uiRun(oForm)

# --------------------------------------------------------------------------
