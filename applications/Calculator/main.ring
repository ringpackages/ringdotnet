# Calculator - a port of ring/applications/calculator to RingDotNet (Windows Forms)

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
dnImport("System.Drawing")
dnImport("System.Windows.Forms")

cDisplay = "0"		# the number being typed or the result
nAccumulator = 0	# the left operand
cOperator = ""		# + - * /
lFresh = true		# the next digit starts a new number
cHistory = ""

oForm = uiForm("Calculator",280,380)
oForm.KeyPreview = 1
oForm.FormBorderStyle = "FixedSingle"
oForm.MaximizeBox = 0

oHistory = uiLabel(oForm,"",10,8,260,18)
oHistory.TextAlign = "MiddleRight"
oHistory.ForeColor = uiColor("Gray")

oScreen = uiTextBox(oForm,10,30,260,50)
oScreen.ReadOnly = 1
oScreen.TextAlign = "Right"
oScreen.Font = uiFont("Segoe UI",24,false)
oScreen.Text = "0"

aKeys = [
	["C","±","%","/"],
	["7","8","9","*"],
	["4","5","6","-"],
	["1","2","3","+"],
	["0",".","√","="]
]
for nRow = 1 to len(aKeys)
	for nCol = 1 to 4
		cKey = aKeys[nRow][nCol]
		oButton = uiButton(oForm,cKey,10 + (nCol - 1) * 65,95 + (nRow - 1) * 55,60,50,"press('" + cKey + "')")
		oButton.Font = uiFont("Segoe UI",14,false)
		if find(["/","*","-","+","="],cKey) > 0
			oButton.BackColor = uiColor("LightSteelBlue")
		ok
	next
next

# typing on the keyboard works too
oForm.setKeyPressEvent("keyTyped(aDotNetArgs[2].KeyChar)")

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

# --------------------------------------------------------------------------

func keyTyped cChar
	if find(["0","1","2","3","4","5","6","7","8","9",".","+","-","*","/","%"],cChar) > 0
		press(cChar)
	but cChar = "=" or cChar = chr(13)
		press("=")
	but cChar = "c" or cChar = "C" or cChar = chr(27)
		press("C")
	ok

func press cKey
	if find(["0","1","2","3","4","5","6","7","8","9"],cKey) > 0
		if lFresh
			cDisplay = cKey
			lFresh = false
		but len(cDisplay) < 16
			if cDisplay = "0"
				cDisplay = cKey
			else
				cDisplay += cKey
			ok
		ok
	but cKey = "."
		if lFresh
			cDisplay = "0."
			lFresh = false
		but not substr(cDisplay,".")
			cDisplay += "."
		ok
	but cKey = "C"
		cDisplay = "0"
		nAccumulator = 0
		cOperator = ""
		lFresh = true
		cHistory = ""
	but cKey = "±"
		if cDisplay != "0"
			if left(cDisplay,1) = "-"
				cDisplay = substr(cDisplay,2)
			else
				cDisplay = "-" + cDisplay
			ok
		ok
	but cKey = "%"
		cDisplay = uiNumber(number(cDisplay) / 100)
		lFresh = true
	but cKey = "√"
		if number(cDisplay) < 0
			cDisplay = "Error"
		else
			cDisplay = uiNumber(sqrt(number(cDisplay)))
		ok
		lFresh = true
	but find(["+","-","*","/"],cKey) > 0
		if cOperator != "" and not lFresh
			calculate()
		ok
		nAccumulator = number(cDisplay)
		cOperator = cKey
		cHistory = cDisplay + " " + cKey
		lFresh = true
	but cKey = "="
		if cOperator != ""
			cHistory = uiNumber(nAccumulator) + " " + cOperator + " " + cDisplay + " ="
			calculate()
			cOperator = ""
		ok
	ok
	oScreen.Text = cDisplay
	oHistory.Text = cHistory

func calculate
	nRight = number(cDisplay)
	switch cOperator
	on "+"
		nResult = nAccumulator + nRight
	on "-"
		nResult = nAccumulator - nRight
	on "*"
		nResult = nAccumulator * nRight
	on "/"
		if nRight = 0
			cDisplay = "Cannot divide by zero"
			lFresh = true
			nAccumulator = 0
			cOperator = ""
			return
		ok
		nResult = nAccumulator / nRight
	off
	cDisplay = uiNumber(nResult)
	nAccumulator = nResult
	lFresh = true

func typeKeys cKeys
	for x = 1 to len(cKeys)
		press(cKeys[x])
	next

func selfTest
	typeKeys("12+30=")
	dnAssert("12+30",oScreen.Text,"42")
	press("C")
	typeKeys("9/3=")
	dnAssert("9/3",oScreen.Text,"3")
	press("C")
	typeKeys("5*0.5=")
	dnAssert("5*0.5",oScreen.Text,"2.5")
	press("C")
	typeKeys("1+2+3=")
	dnAssert("chained",oScreen.Text,"6")
	press("C")
	typeKeys("0.1+0.2=")
	dnAssert("floating point",oScreen.Text,"0.30000000000000004")
	press("C")
	typeKeys("81")
	press("√")
	dnAssert("square root",oScreen.Text,"9")
	press("C")
	typeKeys("5/0=")
	dnAssert("division by zero",oScreen.Text,"Cannot divide by zero")
	press("C")
	typeKeys("50")
	press("%")
	dnAssert("percent",oScreen.Text,"0.5")
	press("C")
	typeKeys("7")
	press("±")
	dnAssert("sign",oScreen.Text,"-7")
	dnAssert("history shows the keys",oHistory.Text,"")
	press("C")
	# the buttons work as well
	for oControl in oForm.Controls.toList()
		if classname(oControl) = "button" and oControl.Text = "7"
			oControl.PerformClick()
			exit
		ok
	next
	dnAssert("button click",oScreen.Text,"7")
