# Color mixer - three track bars, the color, its #RRGGBB code and HSV values

load "dotnet.ring"
dnUseDesktop()
using {
	"System.Drawing"
	"System.Windows.Forms"
}

aBars = []
aValues = []

oForm = uiForm("Color mixer",420,260)
oForm {
	FormBorderStyle = "FixedDialog"
	MaximizeBox = False
}
nY = 15
for cName in ["Red","Green","Blue"]
	uiLabel(oForm,cName,15,nY + 4,50,22)
	oBar = new TrackBar() {
		Location = new Point(70,nY)
		Size = new Size(200,40)
		Minimum = 0
		Maximum = 255
		TickFrequency = 32
		setScrollEvent("mix()")
		setValueChangedEvent("mix()")
	}
	oForm.Controls.Add(oBar)
	aBars + oBar
	aValues + uiLabel(oForm,"0",280,nY + 4,40,22)
	nY += 50
next
oSwatch = uiPanel(oForm,15,170,120,70)
oSwatch.BorderStyle = "FixedSingle"
oHex = uiTextBox(oForm,150,175,100,26)
oHex {
	ReadOnly = True
	Font = uiFont("Consolas",12,false)
}
oHsv = uiLabel(oForm,"",150,210,250,24)
uiButton(oForm,"Random",300,172,100,28,"randomColor()")
aBars[1].Value = 200
aBars[2].Value = 120
aBars[3].Value = 40

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

# --------------------------------------------------------------------------

func hex2 nValue
	cText = upper(hex(nValue))
	if len(cText) < 2
		cText = "0" + cText
	ok
	return cText

func mix
	nRed = aBars[1].Value
	nGreen = aBars[2].Value
	nBlue = aBars[3].Value
	for nIndex = 1 to 3
		aValues[nIndex].Text = "" + aBars[nIndex].Value
	next
	oColor = uiRGB(nRed,nGreen,nBlue)
	oSwatch.BackColor = oColor
	oHex.Text = "#" + hex2(nRed) + hex2(nGreen) + hex2(nBlue)
	oHsv.Text = "H " + floor(oColor.GetHue()) + "   S " + floor(oColor.GetSaturation() * 100) + "%   V " + floor(oColor.GetBrightness() * 100) + "% (HSL lightness)"

func randomColor
	for oBar in aBars
		oBar.Value = random(255)
	next

func selfTest
	aBars[1].Value = 255
	aBars[2].Value = 0
	aBars[3].Value = 0
	dnAssert("red hex",oHex.Text,"#FF0000")
	dnAssert("swatch color",oSwatch.BackColor.ToArgb(),-65536)
	dnAssert("red hue",left(oHsv.Text,3),"H 0")
	aBars[1].Value = 0
	aBars[2].Value = 128
	aBars[3].Value = 255
	dnAssert("mixed hex",oHex.Text,"#0080FF")
	dnAssert("value label",aValues[2].Text,"128")
	aBars[1].Value = 10
	aBars[2].Value = 10
	aBars[3].Value = 10
	dnAssert("dark gray",oHex.Text,"#0A0A0A")
	randomColor()
	dnAssert("random color has a code",len(oHex.Text),7)
