# Sokoban - push every box onto a target with the arrow keys (a port of ring/applications/sokoban)
#   # wall   @ player   $ box   . target   * box on a target   + player on a target

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
using {
	"System.Drawing"
	"System.Windows.Forms"
}

C_CELL = 40

aLevels = [
	["#######",
	 "#.@ $ #",
	 "#     #",
	 "#######"],
	["########",
	 "#      #",
	 "# .$.$ #",
	 "#  @   #",
	 "########"],
	["  #####",
	 "###   #",
	 "#.@$  #",
	 "### $.#",
	 "#.##$ #",
	 "# # . ##",
	 "#$ *$$.#",
	 "#   .  #",
	 "########"]
]
nLevel = 1
aMap = []		# list of strings
nPlayerColumn = 0
nPlayerRow = 0
nMoves = 0

oForm = uiForm("Sokoban",400,300)
oForm.KeyPreview = 1
oForm.FormBorderStyle = "FixedSingle"
oForm.MaximizeBox = 0
oPicture = uiPictureBox(oForm,0,36,400,264)
oCanvas = new UiCanvas(oPicture)
oInfo = uiLabel(oForm,"",10,8,250,22)
oInfo.Font = uiFont("Segoe UI",11,true)
oRestart = uiButton(oForm,"Restart",270,5,60,26,"loadLevel(nLevel)")
oNext = uiButton(oForm,"Next",335,5,55,26,"nextLevel()")
uiGameKeys(oForm,"keyPressed(aDotNetArgs[2].KeyCode)")
loadLevel(1)

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

# --------------------------------------------------------------------------

func loadLevel nNumber
	nLevel = nNumber
	aMap = []
	for cRow in aLevels[nLevel]
		aMap + cRow
	next
	nMoves = 0
	fitWindow()
	for nRow = 1 to len(aMap)
		for nColumn = 1 to len(aMap[nRow])
			if aMap[nRow][nColumn] = "@" or aMap[nRow][nColumn] = "+"
				nPlayerColumn = nColumn
				nPlayerRow = nRow
			ok
		next
	next
	draw()

# the window and the picture follow the size of the level
func fitWindow
	nColumns = 0
	for cRow in aMap
		if len(cRow) > nColumns
			nColumns = len(cRow)
		ok
	next
	nWidth = nColumns * C_CELL
	if nWidth < 400
		nWidth = 400
	ok
	nHeight = len(aMap) * C_CELL
	oPicture.Size = new Size(nWidth,nHeight)
	oForm.ClientSize = new Size(nWidth,nHeight + 36)
	oCanvas = new UiCanvas(oPicture)
	oRestart.Left = nWidth - 130
	oNext.Left = nWidth - 65

func nextLevel
	loadLevel(nLevel % len(aLevels) + 1)

func tileAt nColumn, nRow
	if nRow < 1 or nRow > len(aMap) or nColumn < 1 or nColumn > len(aMap[nRow])
		return "#"
	ok
	return aMap[nRow][nColumn]

func setTile nColumn, nRow, cTile
	aMap[nRow][nColumn] = cTile

func isTarget cTile
	return cTile = "." or cTile = "*" or cTile = "+"

func isBox cTile
	return cTile = "$" or cTile = "*"

# the tile left behind: a target stays a target
func without cTile
	if isTarget(cTile)
		return "."
	ok
	return " "

func move nDx, nDy
	nTargetColumn = nPlayerColumn + nDx
	nTargetRow = nPlayerRow + nDy
	cTarget = tileAt(nTargetColumn,nTargetRow)
	if cTarget = "#"
		return false
	ok
	if isBox(cTarget)
		cBeyond = tileAt(nTargetColumn + nDx,nTargetRow + nDy)
		if cBeyond = "#" or isBox(cBeyond)
			return false
		ok
		# push the box
		if isTarget(cBeyond)
			setTile(nTargetColumn + nDx,nTargetRow + nDy,"*")
		else
			setTile(nTargetColumn + nDx,nTargetRow + nDy,"$")
		ok
	ok
	# move the player
	cHere = tileAt(nPlayerColumn,nPlayerRow)
	setTile(nPlayerColumn,nPlayerRow,without(cHere))
	if isTarget(cTarget)
		setTile(nTargetColumn,nTargetRow,"+")
	else
		setTile(nTargetColumn,nTargetRow,"@")
	ok
	nPlayerColumn = nTargetColumn
	nPlayerRow = nTargetRow
	nMoves++
	return true

func boxesLeft
	nCount = 0
	for cRow in aMap
		for x = 1 to len(cRow)
			if cRow[x] = "$"
				nCount++
			ok
		next
	next
	return nCount

func keyPressed cKey
	switch cKey
	on "Left"	move(-1,0)
	on "Right"	move(1,0)
	on "Up"		move(0,-1)
	on "Down"	move(0,1)
	off
	draw()

func draw
	oCanvas.clear("#222222")
	for nRow = 1 to len(aMap)
		for nColumn = 1 to len(aMap[nRow])
			nX = (nColumn - 1) * C_CELL
			nY = (nRow - 1) * C_CELL
			cTile = aMap[nRow][nColumn]
			if cTile = "#"
				oCanvas.fillRect(nX,nY,C_CELL - 1,C_CELL - 1,"SlateGray")
			but cTile != " "
				oCanvas.fillRect(nX,nY,C_CELL - 1,C_CELL - 1,"#3a3a3a")
			ok
			if isTarget(cTile)
				oCanvas.fillCircle(nX + C_CELL / 2,nY + C_CELL / 2,6,"Gold")
			ok
			if cTile = "$"
				oCanvas.fillRect(nX + 5,nY + 5,C_CELL - 11,C_CELL - 11,"Peru")
			but cTile = "*"
				oCanvas.fillRect(nX + 5,nY + 5,C_CELL - 11,C_CELL - 11,"ForestGreen")
			but cTile = "@" or cTile = "+"
				oCanvas.fillCircle(nX + C_CELL / 2,nY + C_CELL / 2,13,"DodgerBlue")
			ok
		next
	next
	if boxesLeft() = 0
		oInfo.Text = "Level " + nLevel + " solved in " + nMoves + " moves!"
	else
		oInfo.Text = "Level " + nLevel + "   moves " + nMoves
	ok
	oCanvas.show()

func selfTest
	# real key presses with the Restart button focused
	loadLevel(1)
	oRestart.Focus()
	if uiSendKeys(oForm,"{LEFT}")
		dnAssert("the arrow key moves the player",nPlayerColumn,2)
		uiSendKeys(oForm,"{RIGHT}")
		dnAssert("the right arrow key too",nPlayerColumn,3)
		uiSendKeys(oForm," ")
		dnAssert("Space does not press the Restart button",nMoves,2)
	ok
	loadLevel(1)
	dnAssert("player found",nPlayerColumn,3)
	keyPressed("Left")
	dnAssert("the target square is entered",tileAt(2,2),"+")
	keyPressed("Left")
	dnAssert("the wall stops the player",nPlayerColumn,2)
	keyPressed("Right")
	keyPressed("Right")
	dnAssert("the box is pushed",tileAt(5,2),"$")
	dnAssert("the target is visible again",tileAt(2,2),".")
	dnAssert("moves counted",nMoves,3)
	# push the box left onto the target: go around it
	keyPressed("Down")
	keyPressed("Right")
	keyPressed("Right")
	keyPressed("Up")
	dnAssert("player is right of the box",tileAt(6,2),"@")
	keyPressed("Left")
	keyPressed("Left")
	keyPressed("Left")
	dnAssert("the box is on the target",tileAt(2,2),"*")
	dnAssert("level solved",oInfo.Text,"Level 1 solved in 10 moves!")
	# a box can not be pushed into a wall
	loadLevel(2)
	keyPressed("Down")
	keyPressed("Down")
	dnAssert("wall at the bottom",nPlayerRow,4)
	nextLevel()
	dnAssert("next level",nLevel,3)
	nextLevel()
	nextLevel()
	dnAssert("levels wrap around",nLevel,2)
	loadLevel(3)
	dnAssert("the window grows with the level (9 rows)",oForm.ClientSize.Height,9 * C_CELL + 36)
	dnAssert("the picture fits the level",oPicture.Height,9 * C_CELL)
	dnAssert("the whole level is drawn (last row)",oCanvas.pixel(40,8 * C_CELL + 20) != "ff222222",1)
	loadLevel(1)
	dnAssert("a small level keeps a usable width",oForm.ClientSize.Width,400)
