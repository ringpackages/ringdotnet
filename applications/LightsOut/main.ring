# Lights Out - press a cell to toggle it and its neighbours until all the lights are off
# (a port of ring/applications/lightsout to RingDotNet)

load "dotnetlib.ring"
dnUseDesktop()
using {
	"System.Drawing"
	"System.Windows.Forms"
}

C_SIZE = 5
aLights = list(C_SIZE * C_SIZE)
aCells = []
nPresses = 0

oForm = uiForm("Lights Out",310,380)
oForm {
	FormBorderStyle = "FixedSingle"
	MaximizeBox = False
}
for nCell = 1 to C_SIZE * C_SIZE
	nRow = floor((nCell - 1) / C_SIZE)
	nCol = (nCell - 1) % C_SIZE
	oCell = uiButton(oForm,"",10 + nCol * 58,10 + nRow * 58,55,55,"press(" + nCell + ")")
	oCell.FlatStyle = "Flat"
	aCells + oCell
next
oInfo = uiLabel(oForm,"",10,305,290,24)
uiButton(oForm,"New game",10,335,100,30,"newGame()")
newGame()

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

# --------------------------------------------------------------------------

func showLights
	for nCell = 1 to len(aLights)
		if aLights[nCell]
			aCells[nCell].BackColor = uiColor("Gold")
		else
			aCells[nCell].BackColor = uiColor("DimGray")
		ok
	next
	nOn = 0
	for nLight in aLights
		nOn += nLight
	next
	if nOn = 0
		oInfo.Text = "All lights are off - you won in " + nPresses + " presses!"
	else
		oInfo.Text = string(nOn) + " lights on, presses: " + nPresses
	ok

func toggle nCell
	aLights[nCell] = not aLights[nCell]

# toggle the cell and its neighbours
func flip nCell
	nRow = floor((nCell - 1) / C_SIZE)
	nCol = (nCell - 1) % C_SIZE
	toggle(nCell)
	if nRow > 0 toggle(nCell - C_SIZE) ok
	if nRow < C_SIZE - 1 toggle(nCell + C_SIZE) ok
	if nCol > 0 toggle(nCell - 1) ok
	if nCol < C_SIZE - 1 toggle(nCell + 1) ok

func press nCell
	flip(nCell)
	nPresses++
	showLights()

func newGame
	aLights = list(C_SIZE * C_SIZE)
	# random presses keep the game solvable
	for nStep = 1 to 12
		flip(random(C_SIZE * C_SIZE - 1) + 1)
	next
	nPresses = 0
	showLights()

func selfTest
	aLights = list(C_SIZE * C_SIZE)
	showLights()
	aCells[13].PerformClick()
	dnAssert("center flips 5 lights",aLights[13] + aLights[8] + aLights[18] + aLights[12] + aLights[14],5)
	dnAssert("others stay off",aLights[1] + aLights[25],0)
	aCells[13].PerformClick()
	dnAssert("pressing twice undoes it",aLights[13] + aLights[8],0)
	dnAssert("win message",left(oInfo.Text,10),"All lights")
	aLights = list(C_SIZE * C_SIZE)
	aCells[1].PerformClick()
	dnAssert("corner flips 3 lights",aLights[1] + aLights[2] + aLights[6],3)
	dnAssert("button color on",aCells[1].BackColor.Name,"Gold")
	dnAssert("button color off",aCells[25].BackColor.Name,"DimGray")
	newGame()
	dnAssert("new game resets the counter",nPresses,0)
