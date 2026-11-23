# Typing quiz - type the sentence, the quiz measures the speed and the mistakes (a port of ring/applications/typingquiz)

load "dotnet.ring"
using {
	"System"
	"System.Diagnostics"
	"System.Drawing"
	"System.Windows.Forms"
}

aSentences = [
	"The quick brown fox jumps over the lazy dog",
	"Ring is a practical language for building applications",
	"Windows Forms controls can be used from Ring programs",
	"A journey of a thousand miles begins with a single step"
]
cTarget = ""
oWatch = new Stopwatch()
lStarted = false
nBest = 0

oForm = uiForm("Typing quiz",560,260)
oForm {
	FormBorderStyle = "FixedDialog"
	MaximizeBox = False
}
oSentence = uiLabel(oForm,"",15,15,530,50)
oSentence.Font = uiFont("Segoe UI",14,false)
oInput = uiTextBox(oForm,15,75,530,30)
oInput {
	Font = uiFont("Segoe UI",14,false)
	setTextChangedEvent("typed()")
}
oResult = uiLabel(oForm,"",15,120,530,60)
oResult.Font = uiFont("Segoe UI",12,true)
uiButton(oForm,"New sentence",15,195,130,34,"newSentence()")
oBest = uiLabel(oForm,"",160,203,300,22)
newSentence()

uiRun(oForm)

# --------------------------------------------------------------------------

func newSentence
	cTarget = aSentences[random(len(aSentences) - 1) + 1]
	showTarget(cTarget)
	oInput.Text = ""
	oResult {
		Text = "Start typing..."
		ForeColor = uiColor("Black")
	}
	oWatch.Reset()
	lStarted = false
	oInput.Focus()

func showTarget cText
	cTarget = cText
	oSentence.Text = cText

# the number of typed characters that differ from the target (the part that is not typed yet does not count)
func mistakes cTyped
	nWrong = 0
	for x = 1 to len(cTarget)
		if x <= len(cTyped) and cTyped[x] != cTarget[x]
			nWrong++
		ok
	next
	if len(cTyped) > len(cTarget)
		nWrong += len(cTyped) - len(cTarget)
	ok
	return nWrong

# words per minute: five characters make a word
func wordsPerMinute nCharacters, nMilliseconds
	if nMilliseconds <= 0
		return 0
	ok
	return floor((nCharacters / 5) / (nMilliseconds / 60000))

func typed
	cTyped = oInput.Text
	if cTyped = "" or cTarget = ""
		return
	ok
	if not lStarted
		oWatch.Start()
		lStarted = true
	ok
	if cTyped = cTarget
		oWatch.Stop()
		nSpeed = wordsPerMinute(len(cTarget),oWatch.ElapsedMilliseconds)
		oResult {
			Text = "Done! " + nSpeed + " words per minute"
			ForeColor = uiColor("DarkGreen")
		}
		if nSpeed > nBest
			nBest = nSpeed
			oBest.Text = "Best: " + nBest + " wpm"
		ok
	else
		nWrong = mistakes(cTyped)
		if nWrong = 0
			oResult {
				Text = "Good so far..."
				ForeColor = uiColor("Black")
			}
		else
			oResult {
				Text = "" + nWrong + " characters are different"
				ForeColor = uiColor("Firebrick")
			}
		ok
	ok
