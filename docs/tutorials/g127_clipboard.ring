# the clipboard - text, a table for a spreadsheet, a picture, and leaving the clipboard as the user had it
load "dotnet.ring"
using {
	"System.Drawing"
	"System.Windows.Forms"
}

# controls and state that the event code uses are global variables
oForm = ""
oEdit = ""
oStatus = ""
oPicture = ""
aTable = [ ["Item","Price"], ["Tea","2.50"], ["Coffee","3.20"], ["Juice","4.00"] ]
cBefore = ""

func main
	oForm = uiForm("Clipboard",420,300)
	oEdit = uiTextBox(oForm,15,15,380,26)
	oEdit.Text = "Copied from Ring"
	uiButton(oForm,"Copy text",15,55,110,30,"copyText()")
	uiButton(oForm,"Paste text",135,55,110,30,"pasteText()")
	uiButton(oForm,"Copy table",255,55,110,30,"copyTable()")
	uiButton(oForm,"Copy picture",15,95,110,30,"copyPicture()")
	uiButton(oForm,"Clear",135,95,110,30,"clearClipboard()")
	oPicture = uiPictureBox(oForm,15,140,120,80)
	oPicture.Image = makePicture()
	oStatus = uiLabel(oForm,"Ready",15,235,380,24)

	uiTest(oForm,"selfTest()")
	uiRun(oForm)
	uiEnd()

# --------------------------------------------------------------------------
# The clipboard is shared by all programs, so a program that uses it for its own work (a test, for example) puts back what it found.

# 1. Text. SetText puts a text on the clipboard; GetText reads it (it needs NULL: the method has a second form). ContainsText asks first.
func copyText
	oClipboard = new Clipboard()
	oClipboard.SetText(oEdit.Text)
	oStatus.Text = "Copied " + len(oEdit.Text) + " characters"

func pasteText
	oClipboard = new Clipboard()
	if oClipboard.ContainsText(NULL)
		oEdit.Text = oClipboard.GetText(NULL)
		oStatus.Text = "Pasted"
	else
		oStatus.Text = "The clipboard has no text"
	ok

# 2. A table for a spreadsheet. Excel, LibreOffice and others paste text with TABS between the columns and a new line between the rows as
#    a table of cells: the program only has to make that text.
func copyTable
	cText = ""
	for aRow in aTable
		cText += aRow[1] + char(9) + aRow[2] + nl
	next
	oClipboard = new Clipboard()
	oClipboard.SetText(cText)
	oStatus.Text = "Copied a table of " + len(aTable) + " rows"

# 3. A picture. SetImage puts a bitmap on the clipboard; other programs paste it as a picture.
func copyPicture
	oClipboard = new Clipboard()
	oClipboard.SetImage(oPicture.Image)
	oStatus.Text = "Copied a picture of " + oPicture.Image.Width + " x " + oPicture.Image.Height + " pixels"

func clearClipboard
	oClipboard = new Clipboard()
	oClipboard.Clear()
	oStatus.Text = "The clipboard is empty"

# a small picture made with Graphics: a blue square with a yellow circle
func makePicture
	oBitmap = new Bitmap(120,80)
	oGraphics = new Graphics().FromImage(oBitmap)
	oGraphics.Clear(dnStatic("System.Drawing.Color","FromArgb",[ 255, 40, 90, 200 ]))
	oBrush = new SolidBrush(dnStatic("System.Drawing.Color","FromArgb",[ 255, 250, 210, 40 ]))
	oGraphics.FillEllipse([ :brush = oBrush, :rect = new Rectangle(35,15,50,50) ])
	oGraphics.Dispose()
	return oBitmap

func selfTest
	oClipboard = new Clipboard()
	if oClipboard.ContainsText(NULL)
		cBefore = oClipboard.GetText(NULL)                  # keep what the user had on the clipboard
	ok

	# text: copy, change the box, paste
	oForm.Controls.Item(1).PerformClick()
	oEdit.Text = "something else"
	oForm.Controls.Item(2).PerformClick()
	dnAssert("text round trip",oEdit.Text,"Copied from Ring")
	dnAssert("text status",oStatus.Text,"Pasted")

	# the table: tabs between the cells, a new line after each row
	oForm.Controls.Item(3).PerformClick()
	cTable = oClipboard.GetText(NULL)
	dnAssert("table text",substr(cTable,char(9),"|"),"Item|Price" + nl + "Tea|2.50" + nl + "Coffee|3.20" + nl + "Juice|4.00" + nl)

	# the picture
	oForm.Controls.Item(4).PerformClick()
	dnAssert("has image",oClipboard.ContainsImage(),True)
	dnAssert("image size",oClipboard.GetImage().Width,120)

	# clear: nothing left, and pasting says so
	oForm.Controls.Item(5).PerformClick()
	dnAssert("has no text",oClipboard.ContainsText(NULL),False)
	oForm.Controls.Item(2).PerformClick()
	dnAssert("paste of nothing",oStatus.Text,"The clipboard has no text")

	if cBefore != ""
		oClipboard.SetText(cBefore)                         # put it back
	ok
