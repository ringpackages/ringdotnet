# Tutorial 40: your own dialog - a modal form that asks for data and gives it back
load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
using {
	"System.Drawing"
	"System.Windows.Forms"
}

# the main window
oForm = ""
oShow = ""
cName = "Ann"
nAge = 31

# the dialog and its controls (the dialog code is run by events, so they are global too)
oDialog = ""
oNameBox = ""
oAgeBox = ""
oError = ""
oOk = ""
oTimer = ""
nStep = 0                       # which step of the test is next
cNextName = ""

func main
	oForm = uiForm("Profile",340,150)
	oShow = uiLabel(oForm,"",20,20,300,50)
	oShow.Font = new Font("Segoe UI",12)
	uiButton(oForm,"Edit profile...",20,90,130,32,"editProfile()")
	showProfile()

	uiTest(oForm,"selfTest()")
	uiRun(oForm)
	uiEnd()

func showProfile
	oShow.Text = cName + nl + nAge + " years old"

# The main window asks the dialog and uses the answer only when the user pressed OK
func editProfile
	aAnswer = askProfile(cName,nAge)
	if islist(aAnswer)
		cName = aAnswer[1]
		nAge = aAnswer[2]
		showProfile()
	ok

# ---------------------------------------------------------------- the dialog
# Returns [name, age] when the user presses OK, or "" when the dialog is cancelled.
func askProfile cStartName, nStartAge
	oDialog = new Form() {
		Text = "Edit profile"
		ClientSize = new Size(300,150)
		StartPosition = "CenterParent"
		FormBorderStyle = "FixedDialog"           # a dialog is not resizable
		MaximizeBox = False
		MinimizeBox = False
	}
	uiLabel(oDialog,"Name",15,18,60,22)
	oNameBox = uiTextBox(oDialog,80,16,200,24)
	oNameBox.Text = cStartName
	uiLabel(oDialog,"Age",15,52,60,22)
	oAgeBox = new NumericUpDown() {
		Location = new Point(80,50)
		Size = new Size(70,24)
		Minimum = 0
		Maximum = 130
		Value = nStartAge
	}
	oDialog.Controls.Add(oAgeBox)
	oError = uiLabel(oDialog,"",15,82,270,20)
	oError.ForeColor = new Color().Crimson

	oOk = uiButton(oDialog,"OK",120,112,80,28,"okPressed()")
	oCancel = uiButton(oDialog,"Cancel",206,112,80,28,"")
	# the dialog knows its default buttons: Enter presses OK, Escape presses Cancel
	oDialog.AcceptButton = oOk
	oDialog.CancelButton = oCancel
	oCancel.DialogResult = "Cancel"                # a button with a DialogResult closes the dialog by itself

	if uiSelfTest()
		oTimer = uiTimer(150,"driveDialog()")      # in a test a timer works inside the dialog, as the user would
		oTimer.Start()
	ok
	cResult = oDialog.ShowDialog(NULL)             # shows the dialog and WAITS until it is closed: "OK" or "Cancel"
	if cResult = "OK"
		aAnswer = [trim(oNameBox.Text),oAgeBox.Value]
	else
		aAnswer = ""
	ok
	oDialog.Dispose()
	return aAnswer

# OK checks the input: an invalid input keeps the dialog open and says why
func okPressed
	if trim(oNameBox.Text) = ""
		oError.Text = "Please type a name"
		oNameBox.Focus()
		return
	ok
	oDialog.DialogResult = "OK"                    # setting the result closes the dialog

# ---------------------------------------------------------------- tests: a timer acts as the user in the dialog

func driveDialog
	nStep++
	if nStep = 1
		oNameBox.Text = "   "                     # first an invalid name: the dialog must stay open
		oOk.PerformClick()
		dnAssert("the dialog complained",oError.Text,"Please type a name")
	but nStep = 2
		oNameBox.Text = cNextName
		oAgeBox.Value = 44
		oOk.PerformClick()
		oTimer.Stop()
	ok

func selfTest
	cNextName = "Bob"
	nStep = 0
	editProfile()
	dnAssert("the answer was used",cName,"Bob")
	dnAssert("the age was used",nAge,44)
	dnAssert("shown in the window",oShow.Text,"Bob" + nl + "44 years old")
