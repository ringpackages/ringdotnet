load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()                      # must be the first .NET call
dnImport("System.Windows.Forms")

# Windows Forms: the Ring thread runs the message loop, so event code runs on it.
# This sample closes itself: the Shown event "clicks" the button, whose Click event updates the label and closes the form.

oApp = new Application()
oApp.EnableVisualStyles()

oForm = new Form()
oForm.Text = "RingDotNet - Click event"
oForm.Width = 360
oForm.Height = 160

oLabel = new Label()
oLabel.Text = "Waiting for a click..."
oLabel.Left = 20  oLabel.Top = 20  oLabel.Width = 300

oButton = new Button()
oButton.Text = "Click me"
oButton.Left = 20  oButton.Top = 60

nClicks = 0
oButton.setClickEvent("nClicks++ oLabel.Text = 'Clicked ' + nClicks + ' time(s)' ? 'Click event: ' + oLabel.Text oForm.Close()")

oForm.Controls.Add(oLabel)
oForm.Controls.Add(oButton)

# Remove this line to use the form yourself (click the button, then close the window)
oForm.setShownEvent("oButton.PerformClick()")

oApp.Run(oForm)
? "Form closed, clicks = " + nClicks
