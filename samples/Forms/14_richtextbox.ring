# Formatting the selected text of a rich text box

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
dnImport("System.Drawing")
dnImport("System.Windows.Forms")


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
	oRich.Select_2(0,4)
	oRich.SelectionColor = uiColor("Red")
	oBoldFont = uiFont("Segoe UI",14,true)
	oRich.SelectionFont = oBoldFont
	oRich.Select_2(9,4)
	oRich.SelectionColor = uiColor("Blue")
	oRich.Select_2(0,0)
	dnAssert("text is kept",oRich.Text,"Ring and .NET make a good team")
	oRich.Select_2(1,1)
	dnAssert("first word is red",oRich.SelectionColor.Name,"Red")
	dnAssert("rtf has formatting",substr(oRich.Rtf,"\b") > 0,1)
