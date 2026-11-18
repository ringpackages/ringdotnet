load "dotnet.ring"
dnUseDesktop()                      # must be the first .NET call
using { "System.Windows.Forms" }

# Windows Forms: the Ring thread runs the message loop, so event code runs on it.
# This sample closes itself: the Shown event "clicks" the button, whose Click event updates the label and closes the form.

oApp = new Application()
oApp.EnableVisualStyles()

oForm = new Form() {
	Text = "RingDotNet - Click event"
	Width = 360
	Height = 160
}

oLabel = new Label() {
	Text = "Waiting for a click..."
	Left = 20  oLabel.Top = 20  oLabel.Width = 300
}

oButton = new Button() {
	Text = "Click me"
	Left = 20  oButton.Top = 60
}

nClicks = 0
oButton.setClickEvent("nClicks++ oLabel.Text = 'Clicked ' + nClicks + ' time(s)' ? 'Click event: ' + oLabel.Text oForm.Close()")

oForm {
	Controls.Add(oLabel)
	Controls.Add(oButton)
}

# Remove this line to use the form yourself (click the button, then close the window)
oForm.setShownEvent("oButton.PerformClick()")

oApp.Run(oForm)
? "Form closed, clicks = " + nClicks
