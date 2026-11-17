load "../../libraries/dotnetlib/dotnetlib.ring"

# Windows Forms: the Ring thread runs the message loop, so event code runs on it.
# This sample closes itself: the Shown event "clicks" the button, whose Click event updates the label and closes the form.
dnUseDesktop()                      # must be the first .NET call

oApp = new Application()
oApp.EnableVisualStyles()

oForm = new Form()
oForm.setText("RingDotNet - Click event")
oForm.setWidth(360)
oForm.setHeight(160)

oLabel = new Label()
oLabel.setText("Waiting for a click...")
oLabel.setLeft(20)  oLabel.setTop(20)  oLabel.setWidth(300)

oButton = new Button()
oButton.setText("Click me")
oButton.setLeft(20)  oButton.setTop(60)

nClicks = 0
oButton.setClickEvent("nClicks++ oLabel.setText('Clicked ' + nClicks + ' time(s)') ? 'Click event: ' + oLabel.getText() oForm.Close()")

oForm.getControls().Add(oLabel)
oForm.getControls().Add(oButton)

# Remove this line to use the form yourself (click the button, then close the window)
oForm.setShownEvent("oButton.PerformClick()")

oApp.Run(oForm)
? "Form closed, clicks = " + nClicks
