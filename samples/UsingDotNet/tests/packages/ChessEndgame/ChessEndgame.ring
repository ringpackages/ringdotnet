# Chess end game: a window for the ML.NET models of the example (a white king and a white rook against a black king).
#   ring train.ring           first: makes the models (or use the button of the tab Models)
#   ring ChessEndgame.ring    the window
# Play: drag the pieces on the board, and the models say how the game ends. Data: the 28,056 positions of the data set. Statistics: the results of the data in numbers and a chart.
# Models: the saved models and their accuracy on the test positions, training of all the algorithms, and the test of a model. A port of ring/applications/chessendgame (RingQt, and
# models of Azure), with the models of ML.NET that train.ring makes and without C#.

load "chesslib.ring"

using {
	"System"
	"System.Drawing"
	"System.Windows.Forms"
}

C_CELL = 50                     # the size of a square of the board in pixels
C_LEFT = 30                     # where the board starts in the picture
C_TOP = 10
C_PAGE = 500                    # the rows of the data that one page of the tab Data shows
C_RESULTS = ["draw","zero","one","two","three","four","five","six","seven","eight","nine","ten","eleven","twelve","thirteen","fourteen","fifteen","sixteen"]

gPiece = [[5,4],[5,1],[8,8]]    # the squares of the white king, the white rook and the black king: [file, rank]
gDrag = 0                       # the piece that is dragged (0: none), and where the mouse is
gDragX = 0
gDragY = 0
gBusy = false                   # true while the program changes a control itself (the controls then do not answer)
gModels = []                    # the models of models/index.txt, the best first
gLoaded = [:none = 0]           # the models that are loaded: the key of a model is key_features
gRows = []                      # the positions of the data: [white king, white rook, black king, result] with the squares as a1 to h8
gKnown = [:none = ""]           # the result of a position of the data: the key is the six squares
gFilter = []                    # the numbers of the rows that the tab Data shows (the filter of the result)
gPage = 1
gCounts = []                    # the number of positions of each result
gImages = []

# the controls (made by the functions that build the tabs): the variables exist first, so that the functions change these ones.
# (No variable here is called oPicture, oBitmap or oGraphics: these are attributes of UiCanvas, and a global of the same name takes their place inside its methods.)
oBoardPicture = ""
oCanvas = ""
oModelBox = ""
oKingBox = ""
oRookBox = ""
oBlackBox = ""
oAnswer = ""
oReal = ""
oVerdict = ""
oNote = ""
oAll = ""
oFilterBox = ""
oPageLabel = ""
oRowList = ""
oDataNote = ""
oStatList = ""
oChartPicture = ""
oChart = ""
oStatNote = ""
oModelList = ""
oProgress = ""
oModelNote = ""

chessSetup()
oMl = chessContext(1)
loadTheData()
gModels = chessModels()
loadImages()

oForm = uiForm("Chess end game - ML.NET with RingDotNet",1000,700)
oForm.StartPosition = "CenterScreen"
oTabs = new TabControl()
oTabs.Dock = "Fill"
oStatus = new StatusStrip()
oStatusText = new ToolStripStatusLabel()
oStatus.Items.Add(oStatusText)
oForm.Controls.Add(oTabs)
oForm.Controls.Add(oStatus)
aPages = []
for cName in ["Play","Data","Statistics","Models"]
	oPage = new TabPage()
	oPage.Text = cName
	oTabs.TabPages.Add(oPage)
	aPages + oPage
next

buildPlay(aPages[1])
buildData(aPages[2])
buildStatistics(aPages[3])
buildModels(aPages[4])
showModels()
showStatistics()
showPage()
fillModelBox()
showPosition()

uiRun(oForm)

# ---------------------------------------------------------------- the data

# data/chess.csv: the squares of the pieces and the result. gKnown finds the result of a position from its squares.
func loadTheData

	aLines = str2list(read("data/chess.csv"))
	nLines = len(aLines)
	gCounts = list(len(C_RESULTS))
	for nLine = 2 to nLines
		cLine = aLines[nLine]
		if len(cLine) > 5
			aParts = str2list(substr(cLine,",",nl))
			cWhiteKing = aParts[1] + aParts[2]
			cWhiteRook = aParts[3] + aParts[4]
			cBlackKing = aParts[5] + aParts[6]
			gRows + [cWhiteKing,cWhiteRook,cBlackKing,aParts[7]]
			gKnown[cWhiteKing + cWhiteRook + cBlackKing] = aParts[7]
			nPlace = find(C_RESULTS,aParts[7])
			gCounts[nPlace] += 1
		ok
	next

# The result that the data has for a position (the squares are [file, rank]), or "" for a position that the data does not have. The data has one way of each position
# (see chessCanonical), so the position is turned to that way first; a position with the white king on the diagonal has two ways, and the other one is tried as well.
func knownResult aKing, aRook, aBlack

	aWay = chessCanonical(aKing[1],aKing[2],aRook[1],aRook[2],aBlack[1],aBlack[2])
	cResult = gKnown[wayKey(aWay)]
	if isstring(cResult) and cResult != ""
		return cResult
	ok
	cResult = gKnown[wayKey([aWay[2],aWay[1],aWay[4],aWay[3],aWay[6],aWay[5]])]          # the same position mirrored along the diagonal
	if isstring(cResult)
		return cResult
	ok
	return ""

func wayKey aWay

	return squareName([aWay[1],aWay[2]]) + squareName([aWay[3],aWay[4]]) + squareName([aWay[5],aWay[6]])

func squareName aSquare

	return char(96 + aSquare[1]) + aSquare[2]

# the squares as a text a1 to h8 to [file, rank]
func squareOf cSquare

	return [ascii(left(cSquare,1)) - 96,number(substr(cSquare,2,1))]

func loadImages

	for cName in ["WK","WR","BK"]
		gImages + new Image().FromFile(currentdir() + "/images/" + cName + ".png")
	next

# ---------------------------------------------------------------- the tab Play

func buildPlay oPage

	oBoardPicture = uiPictureBox(oPage,10,10,C_LEFT + C_CELL * 8 + 10,C_TOP + C_CELL * 8 + 30)
	oCanvas = new UiCanvas(oBoardPicture)
	oBoardPicture {
		setMouseDownEvent("boardDown(aDotNetArgs[2].X,aDotNetArgs[2].Y)")
		setMouseMoveEvent("boardMove(aDotNetArgs[2].X,aDotNetArgs[2].Y)")
		setMouseUpEvent("boardUp(aDotNetArgs[2].X,aDotNetArgs[2].Y)")
	}
	uiLabel(oPage,"Drag the pieces on the board: the white king, the white rook and the black king (it is white's turn).",10,462,440,40)

	uiLabel(oPage,"Model",470,14,50,22)
	oModelBox = uiComboBox(oPage,530,10,420,[""])
	oModelBox.setSelectedIndexChangedEvent("modelChanged()")
	aSquares = []
	for nFile = 1 to 8
		for nRank = 1 to 8
			aSquares + squareName([nFile,nRank])
		next
	next
	aBoxes = []
	nX = 470
	for cPiece in ["White king","White rook","Black king"]
		uiLabel(oPage,cPiece,nX,52,140,22)
		aBoxes + uiComboBox(oPage,nX,76,100,aSquares)
		nX += 160
	next
	oKingBox = aBoxes[1]
	oRookBox = aBoxes[2]
	oBlackBox = aBoxes[3]
	oKingBox.setSelectedIndexChangedEvent("squareChosen(1,oKingBox)")
	oRookBox.setSelectedIndexChangedEvent("squareChosen(2,oRookBox)")
	oBlackBox.setSelectedIndexChangedEvent("squareChosen(3,oBlackBox)")
	for oBox in aBoxes
		oBox.setDropDownClosedEvent("drawBoard()")          # the list is closed: the board is drawn again (it may have been painted under the open list)
	next
	uiButton(oPage,"Random position",470,116,140,30,"randomPosition()")
	uiButton(oPage,"From the data",620,116,140,30,"dataPosition()")
	uiButton(oPage,"Ask all the models",770,116,180,30,"askAll()")

	oAnswer = uiLabel(oPage,"",470,162,480,40)
	oAnswer.Font = uiFont("Segoe UI",16,true)
	oReal = uiLabel(oPage,"",470,206,480,24)
	oVerdict = uiLabel(oPage,"",470,232,480,24)
	oNote = uiLabel(oPage,"",470,258,480,24)
	oAll = new ListView() {
		Location = new Point(470,290)
		Size = new Size(480,280)
		View = "Details"
		FullRowSelect = True
		GridLines = True
	}
	oAll.Columns.Add([ :text = "Model", :width = 250 ])
	oAll.Columns.Add([ :text = "Answer", :width = 140 ])
	oAll.Columns.Add([ :text = "Right", :width = 70 ])
	oPage.Controls.Add(oAll)

# the way the board is drawn: the squares, the names of the files and the ranks, the pieces, and the piece that is dragged on top
func drawBoard

	oCanvas.clear("#f0f0f0")
	for nRank = 1 to 8
		for nFile = 1 to 8
			cColor = "#f0d9b5"
			if (nFile + nRank) % 2 = 0
				cColor = "#b58863"
			ok
			oCanvas.fillRect(C_LEFT + (nFile - 1) * C_CELL,C_TOP + (8 - nRank) * C_CELL,C_CELL,C_CELL,cColor)
		next
	next
	for nPlace = 1 to 8
		oCanvas.text(char(96 + nPlace),C_LEFT + (nPlace - 1) * C_CELL + 20,C_TOP + 8 * C_CELL + 4,"Black",10)
		oCanvas.text("" + nPlace,10,C_TOP + (8 - nPlace) * C_CELL + 15,"Black",10)
	next
	for nPiece = 1 to 3
		if nPiece != gDrag
			drawPiece(nPiece,C_LEFT + (gPiece[nPiece][1] - 1) * C_CELL,C_TOP + (8 - gPiece[nPiece][2]) * C_CELL)
		ok
	next
	if gDrag > 0
		drawPiece(gDrag,gDragX - C_CELL / 2,gDragY - C_CELL / 2)
	ok
	oCanvas.show()

func drawPiece nPiece, nX, nY

	oCanvas.oGraphics.DrawImage([ :image = gImages[nPiece], :x = nX, :y = nY, :width = C_CELL, :height = C_CELL ])

# the square under a point of the picture: [file, rank], or an empty list outside the board
func squareAt nX, nY

	nFile = floor((nX - C_LEFT) / C_CELL) + 1
	nRank = 8 - floor((nY - C_TOP) / C_CELL)
	if nX < C_LEFT or nY < C_TOP or nFile < 1 or nFile > 8 or nRank < 1 or nRank > 8
		return []
	ok
	return [nFile,nRank]

# the piece that is on a square (0: none)
func pieceAt aSquare

	for nPiece = 1 to 3
		if gPiece[nPiece][1] = aSquare[1] and gPiece[nPiece][2] = aSquare[2]
			return nPiece
		ok
	next
	return 0

func boardDown nX, nY

	aSquare = squareAt(nX,nY)
	if len(aSquare) = 2
		gDrag = pieceAt(aSquare)
		gDragX = nX
		gDragY = nY
		if gDrag > 0
			drawBoard()
		ok
	ok

func boardMove nX, nY

	if gDrag > 0
		gDragX = nX
		gDragY = nY
		drawBoard()
	ok

# the piece is dropped: on a free square it stays there, anywhere else it goes back
func boardUp nX, nY

	if gDrag = 0
		return
	ok
	nPiece = gDrag
	gDrag = 0
	aSquare = squareAt(nX,nY)
	if len(aSquare) = 2 and pieceAt(aSquare) = 0
		gPiece[nPiece] = aSquare
	ok
	showPosition()

# a piece is moved with the box of its square
func squareChosen nPiece, oBox

	if gBusy
		return
	ok
	nIndex = oBox.SelectedIndex
	aSquare = [floor(nIndex / 8) + 1,nIndex % 8 + 1]
	if pieceAt(aSquare) = 0
		gPiece[nPiece] = aSquare
	ok
	showPosition()

# a position is shown: the board, the boxes of the squares, and the answer of the model
func showPosition

	gBusy = true
	oKingBox.SelectedIndex = (gPiece[1][1] - 1) * 8 + gPiece[1][2] - 1
	oRookBox.SelectedIndex = (gPiece[2][1] - 1) * 8 + gPiece[2][2] - 1
	oBlackBox.SelectedIndex = (gPiece[3][1] - 1) * 8 + gPiece[3][2] - 1
	gBusy = false
	drawBoard()
	oAll.Items.Clear()
	aKing = gPiece[1]
	aRook = gPiece[2]
	aBlack = gPiece[3]
	oNote.Text = ""
	oVerdict.Text = ""
	cReal = knownResult(aKing,aRook,aBlack)
	if cReal = ""
		oReal.Text = "The data does not have this position."
	else
		oReal.Text = "The data says: " + chessSay(cReal)
	ok
	if chessDistance(aKing[1],aKing[2],aBlack[1],aBlack[2]) <= 1
		oNote.Text = "The kings touch each other: this can not be a position of a game."
	ok
	if len(gModels) = 0
		oAnswer.Text = "There are no models yet"
		oNote.Text = "Make them with the tab Models (or ring train.ring)."
		return
	ok
	cAnswer = answerOf(oModelBox.SelectedIndex + 1)
	oAnswer.Text = "The model says: " + chessSay(cAnswer)
	if cReal != ""
		if cAnswer = cReal
			oVerdict.Text = "The model is right."
		but cAnswer != "draw" and cReal != "draw" and fabs(chessDepth(cAnswer) - chessDepth(cReal)) = 1
			oVerdict.Text = "The model is wrong by one move."
		else
			oVerdict.Text = "The model is wrong."
		ok
	ok

# the answer (the word of the result) of a model of the list for the position on the board
func answerOf nModel

	aModel = gModels[nModel]
	cKey = aModel[1] + "_" + aModel[3]
	if not isobject(gLoaded[cKey])
		oStatusText.Text = "Loading the model " + aModel[2] + " ..."
		new Application().DoEvents()
		gLoaded[cKey] = chessLoadModel(oMl,aModel)
		oStatusText.Text = ""
	ok
	return chessPredictOne(oMl,gLoaded[cKey],gPiece[1],gPiece[2],gPiece[3])

# the models of the list with their accuracy
func fillModelBox

	gBusy = true
	oModelBox.Items.Clear()
	for aModel in gModels
		oModelBox.Items.Add(aModel[2] + " [" + aModel[3] + "]   " + chessPercent(aModel[4]))
	next
	if len(gModels) > 0
		oModelBox.SelectedIndex = 0
	ok
	gBusy = false

func modelChanged

	if not gBusy
		showPosition()
	ok

# a position of the game: the pieces on squares that are not the same, and the kings that do not touch
func randomPosition

	lFound = false
	while not lFound
		aTry = []
		for nPiece = 1 to 3
			aTry + [random(7) + 1,random(7) + 1]
		next
		lFound = (chessDistance(aTry[1][1],aTry[1][2],aTry[3][1],aTry[3][2]) > 1)
		if aTry[2][1] = aTry[1][1] and aTry[2][2] = aTry[1][2]
			lFound = false
		ok
		if aTry[2][1] = aTry[3][1] and aTry[2][2] = aTry[3][2]
			lFound = false
		ok
	end
	gPiece = aTry
	showPosition()

# a position of the data (with its real result)
func dataPosition

	nRow = random(len(gRows) - 1) + 1
	setRow(nRow)
	showPosition()

func setRow nRow

	gPiece = [squareOf(gRows[nRow][1]),squareOf(gRows[nRow][2]),squareOf(gRows[nRow][3])]

# what all the models say about the position
func askAll

	if len(gModels) = 0
		return
	ok
	oAll.Items.Clear()
	cReal = knownResult(gPiece[1],gPiece[2],gPiece[3])
	nModels = len(gModels)
	for nModel = 1 to nModels
		cAnswer = answerOf(nModel)
		cRight = ""
		if cReal != ""
			cRight = "no"
			if cAnswer = cReal
				cRight = "yes"
			ok
		ok
		oItem = new ListViewItem().@New([ :text = gModels[nModel][2] + " [" + gModels[nModel][3] + "]" ])
		oItem.SubItems.Add(chessSay(cAnswer))
		oItem.SubItems.Add(cRight)
		oAll.Items.Add(oItem)
	next
	oStatusText.Text = "The models answered for " + squareName(gPiece[1]) + " " + squareName(gPiece[2]) + " " + squareName(gPiece[3])

# ---------------------------------------------------------------- the tab Data

func buildData oPage

	uiLabel(oPage,"Result",10,14,50,22)
	aFilters = ["all"]
	for cResult in C_RESULTS
		aFilters + cResult
	next
	oFilterBox = uiComboBox(oPage,66,10,120,aFilters)
	oFilterBox.setSelectedIndexChangedEvent("filterChanged()")
	uiButton(oPage,"<",200,8,40,28,"pageMove(-1)")
	oPageLabel = uiLabel(oPage,"",246,14,360,22)
	uiButton(oPage,">",612,8,40,28,"pageMove(1)")
	uiButton(oPage,"Show on the board",670,8,160,28,"showSelectedRow()")
	oRowList = new ListView() {
		Location = new Point(10,48)
		Size = new Size(690,540)
		View = "Details"
		FullRowSelect = True
		GridLines = True
	}
	oRowList.Columns.Add([ :text = "#", :width = 70 ])
	oRowList.Columns.Add([ :text = "White king", :width = 110 ])
	oRowList.Columns.Add([ :text = "White rook", :width = 110 ])
	oRowList.Columns.Add([ :text = "Black king", :width = 110 ])
	oRowList.Columns.Add([ :text = "Result", :width = 200 ])
	oPage.Controls.Add(oRowList)
	oRowList.setDoubleClickEvent("showSelectedRow()")
	oDataNote = uiLabel(oPage,"",720,48,250,200)
	oDataNote.Text = "The positions of the data set: where the pieces are, and the result of the game with the best play: a draw, or the number of moves that white needs to win." + nl + nl + "Double click a row (or use the button) to see the position on the board and what the models say."

func filterChanged

	if gBusy
		return
	ok
	gPage = 1
	showPage()

# the rows of the filter, one page of them
func showPage

	cResult = oFilterBox.Text
	gFilter = []
	nRows = len(gRows)
	for nRow = 1 to nRows
		if cResult = "all" or gRows[nRow][4] = cResult
			gFilter + nRow
		ok
	next
	nPages = floor((len(gFilter) - 1) / C_PAGE) + 1
	if gPage > nPages
		gPage = nPages
	ok
	if gPage < 1
		gPage = 1
	ok
	nFrom = (gPage - 1) * C_PAGE + 1
	nTo = nFrom + C_PAGE - 1
	if nTo > len(gFilter)
		nTo = len(gFilter)
	ok
	oRowList.BeginUpdate()
	oRowList.Items.Clear()
	for nPlace = nFrom to nTo
		nRow = gFilter[nPlace]
		oItem = new ListViewItem().@New([ :text = "" + nRow ])
		oItem.SubItems.Add(gRows[nRow][1])
		oItem.SubItems.Add(gRows[nRow][2])
		oItem.SubItems.Add(gRows[nRow][3])
		oItem.SubItems.Add(chessSay(gRows[nRow][4]))
		oRowList.Items.Add(oItem)
	next
	oRowList.EndUpdate()
	oPageLabel.Text = "positions " + nFrom + " to " + nTo + " of " + len(gFilter) + " (page " + gPage + " of " + nPages + ")"

func pageMove nStep

	gPage += nStep
	showPage()

func showSelectedRow

	if oRowList.SelectedItems.Count = 0
		return
	ok
	nRow = number(oRowList.SelectedItems.Item(0).Text)
	setRow(nRow)
	oTabs.SelectedIndex = 0
	showPosition()

# ---------------------------------------------------------------- the tab Statistics

func buildStatistics oPage

	oStatList = new ListView() {
		Location = new Point(10,10)
		Size = new Size(380,470)
		View = "Details"
		FullRowSelect = True
		GridLines = True
	}
	oStatList.Columns.Add([ :text = "Result", :width = 120 ])
	oStatList.Columns.Add([ :text = "Positions", :width = 90 ])
	oStatList.Columns.Add([ :text = "Share", :width = 90 ])
	oPage.Controls.Add(oStatList)
	oStatList.setSelectedIndexChangedEvent("drawChart()")
	oChartPicture = uiPictureBox(oPage,410,10,560,470)
	oChart = new UiCanvas(oChartPicture)
	oStatNote = uiLabel(oPage,"",10,490,960,60)

func showStatistics

	nTotal = len(gRows)
	oStatList.Items.Clear()
	for nResult = 1 to len(C_RESULTS)
		oItem = new ListViewItem().@New([ :text = chessSay(C_RESULTS[nResult]) ])
		oItem.SubItems.Add("" + gCounts[nResult])
		oItem.SubItems.Add(chessPercent(gCounts[nResult] / nTotal))
		oStatList.Items.Add(oItem)
	next
	oStatNote.Text = "" + nTotal + " positions: " + gCounts[1] + " draws (" + chessPercent(gCounts[1] / nTotal) + ") and " + (nTotal - gCounts[1]) + " wins for white, in 0 to 16 moves."
	drawChart()

# the bars of the number of positions of each result; the result that is selected in the table has another color
func drawChart

	nMax = 0
	for nCount in gCounts
		if nCount > nMax
			nMax = nCount
		ok
	next
	nSelected = 0
	if oStatList.SelectedIndices.Count > 0
		nSelected = oStatList.SelectedIndices.Item(0) + 1
	ok
	oChart.clear("White")
	nBars = len(C_RESULTS)
	nWidth = 26
	nHeight = 380
	for nBar = 1 to nBars
		nBarHeight = floor(gCounts[nBar] / nMax * nHeight)
		cColor = "#4c78a8"
		if nBar = 1
			cColor = "#9a9a9a"
		ok
		if nBar = nSelected
			cColor = "#e45756"
		ok
		nX = 14 + (nBar - 1) * 30
		oChart.fillRect(nX,10 + nHeight - nBarHeight,nWidth,nBarHeight,cColor)
		cName = "d"
		if nBar > 1
			cName = "" + (nBar - 2)
		ok
		oChart.text(cName,nX + 4,10 + nHeight + 4,"Black",9)
	next
	if nSelected > 0
		oChart.text(chessSay(C_RESULTS[nSelected]) + ": " + gCounts[nSelected] + " positions",14,4,"Black",11)
	else
		oChart.text("positions of each result (d: draw, then the moves to win)",14,4,"Black",11)
	ok
	oChart.show()

# ---------------------------------------------------------------- the tab Models

func buildModels oPage

	oModelList = new ListView() {
		Location = new Point(10,10)
		Size = new Size(960,330)
		View = "Details"
		FullRowSelect = True
		GridLines = True
	}
	oModelList.Columns.Add([ :text = "#", :width = 40 ])
	oModelList.Columns.Add([ :text = "Algorithm", :width = 360 ])
	oModelList.Columns.Add([ :text = "Features", :width = 120 ])
	oModelList.Columns.Add([ :text = "Accuracy", :width = 100 ])
	oModelList.Columns.Add([ :text = "Within 1 move", :width = 120 ])
	oPage.Controls.Add(oModelList)
	uiButton(oPage,"Train all the algorithms",10,350,200,32,"trainModels(false)")
	uiButton(oPage,"Quick training (3 algorithms)",220,350,220,32,"trainModels(true)")
	uiButton(oPage,"Test the selected model",450,350,200,32,"testSelected()")
	oProgress = new ProgressBar()
	oProgress.Location = new Point(10,394)
	oProgress.Size = new Size(960,22)
	oPage.Controls.Add(oProgress)
	oModelNote = uiLabel(oPage,"",10,424,960,160)
	oModelNote.Text = "The models learn from 70 percent of the positions and are tested on the other 30 percent that they have not seen. Accuracy is the share of the test positions whose result is exactly right; within 1 move also accepts a win that is one move off." + nl + nl + "Training all the algorithms takes about a minute."

func showModels

	oModelList.Items.Clear()
	nPlace = 1
	for aModel in gModels
		oItem = new ListViewItem().@New([ :text = "" + nPlace ])
		oItem.SubItems.Add(aModel[2])
		oItem.SubItems.Add(aModel[3])
		oItem.SubItems.Add(chessPercent(aModel[4]))
		oItem.SubItems.Add(chessPercent(aModel[5]))
		oModelList.Items.Add(oItem)
		nPlace++
	next

# split the data (70 / 30), train the algorithms and save the models; the window shows the progress
func trainModels lQuick

	oProgress.Value = 0
	oModelNote.Text = "Splitting the positions: 70 percent to train, 30 percent to test ..."
	new Application().DoEvents()
	aCounts = chessSplit(lQuick)
	oModelNote.Text = "" + aCounts[1] + " positions to train, " + aCounts[2] + " to test." + nl
	aResults = chessTrainAll(oMl,lQuick,"trained")
	gModels = chessModels()
	gLoaded = [:none = 0]
	showModels()
	fillModelBox()
	showPosition()
	oProgress.Value = 100
	oModelNote.Text += nl + "Done: the best model is " + aResults[1][3][2] + " [" + aResults[1][3][3] + "], " + chessPercent(aResults[1][1]) + " of the test positions."

# the progress after each algorithm (called by chessTrainAll)
func trained nAlgorithm, nAlgorithms, aAlgorithm, nExact, nNear, nSeconds

	oProgress.Value = floor(nAlgorithm / nAlgorithms * 100)
	oModelNote.Text += aAlgorithm[2] + " [" + aAlgorithm[3] + "]: " + chessPercent(nExact) + " (" + (floor(nSeconds * 10) / 10) + " seconds)" + nl
	oStatusText.Text = "Trained " + nAlgorithm + " of " + nAlgorithms
	new Application().DoEvents()

# the selected model on the test positions of data/test.csv
func testSelected

	if oModelList.SelectedIndices.Count = 0
		oModelNote.Text = "Select a model of the list first."
		return
	ok
	if not fexists("data/test.csv")
		oModelNote.Text = "There are no test positions yet: train the models first."
		return
	ok
	aModel = gModels[oModelList.SelectedIndices.Item(0) + 1]
	oModelNote.Text = "Testing " + aModel[2] + " [" + aModel[3] + "] ..."
	new Application().DoEvents()
	oModel = chessLoadModel(oMl,aModel)
	oTest = chessLoad(oMl,"data/test.csv")
	aActual = chessColumn(oTest,"System.String","GameResult")
	aPredicted = chessColumn(oModel.Transform(oTest),"System.String","PredictedResult")
	aAccuracy = chessAccuracy(aActual,aPredicted)
	nDraws = 0
	nFound = 0
	nTotal = len(aActual)
	for nPlace = 1 to nTotal
		if aActual[nPlace] = "draw"
			nDraws++
			if aPredicted[nPlace] = "draw"
				nFound++
			ok
		ok
	next
	oModelNote.Text = aModel[2] + " [" + aModel[3] + "] on " + nTotal + " test positions:" + nl + "exactly right: " + chessPercent(aAccuracy[1]) + nl + "within 1 move: " + chessPercent(aAccuracy[2]) + nl + "draws found: " + nFound + " of " + nDraws
