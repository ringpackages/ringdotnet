# Password generator - uses the .NET cryptographic random number generator

load "dotnet.ring"

using {
	"System"
	"System.Security.Cryptography"
	"System.Drawing"
	"System.Windows.Forms"
}

oForm = uiForm("Password generator",380,260)
oForm {
	FormBorderStyle = "FixedDialog"
	MaximizeBox = False
}
oPassword = uiTextBox(oForm,15,15,350,32)
oPassword {
	Font = uiFont("Consolas",14,false)
	ReadOnly = True
}
uiLabel(oForm,"Length",15,62,50,22)
oLength = new NumericUpDown() {
	Location = new Point(70,60)
	Size = new Size(60,26)
	Minimum = 4
	Maximum = 64
	Value = 16
}
oForm.Controls.Add(oLength)
oLower = uiCheckBox(oForm,"abc",150,60,60,24,"")
oUpper = uiCheckBox(oForm,"ABC",210,60,60,24,"")
oDigits = uiCheckBox(oForm,"123",270,60,60,24,"")
oSymbols = uiCheckBox(oForm,"!@#",150,90,70,24,"")
oLower.Checked = True
oUpper.Checked = True
oDigits.Checked = True
oSymbols.Checked = True
uiButton(oForm,"Generate",15,130,110,34,"generate()")
uiButton(oForm,"Copy",135,130,80,34,"copyIt()")
oStrength = new ProgressBar() {
	Location = new Point(15,185)
	Size = new Size(350,18)
	Maximum = 100
}
oForm.Controls.Add(oStrength)
oStrengthText = uiLabel(oForm,"",15,210,350,24)
generate()

uiRun(oForm)

# --------------------------------------------------------------------------

func alphabet

	cChars = ""
	if oLower.Checked cChars += "abcdefghijklmnopqrstuvwxyz" ok
	if oUpper.Checked cChars += "ABCDEFGHIJKLMNOPQRSTUVWXYZ" ok
	if oDigits.Checked cChars += "0123456789" ok
	if oSymbols.Checked cChars += "!@#$%^&*()-_=+[]{};:,.?" ok
	return cChars

# a random number from 0 to nMax - 1 taken from the operating system's random generator
func secureRandom nMax

	return new RandomNumberGenerator().GetInt32(nMax)

func strength cPassword

	nScore = len(cPassword) * 4
	nClasses = 0
	if hasAny(cPassword,"abcdefghijklmnopqrstuvwxyz") nClasses++ ok
	if hasAny(cPassword,"ABCDEFGHIJKLMNOPQRSTUVWXYZ") nClasses++ ok
	if hasAny(cPassword,"0123456789") nClasses++ ok
	if hasAny(cPassword,"!@#$%^&*()-_=+[]{};:,.?") nClasses++ ok
	nScore += nClasses * 10
	if nScore > 100
		nScore = 100
	ok
	return nScore

func hasAny cText, cChars

	for x = 1 to len(cText)
		if substr(cChars,cText[x])
			return true
		ok
	next
	return false

func generate

	cChars = alphabet()
	if cChars = ""
		oPassword.Text = ""
		oStrengthText.Text = "Choose at least one kind of characters"
		oStrength.Value = 0
		return
	ok
	cPassword = ""
	for x = 1 to number(oLength.Value)
		cPassword += cChars[secureRandom(len(cChars)) + 1]
	next
	oPassword.Text = cPassword
	nScore = strength(cPassword)
	oStrength.Value = nScore
	if nScore < 50
		oStrengthText.Text = "Weak"
	but nScore < 80
		oStrengthText.Text = "Good"
	else
		oStrengthText.Text = "Strong"
	ok

func copyIt

	if oPassword.Text != "" and not uiSelfTest()
		new Clipboard().SetText(oPassword.Text)
	ok
