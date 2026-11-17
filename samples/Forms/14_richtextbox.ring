# Formatting the selected text of a rich text box

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
using {
	"System.Drawing"
	"System.Windows.Forms"
}


oForm = uiForm("Rich text",420,200)
oRich = new RichTextBox()
oRich.Dock = "Fill"
oForm.Controls.Add(oRich)
oRich.Text = "Ring and .NET make a good team"

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

# --------------------------------------------------------------------------

func selfTest
	oRich.SelectWith([ :start = 0, :length = 4 ])
	oRich.SelectionColor = uiColor("Red")
	oBoldFont = uiFont("Segoe UI",14,true)
	oRich.SelectionFont = oBoldFont
	oRich.SelectWith([ :start = 9, :length = 4 ])
	oRich.SelectionColor = uiColor("Blue")
	oRich.SelectWith([ :start = 0, :length = 0 ])
	dnAssert("text is kept",oRich.Text,"Ring and .NET make a good team")
	oRich.SelectWith([ :start = 1, :length = 1 ])
	dnAssert("first word is red",oRich.SelectionColor.Name,"Red")
	dnAssert("rtf has formatting",substr(oRich.Rtf,"\b") > 0,True)
