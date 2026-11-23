# Calculator - a port of ring/applications/calculator to RingDotNet (Windows Forms)

load "dotnet.ring"

using {
	"System.Drawing"
	"System.Windows.Forms"
}

cDisplay = "0"		# the number being typed or the result
nAccumulator = 0	# the left operand
cOperator = ""		# + - * /
lFresh = true		# the next digit starts a new number
cHistory = ""

oForm = uiForm("Calculator",280,380)
oForm {
	KeyPreview = True
	FormBorderStyle = "FixedSingle"
	MaximizeBox = False
}

oHistory = uiLabel(oForm,"",10,8,260,18)
oHistory {
	TextAlign = "MiddleRight"
	ForeColor = uiColor("Gray")
}

oScreen = uiTextBox(oForm,10,30,260,50)
oScreen {
	ReadOnly = True
	TextAlign = "Right"
	Font = uiFont("Segoe UI",24,false)
	Text = "0"
}

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

# typing on the keyboard works too: characters arrive in KeyPress, Enter / Escape / Backspace in KeyDown
# (uiInputKeys: a focused button would take Enter and press itself again)
uiInputKeys(oForm)
oForm {
	setKeyPressEvent("keyTyped(aDotNetArgs[2])")
	setKeyDownEvent("specialKey(aDotNetArgs[2])")
}

uiRun(oForm)

# --------------------------------------------------------------------------

func keyTyped oArgs

	cChar = oArgs.KeyChar
	if find(["0","1","2","3","4","5","6","7","8","9",".","+","-","*","/","%"],cChar) > 0
		press(cChar)
		oArgs.Handled = True
	but cChar = "="
		press("=")
		oArgs.Handled = True
	but cChar = "c" or cChar = "C"
		press("C")
		oArgs.Handled = True
	ok

func specialKey oArgs

	cKey = oArgs.KeyCode
	if cKey = "Return" or cKey = "Enter"
		press("=")
	but cKey = "Escape"
		press("C")
	but cKey = "Back"
		backspace()
	else
		return
	ok
	oArgs {
		Handled = True
		SuppressKeyPress = True
	}

func backspace

	if not lFresh and len(cDisplay) > 0
		cDisplay = left(cDisplay,len(cDisplay) - 1)
		if cDisplay = "" or cDisplay = "-"
			cDisplay = "0"
			lFresh = true
		ok
		oScreen.Text = cDisplay
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
