# formatted text - RichTextBox: bold and colored words, searching, saving as RTF and loading it again
load "dotnet.ring"

using {
	"System"
	"System.IO"
	"System.Drawing"
	"System.Windows.Forms"
}

# controls that the event code uses are global variables
oForm = ""
oRich = ""
oStatus = ""
oBold = ""
oFind = ""

func main

	oForm = uiForm("Formatted text",520,360)
	oBold = uiButton(oForm,"Bold",15,12,70,28,"toggleBold()")
	uiButton(oForm,"Red",92,12,70,28,"makeRed()")
	uiButton(oForm,"Plain",169,12,70,28,"makePlain()")
	oFind = uiTextBox(oForm,260,14,110,24)
	oFind.Text = "ring"
	uiButton(oForm,"Find all",378,12,80,28,"findAll()")

	# a RichTextBox is a text box whose text can have a font, a size, a color and more for each part
	oRich = new RichTextBox()
	oRich.Location = new Point(15,52)
	oRich.Size = new Size(485,230)
	oRich.Font = new Font("Segoe UI",11)
	oRich.Text = "Ring talks to .NET. The ring program writes in a rich text box: some words are bold and some are red."
	oForm.Controls.Add(oRich)
	oStatus = uiLabel(oForm,"Select some text, then click a button",15,292,480,24)

	uiRun(oForm)

# the font of the selection: uiFont(family, size, bold). The same family and size, only the bold changes.
func setBold lBold

	oRich.SelectionFont = uiFont("Segoe UI",11,lBold)

func toggleBold

	if oRich.SelectionLength = 0
		oStatus.Text = "Select some text first"
		return
	but oRich.SelectionFont.Bold
		setBold(False)
	else
		setBold(True)
	ok
	oStatus.Text = "Bold: " + oRich.SelectionFont.Bold

func makeRed

	oRich.SelectionColor = uiColor("Red")

func makePlain

	setBold(False)
	oRich.SelectionColor = uiColor("Black")

# Find searches from a start place; the loop finds every match and marks it. The options "None" ignore upper and lower case; "MatchCase"
# would not.
func findAll

	cWord = oFind.Text
	nCount = 0
	nStart = 0
	while len(cWord) > 0
		nPlace = oRich.Find([ :str = cWord, :start = nStart, :options = "None" ])
		if nPlace < 0
			exit
		ok
		oRich.Select([ :start = nPlace, :length = len(cWord) ])
		oRich.SelectionBackColor = dnStatic("System.Drawing.Color","FromArgb",[ 255, 255, 235, 120 ])
		nCount++
		nStart = nPlace + len(cWord)
	end
	oRich.Select([ :start = 0, :length = 0 ])
	oStatus.Text = "Found " + nCount + " times"
