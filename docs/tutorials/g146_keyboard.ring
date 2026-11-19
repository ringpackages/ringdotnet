# the keyboard in a form - KeyPress to allow only digits, the Enter and Escape buttons, the tab order, the access keys and select-all
load "dotnet.ring"
using {
	"System.Drawing"
	"System.Windows.Forms"
}

# controls and state that the event code uses are global variables
oForm = ""
oName = ""
oAge = ""
oOk = ""
oCancel = ""
oResult = ""
nRejected = 0                     # how many keys the age box refused
lClosed = False

func main
	oForm = uiForm("Keyboard",360,230)

	# An ACCESS KEY: the & in front of a letter underlines it, and Alt + that letter moves the focus to the NEXT control in the tab order
	# (a label cannot take the focus itself). So the label comes just before its text box.
	uiLabel(oForm,"&Name",20,22,80,22)
	oName = uiTextBox(oForm,110,20,220,24)
	uiLabel(oForm,"&Age",20,58,80,22)
	oAge = uiTextBox(oForm,110,56,60,24)
	oAge.MaxLength = 3                                   # at most 3 characters, whatever is typed or pasted

	# KeyPress runs for each character that is typed, before it reaches the text box. Handled = True throws the character away.
	oAge.setKeyPressEvent("filterKey(aDotNetArgs[2])")

	oOk = uiButton(oForm,"OK",110,100,90,30,"accept()")
	oCancel = uiButton(oForm,"Cancel",210,100,90,30,"oForm.Close()")
	# Enter presses the AcceptButton from any control, and Escape presses the CancelButton: the two keys that every dialog has
	oForm.AcceptButton = oOk
	oForm.CancelButton = oCancel
	oResult = uiLabel(oForm,"",20,150,320,44)
	oForm.setFormClosedEvent("lClosed = True")

	# the first control with the focus, and the select-all of the text when the user comes to a box with Tab
	oName.TabIndex = 1
	oAge.TabIndex = 2
	oOk.TabIndex = 3
	oCancel.TabIndex = 4
	oName.setEnterEvent("oName.SelectAll()")
	oAge.setEnterEvent("oAge.SelectAll()")

	uiTest(oForm,"selfTest()")
	uiRun(oForm)
	uiEnd()

# The argument of KeyPress has KeyChar (the character) and Handled. Digits and the Backspace key are accepted; everything else is refused.
func filterKey oArgs
	cChar = oArgs.KeyChar
	nCode = ascii(cChar)
	lDigit = nCode >= 48 and nCode <= 57
	lBackspace = nCode = 8
	if not lDigit and not lBackspace
		oArgs.Handled = True
		nRejected++
	ok

func accept
	if trim(oName.Text) = "" or oAge.Text = ""
		oResult.Text = "Please fill in both boxes"
		return
	ok
	oResult.Text = trim(oName.Text) + " is " + oAge.Text + " years old"

func selfTest
	# the keys go to the box that has the focus, through the real key processing
	oForm.ActiveControl = oAge
	uiSendKeys(oForm,"1a2-3")
	dnAssert("only digits",oAge.Text,"123")
	dnAssert("the other keys were refused",nRejected,2)

	# MaxLength: a fourth digit is not accepted
	uiSendKeys(oForm,"9")
	dnAssert("at most three characters",oAge.Text,"123")

	# Backspace works, because the filter lets it through
	uiSendKeys(oForm,"{BACKSPACE}")
	dnAssert("backspace",oAge.Text,"12")

	# Enter presses the OK button (the AcceptButton) from any box: with the name empty the program asks for it
	oForm.ActiveControl = oAge
	uiSendKeys(oForm,"{ENTER}")
	dnAssert("an empty name",oResult.Text,"Please fill in both boxes")
	oForm.ActiveControl = oName
	uiSendKeys(oForm,"ann{ENTER}")           # the test keys are lower case letters
	dnAssert("the result",oResult.Text,"ann is 12 years old")

	# the tab order: Tab goes name -> age -> OK
	oForm.ActiveControl = oName
	uiSendKeys(oForm,"{TAB}")
	dnAssert("tab to the age box",oForm.ActiveControl.TabIndex,2)

	# Escape presses the CancelButton: the form closes
	uiSendKeys(oForm,"{ESC}")
	dnAssert("escape closed the form",lClosed,True)
