# Rock, paper, scissors against the computer (a port of ring/applications/rockpaperscissors)

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
using {
	"System.Drawing"
	"System.Windows.Forms"
}

aNames = ["Rock","Paper","Scissors"]
nWins = 0
nLosses = 0
nTies = 0

oForm = uiForm("Rock, paper, scissors",360,250)
oForm {
	FormBorderStyle = "FixedSingle"
	MaximizeBox = False
}
uiLabel(oForm,"Choose:",10,12,60,24)
for nChoice = 1 to 3
	uiButton(oForm,aNames[nChoice],80 + (nChoice - 1) * 90,8,85,34,"play(" + nChoice + ")")
next
oResult = uiLabel(oForm,"Make your move",10,60,340,60)
oResult {
	Font = uiFont("Segoe UI",14,true)
	TextAlign = "MiddleCenter"
}
oScore = uiLabel(oForm,"",10,140,340,28)
oScore.TextAlign = "MiddleCenter"
oHistory = uiListBox(oForm,10,172,340,70)
showScore()

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

# --------------------------------------------------------------------------

# 1 = the player wins, 0 = tie, -1 = the computer wins (rock = 1, paper = 2, scissors = 3)
func compare nPlayer, nComputer
	if nPlayer = nComputer
		return 0
	ok
	if (nPlayer = 1 and nComputer = 3) or (nPlayer = 2 and nComputer = 1) or (nPlayer = 3 and nComputer = 2)
		return 1
	ok
	return -1

func showScore
	oScore.Text = "Wins " + nWins + "   Losses " + nLosses + "   Ties " + nTies

func playAgainst nPlayer, nComputer
	nOutcome = compare(nPlayer,nComputer)
	switch nOutcome
	on 1
		nWins++
		cText = "You win! " + aNames[nPlayer] + " beats " + aNames[nComputer]
	on 0
		nTies++
		cText = "Tie: both chose " + aNames[nPlayer]
	on -1
		nLosses++
		cText = "You lose. " + aNames[nComputer] + " beats " + aNames[nPlayer]
	off
	oResult.Text = cText
	oHistory.Items.Insert(0,cText)
	showScore()
	return nOutcome

func play nPlayer
	playAgainst(nPlayer,random(2) + 1)

func selfTest
	dnAssert("rock beats scissors",compare(1,3),1)
	dnAssert("scissors beat paper",compare(3,2),1)
	dnAssert("paper beats rock",compare(2,1),1)
	dnAssert("paper loses to scissors",compare(2,3),-1)
	dnAssert("tie",compare(2,2),0)
	playAgainst(1,3)
	dnAssert("win recorded",nWins,1)
	dnAssert("win message",left(oResult.Text,8),"You win!")
	playAgainst(1,2)
	dnAssert("loss recorded",nLosses,1)
	playAgainst(3,3)
	dnAssert("tie recorded",nTies,1)
	dnAssert("history has 3 lines",oHistory.Items.Count,3)
	dnAssert("score label",oScore.Text,"Wins 1   Losses 1   Ties 1")
	# a real click plays against a random computer move
	oForm.Controls.Item(1).PerformClick()
	dnAssert("a click counts one game",nWins + nLosses + nTies,4)
