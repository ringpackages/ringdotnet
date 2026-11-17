# Password generator - uses the .NET cryptographic random number generator

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
dnImport("System")
dnImport("System.Security.Cryptography")
dnImport("System.Drawing")
dnImport("System.Windows.Forms")

oForm = uiForm("Password generator",380,260)
oForm.FormBorderStyle = "FixedDialog"
oForm.MaximizeBox = 0
oPassword = uiTextBox(oForm,15,15,350,32)
oPassword.Font = uiFont("Consolas",14,false)
oPassword.ReadOnly = 1
uiLabel(oForm,"Length",15,62,50,22)
oLength = new NumericUpDown()
oLength.Location = new Point(70,60)
oLength.Size = new Size(60,26)
oLength.Minimum = 4
oLength.Maximum = 64
oLength.Value = 16
oForm.Controls.Add(oLength)
oLower = uiCheckBox(oForm,"abc",150,60,60,24,"")
oUpper = uiCheckBox(oForm,"ABC",210,60,60,24,"")
oDigits = uiCheckBox(oForm,"123",270,60,60,24,"")
oSymbols = uiCheckBox(oForm,"!@#",150,90,70,24,"")
oLower.Checked = 1
oUpper.Checked = 1
oDigits.Checked = 1
oSymbols.Checked = 1
uiButton(oForm,"Generate",15,130,110,34,"generate()")
uiButton(oForm,"Copy",135,130,80,34,"copyIt()")
oStrength = new ProgressBar()
oStrength.Location = new Point(15,185)
oStrength.Size = new Size(350,18)
oStrength.Maximum = 100
oForm.Controls.Add(oStrength)
oStrengthText = uiLabel(oForm,"",15,210,350,24)
generate()

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

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

func selfTest
	dnAssert("default length",len(oPassword.Text),16)
	dnAssert("strong by default",oStrengthText.Text,"Strong")
	oLength.Value = 30
	generate()
	dnAssert("longer password",len(oPassword.Text),30)
	oUpper.Checked = 0
	oDigits.Checked = 0
	oSymbols.Checked = 0
	oLength.Value = 20
	generate()
	dnAssert("only lower case",hasAny(oPassword.Text,"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#"),0)
	dnAssert("lower case letters present",hasAny(oPassword.Text,"abcdefghijklmnopqrstuvwxyz"),1)
	oLength.Value = 4
	generate()
	dnAssert("short and simple is weak",oStrengthText.Text,"Weak")
	oLower.Checked = 0
	generate()
	dnAssert("no characters selected",oStrengthText.Text,"Choose at least one kind of characters")
	dnAssert("the random numbers are in range",secureRandom(10) < 10,1)
	nSeen = ""
	for x = 1 to 200
		nSeen += "" + secureRandom(3)
	next
	dnAssert("all values appear",substr(nSeen,"0") > 0 and substr(nSeen,"1") > 0 and substr(nSeen,"2") > 0,1)
