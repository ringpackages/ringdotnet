# closing a window - the FormClosing event: asking to save changes, cancelling the close, and what runs after the form closed
load "dotnet.ring"
using {
	"System.IO"
	"System.Drawing"
	"System.Windows.Forms"
}

# controls and state that the event code uses are global variables
oForm = ""
oEdit = ""
oStatus = ""
cFile = ""
lChanged = False                  # are there changes that are not saved?
cTestAnswer = ""                  # a test sets the answer of the question; empty = ask the user with a message box
nCloseAttempts = 0
lClosed = False

func main
	cFile = new Path().Combine([ new Path().GetTempPath(), "ringdotnet-closing.txt" ])
	oForm = uiForm("Notes",420,260)
	oEdit = uiTextBox(oForm,15,15,380,26)
	oEdit.Text = "my notes"
	uiButton(oForm,"Save",15,55,90,30,"saveNow()")
	uiButton(oForm,"Close",115,55,90,30,"oForm.Close()")
	oStatus = uiLabel(oForm,"No changes",15,100,380,24)

	oEdit.setTextChangedEvent("lChanged = True oStatus.Text = 'There are changes that are not saved'")
	oForm.setFormClosingEvent("onClosing()")             # runs BEFORE the form closes, and can stop it
	oForm.setFormClosedEvent("lClosed = True")           # runs AFTER the form closed: too late to stop it

	uiTest(oForm,"selfTest()")
	uiRun(oForm)
	uiEnd()
	cleanUp()

func saveNow
	new File().WriteAllText([ :path = cFile, :contents = oEdit.Text ])
	lChanged = False
	oStatus.Text = "Saved"

# The question: Yes = save and close, No = close without saving, Cancel = do not close. A test answers by itself.
func askSave
	if cTestAnswer != ""
		return cTestAnswer
	ok
	return new MessageBox().Show([ :text = "Save the changes?", :caption = "Notes", :buttons = "YesNoCancel", :icon = "Question" ])

# The event arguments (aDotNetArgs[2]) have Cancel: set it to True and the form stays open.
func onClosing
	nCloseAttempts++
	if not lChanged
		return                                            # nothing to save: let the form close
	ok
	cAnswer = askSave()
	if cAnswer = "Yes"
		saveNow()
	but cAnswer = "Cancel"
		aDotNetArgs[2].Cancel = True
	ok

func cleanUp
	if new File().Exists(cFile)
		new File().Delete(cFile)
	ok

func selfTest
	# no changes yet: closing would not ask anything
	dnAssert("no changes",lChanged,False)

	# a change, and the user answers Cancel: the form stays open
	oEdit.Text = "my notes, changed"
	dnAssert("the change is known",lChanged,True)
	cTestAnswer = "Cancel"
	oForm.Close()
	dnAssert("asked once",nCloseAttempts,1)
	dnAssert("not closed after Cancel",lClosed,False)
	dnAssert("the file was not written",new File().Exists(cFile),False)

	# the user answers Yes: the changes are saved, and the form closes (here the test form is closed by uiTest after this code)
	cTestAnswer = "Yes"
	oForm.Close()
	dnAssert("asked again",nCloseAttempts,2)
	dnAssert("saved on Yes",new File().ReadAllText(cFile),"my notes, changed")
	dnAssert("the form closed",lClosed,True)
	dnAssert("no changes left",lChanged,False)
