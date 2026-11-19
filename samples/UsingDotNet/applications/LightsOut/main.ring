# Lights Out - press a cell to toggle it and its neighbours until all the lights are off
# (a port of ring/applications/lightsout to RingDotNet)

load "dotnet.ring"
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

uiRun(oForm)

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
