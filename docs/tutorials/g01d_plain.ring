# Tutorial 11, step 4: the same window without the helper functions - what uiForm, uiLabel and uiButton do
load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
using {
	"System.Drawing"
	"System.Windows.Forms"
}

oForm = ""
oLabel = ""
oButton = ""
nClicks = 0

func main
	# every control is an object of a class, configured with properties inside braces
	oForm = new Form() {
		Text = "Click counter (no helpers)"
		ClientSize = new Size(320,120)
		StartPosition = "CenterScreen"           # an enum is written as a text
	}
	oLabel = new Label() {
		Text = "The button was not clicked yet"
		Location = new Point(20,15)
		Size = new Size(280,24)
	}
	oButton = new Button() {
		Text = "Click me"
		Location = new Point(20,55)
		Size = new Size(120,32)
		setClickEvent("clicked()")                # an event: Ring code that runs on click
	}
	oForm.Controls.Add(oLabel)
	oForm.Controls.Add(oButton)

	uiTest(oForm,"oButton.PerformClick() dnAssert('one click',oLabel.Text,'Clicked 1 times')")
	new Application().EnableVisualStyles()
	new Application().Run(oForm)                  # the message loop: the program waits for the user here
	uiEnd()

func clicked
	nClicks++
	oLabel.Text = "Clicked " + nClicks + " times"
