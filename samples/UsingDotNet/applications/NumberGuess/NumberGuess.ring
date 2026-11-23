# Guess the number between 1 and 100 - higher/lower hints and an attempts counter

load "dotnet.ring"

using {
	"System.Drawing"
	"System.Windows.Forms"
}

nSecret = 0
nAttempts = 0
nBest = 0

oForm = uiForm("Guess the number",340,250)
oForm {
	FormBorderStyle = "FixedDialog"
	MaximizeBox = False
}
uiLabel(oForm,"I am thinking of a number between 1 and 100",15,15,310,22)
oGuess = new NumericUpDown() {
	Location = new Point(15,50)
	Size = new Size(90,26)
	Minimum = 1
	Maximum = 100
	Value = 50
}
oForm.Controls.Add(oGuess)
uiButton(oForm,"Guess",115,48,90,30,"guess()")
uiButton(oForm,"New game",215,48,100,30,"newGame()")
oHint = uiLabel(oForm,"",15,95,310,40)
oHint.Font = uiFont("Segoe UI",13,true)
oHistory = uiListBox(oForm,15,140,310,95)
newGame()

uiRun(oForm)

# --------------------------------------------------------------------------

func newGame

	nSecret = random(99) + 1
	nAttempts = 0
	oHint.Text = "Take a guess"
	oHistory.Items.Clear()
	oGuess.Value = 50

func guess

	nNumber = number(oGuess.Value)
	nAttempts++
	if nNumber < nSecret
		cResult = "too low"
	but nNumber > nSecret
		cResult = "too high"
	else
		cResult = "correct"
	ok
	oHistory.Items.Insert(0,"" + nAttempts + ". " + nNumber + " is " + cResult)
	if cResult = "correct"
		oHint.Text = "Yes! " + nNumber + " in " + nAttempts + " attempts"
		if nBest = 0 or nAttempts < nBest
			nBest = nAttempts
		ok
	else
		oHint.Text = "Try a number that is " + substr(cResult,"too ","") + "er"
	ok
