# Hangman - guess the word letter by letter

load "dotnet.ring"
using {
	"System.Drawing"
	"System.Windows.Forms"
}

aWords = ["RING","PROGRAMMING","LANGUAGE","WINDOWS","FORMS","EXTENSION","CALCULATOR","KEYBOARD","DEVELOPER","FUNCTION"]
cWord = ""
cGuessed = ""
nWrong = 0
C_MAXWRONG = 6
aLetterButtons = []

oForm = uiForm("Hangman",420,380)
oForm {
	FormBorderStyle = "FixedSingle"
	MaximizeBox = False
}
oPicture = uiPictureBox(oForm,10,10,200,200)
oCanvas = new UiCanvas(oPicture)
oWord = uiLabel(oForm,"",220,30,190,50)
oWord.Font = uiFont("Consolas",20,true)
oInfo = uiLabel(oForm,"",220,100,190,60)
for nLetter = 0 to 25
	cLetter = char(65 + nLetter)
	oButton = uiButton(oForm,cLetter,10 + (nLetter % 9) * 44,225 + floor(nLetter / 9) * 40,40,36,"letter('" + cLetter + "')")
	aLetterButtons + oButton
next
uiButton(oForm,"New word",290,330,110,30,"newGame()")
newGame()

uiRun(oForm)

# --------------------------------------------------------------------------

func newGame
	cWord = aWords[random(len(aWords) - 1) + 1]
	cGuessed = ""
	nWrong = 0
	for oButton in aLetterButtons
		oButton.Enabled = True
	next
	showState()

# the word with the unknown letters as underscores
func maskedWord
	cMask = ""
	for x = 1 to len(cWord)
		if substr(cGuessed,cWord[x])
			cMask += cWord[x] + " "
		else
			cMask += "_ "
		ok
	next
	return trim(cMask)

func isWon
	return substr(maskedWord(),"_") = 0

func letter cLetter
	if substr(cGuessed,cLetter) or nWrong >= C_MAXWRONG or isWon()
		return
	ok
	cGuessed += cLetter
	aLetterButtons[ascii(cLetter) - 64].Enabled = False
	if not substr(cWord,cLetter)
		nWrong++
	ok
	showState()

func drawGallows
	oCanvas.clear("White")
	oCanvas.line(20,190,180,190,"Black",4)
	oCanvas.line(60,190,60,20,"Black",4)
	oCanvas.line(60,20,130,20,"Black",4)
	oCanvas.line(130,20,130,40,"Black",3)
	if nWrong >= 1 oCanvas.drawCircle(130,52,12,"Black") ok
	if nWrong >= 2 oCanvas.line(130,64,130,115,"Black",3) ok
	if nWrong >= 3 oCanvas.line(130,75,110,100,"Black",3) ok
	if nWrong >= 4 oCanvas.line(130,75,150,100,"Black",3) ok
	if nWrong >= 5 oCanvas.line(130,115,112,145,"Black",3) ok
	if nWrong >= 6 oCanvas.line(130,115,148,145,"Black",3) ok
	oCanvas.show()

func showState
	oWord.Text = maskedWord()
	if isWon()
		oInfo.Text = "You won!"
	but nWrong >= C_MAXWRONG
		oInfo.Text = "You lost. The word was " + cWord
		oWord.Text = cWord
	else
		oInfo.Text = "Wrong guesses: " + nWrong + " of " + C_MAXWRONG
	ok
	drawGallows()
