# Your first window, step 2: a label and a button
load "dotnet.ring"
using {
	"System.Drawing"
	"System.Windows.Forms"
}

oForm = uiForm("Click counter",320,120)
oLabel = uiLabel(oForm,"The button was not clicked yet",20,15,280,24)      # parent, text, x, y, width, height
oButton = uiButton(oForm,"Click me",20,55,120,32,"")                       # no code yet for the click

uiRun(oForm)
