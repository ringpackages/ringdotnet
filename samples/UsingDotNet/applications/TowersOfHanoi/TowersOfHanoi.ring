# Towers of Hanoi - click a peg to pick the top disk, click another peg to drop it; or let it solve itself
# (a port of ring/applications/towersofhanoi to RingDotNet)

load "dotnet.ring"

using {
	"System.Drawing"
	"System.Windows.Forms"
}

nDisks = 4
aPegs = [[],[],[]]	# each peg is a list of disk sizes, the bottom disk first
nHeld = 0		# the peg we picked from (0 = nothing in the hand)
nMoves = 0
aPlan = []		# the moves of the solver: [from,to]
nPlanned = 0

oForm = uiForm("Towers of Hanoi",600,380)
oForm {
	FormBorderStyle = "FixedSingle"
	MaximizeBox = False
}
oPicture = uiPictureBox(oForm,0,0,600,300)
oCanvas = new UiCanvas(oPicture)
oPicture.setMouseDownEvent("clicked(aDotNetArgs[2].X)")
uiLabel(oForm,"Disks:",10,316,45,24)
oCount = new NumericUpDown() {
	Location = new Point(58,314)
	Size = new Size(50,24)
	Minimum = 1
	Maximum = 8
	Value = 4
}
oForm.Controls.Add(oCount)
uiButton(oForm,"New",118,312,70,28,"newGame()")
uiButton(oForm,"Solve",196,312,70,28,"startSolver()")
oInfo = uiLabel(oForm,"",280,316,310,24)
oSolver = uiTimer(300,"solverStep()")
newGame()

uiRun(oForm)

# --------------------------------------------------------------------------

func newGame

	oSolver.Stop()
	nDisks = number(oCount.Value)
	aPegs = [[],[],[]]
	for nSize = nDisks to 1 step -1
		aPegs[1] + nSize
	next
	nHeld = 0
	nMoves = 0
	draw()

func draw

	oCanvas.clear("White")
	for nPeg = 1 to 3
		nX = 100 + (nPeg - 1) * 200
		oCanvas.fillRect(nX - 4,60,8,220,"SaddleBrown")
		if nPeg = nHeld
			oCanvas.fillRect(nX - 60,282,120,8,"Orange")
		else
			oCanvas.fillRect(nX - 60,282,120,8,"Gray")
		ok
		for nLevel = 1 to len(aPegs[nPeg])
			nSize = aPegs[nPeg][nLevel]
			nWidth = 20 + nSize * 14
			oCanvas.fillRect(nX - nWidth / 2,262 - (nLevel - 1) * 24,nWidth,20,diskColor(nSize))
		next
	next
	if isSolved()
		oInfo.Text = "Solved in " + nMoves + " moves (minimum " + (pow(2,nDisks) - 1) + ")"
	else
		oInfo.Text = "Moves: " + nMoves
	ok
	oCanvas.show()

func diskColor nSize

	aColors = ["#e6194b","#f58231","#ffe119","#3cb44b","#4363d8","#911eb4","#f032e6","#808000"]
	return aColors[nSize]

func isSolved

	return len(aPegs[3]) = nDisks

# can the top disk of nFrom go to nTo
func canMove nFrom, nTo

	if nFrom = nTo or len(aPegs[nFrom]) = 0
		return false
	ok
	if len(aPegs[nTo]) = 0
		return true
	ok
	return aPegs[nFrom][len(aPegs[nFrom])] < aPegs[nTo][len(aPegs[nTo])]

func moveDisk nFrom, nTo

	if not canMove(nFrom,nTo)
		return false
	ok
	aPegs[nTo] + aPegs[nFrom][len(aPegs[nFrom])]
	del(aPegs[nFrom],len(aPegs[nFrom]))
	nMoves++
	return true

func clicked nMouseX

	nPeg = floor(nMouseX / 200) + 1
	if nPeg > 3
		nPeg = 3
	ok
	if nHeld = 0
		if len(aPegs[nPeg]) > 0
			nHeld = nPeg
		ok
	else
		moveDisk(nHeld,nPeg)
		nHeld = 0
	ok
	draw()

# the recursive solution, collected as a list of moves
func solve nCount, nFrom, nTo, nVia

	if nCount = 0
		return
	ok
	solve(nCount - 1,nFrom,nVia,nTo)
	aPlan + [nFrom,nTo]
	solve(nCount - 1,nVia,nTo,nFrom)

func startSolver

	newGame()
	aPlan = []
	solve(nDisks,1,3,2)
	nPlanned = 0
	oSolver.Start()

func solverStep

	nPlanned++
	if nPlanned > len(aPlan)
		oSolver.Stop()
		return
	ok
	moveDisk(aPlan[nPlanned][1],aPlan[nPlanned][2])
	draw()
