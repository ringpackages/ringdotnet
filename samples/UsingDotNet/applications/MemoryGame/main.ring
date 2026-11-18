# Memory game - find the pairs (a port of ring/applications/memorygame to RingDotNet)

load "dotnet.ring"
using {
	"System"
	"System.Diagnostics"
	"System.Threading"
	"System.Drawing"
	"System.Windows.Forms"
}

C_CARDS = 16
aSymbols = []		# the symbol hidden behind each card
aCardButtons = []
aMatched = list(C_CARDS)
nFirst = 0		# the first card turned in this attempt
nSecond = 0
nAttempts = 0
nPairs = 0
lBusy = false

oForm = uiForm("Memory game",330,400)
oForm {
	FormBorderStyle = "FixedSingle"
	MaximizeBox = False
}
for nCard = 1 to C_CARDS
	nRow = floor((nCard - 1) / 4)
	nCol = (nCard - 1) % 4
	oCard = uiButton(oForm,"?",10 + nCol * 78,10 + nRow * 78,74,74,"turn(" + nCard + ")")
	oCard.Font = uiFont("Segoe UI",24,true)
	aCardButtons + oCard
next
oInfo = uiLabel(oForm,"",10,330,200,24)
uiButton(oForm,"New game",220,326,100,30,"newGame()")
oHideTimer = uiTimer(700,"hideCards()")
newGame()

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

# --------------------------------------------------------------------------

func newGame
	oHideTimer.Stop()
	# two cards of each of the 8 letters, shuffled
	aSymbols = []
	for cLetter in ["A","B","C","D","E","F","G","H"]
		aSymbols + cLetter
		aSymbols + cLetter
	next
	for nIndex = len(aSymbols) to 2 step -1
		nOther = random(nIndex - 1) + 1
		cTemp = aSymbols[nIndex]
		aSymbols[nIndex] = aSymbols[nOther]
		aSymbols[nOther] = cTemp
	next
	aMatched = list(C_CARDS)
	nFirst = 0
	nSecond = 0
	nAttempts = 0
	nPairs = 0
	lBusy = false
	for oCard in aCardButtons
		oCard {
			Text = "?"
			Enabled = True
			BackColor = new Color().Empty
		}
	next
	showInfo()

func showInfo
	oInfo.Text = "Pairs: " + nPairs + "/8   Attempts: " + nAttempts

func turn nCard
	if lBusy or aMatched[nCard] or nCard = nFirst
		return
	ok
	aCardButtons[nCard].Text = aSymbols[nCard]
	aCardButtons[nCard].BackColor = uiColor("LightYellow")
	if nFirst = 0
		nFirst = nCard
		return
	ok
	nSecond = nCard
	nAttempts++
	if aSymbols[nFirst] = aSymbols[nSecond]
		aMatched[nFirst] = true
		aMatched[nSecond] = true
		aCardButtons[nFirst].BackColor = uiColor("LightGreen")
		aCardButtons[nSecond].BackColor = uiColor("LightGreen")
		nPairs++
		nFirst = 0
		nSecond = 0
		if nPairs = 8
			uiMessage("You found all the pairs in " + nAttempts + " attempts!","Memory game")
		ok
	else
		lBusy = true
		oHideTimer.Start()
	ok
	showInfo()

func hideCards
	oHideTimer.Stop()
	for nCard in [nFirst,nSecond]
		aCardButtons[nCard].Text = "?"
		aCardButtons[nCard].BackColor = new Color().Empty
	next
	nFirst = 0
	nSecond = 0
	lBusy = false

func waitMs nMilliseconds
	oClock = new Stopwatch()
	oClock.Start()
	while oClock.ElapsedMilliseconds < nMilliseconds
		new Application().DoEvents()
		new Thread().Sleep(5)
	end

func selfTest
	# a known layout: pairs next to each other
	aSymbols = ["A","A","B","B","C","C","D","D","E","E","F","F","G","G","H","H"]
	aCardButtons[1].PerformClick()
	dnAssert("card shows its symbol",aCardButtons[1].Text,"A")
	aCardButtons[2].PerformClick()
	dnAssert("a pair is kept",nPairs,1)
	dnAssert("matched color",aCardButtons[1].BackColor.Name,"LightGreen")
	aCardButtons[3].PerformClick()
	aCardButtons[5].PerformClick()
	dnAssert("a wrong pair is turned back after a moment",lBusy,1)
	dnAssert("both cards are still shown",aCardButtons[5].Text,"C")
	waitMs(1100)
	dnAssert("cards hidden again",aCardButtons[5].Text,"?")
	dnAssert("attempts counted",nAttempts,2)
	aCardButtons[3].PerformClick()
	aCardButtons[4].PerformClick()
	dnAssert("second pair",nPairs,2)
	newGame()
	dnAssert("new game hides everything",aCardButtons[1].Text,"?")
	dnAssert("16 symbols",len(aSymbols),16)
