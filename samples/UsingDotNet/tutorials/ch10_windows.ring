# more than one window - a tool window next to the main window: Show with an owner, only one copy, talking between windows, closing together
load "dotnet.ring"
using {
	"System.Drawing"
	"System.Windows.Forms"
}

# the windows and the state are global variables
oForm = ""                        # the main window (uiTest closes the window in the variable oForm)
oShown = ""                       # the label of the main window that the tool window changes
oTool = ""                        # the tool window (the last one that was made)
lToolOpen = False                 # is the tool window open now?
oToolBox = ""
oToolStatus = ""
nToolOpened = 0                   # how many times a tool window was made
cApplied = ""

func main
	oForm = uiForm("Main window",420,200)
	oShown = uiLabel(oForm,"Nothing applied yet",20,20,370,28)
	uiButton(oForm,"Open the tool window",20,60,170,32,"openTool()")
	oForm.setFormClosedEvent("cApplied += '[main closed]'")

	uiRun(oForm)

# Open the tool window. A program should not open a second copy: if it is open, the function brings it to the front.
func openTool
	if lToolOpen
		oTool.Activate()
		return
	ok
	nToolOpened++
	lToolOpen = True
	oTool = uiForm("Tool window",300,150)
	oTool.StartPosition = "Manual"
	oTool.Location = new Point(oForm.Left + oForm.Width + 10,oForm.Top)
	oToolBox = uiTextBox(oTool,20,20,250,24)
	uiButton(oTool,"Apply",20,56,90,30,"applyTool()")
	oToolStatus = uiLabel(oTool,"",20,98,250,22)
	oTool.setFormClosedEvent("toolClosed()")
	# Show(owner): the window is NOT modal (the main window can still be used), but it belongs to the owner: it stays in front of it,
	# is minimized with it, and is closed with it.
	oTool.Show(oForm)

# the tool window changes the main window: one window calls a function that works with the controls of the other
func applyTool
	oShown.Text = "Applied: " + oToolBox.Text
	oToolStatus.Text = "Sent to the main window"

# The event code runs inside a method of the tool window, so it must not destroy the window object (assigning another value to oTool
# would): it only sets a flag, and the next openTool makes a new window and replaces the old object.
func toolClosed
	cApplied += "[tool closed]"
	lToolOpen = False

# the number of the open windows of the program
func openForms
	return new Application().OpenForms.Count
