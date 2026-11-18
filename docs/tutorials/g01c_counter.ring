# Tutorial 11, step 3: the button does something - events and global variables
load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
using {
	"System.Drawing"
	"System.Windows.Forms"
}

# The code of an event runs later, outside this part of the program: it can only see GLOBAL variables.
# So the controls and the counter are global variables, created here at the top.
oForm = ""
oLabel = ""
nClicks = 0

func main
	oForm = uiForm("Click counter",320,120)
	oLabel = uiLabel(oForm,"The button was not clicked yet",20,15,280,24)
	uiButton(oForm,"Click me",20,55,120,32,"clicked()")      # the click calls the function clicked()
	uiButton(oForm,"Reset",150,55,80,32,"resetCount()")

	uiTest(oForm,"selfTest()")
	uiRun(oForm)
	uiEnd()

func clicked
	nClicks++
	oLabel.Text = "Clicked " + nClicks + " times"

func resetCount
	nClicks = 0
	oLabel.Text = "The button was not clicked yet"

# The same program tests itself when it is started with --selftest
func selfTest
	oForm.Controls.Item(1).PerformClick()
	oForm.Controls.Item(1).PerformClick()
	oForm.Controls.Item(1).PerformClick()
	dnAssert("three clicks",oLabel.Text,"Clicked 3 times")
	oForm.Controls.Item(2).PerformClick()
	dnAssert("reset",oLabel.Text,"The button was not clicked yet")
