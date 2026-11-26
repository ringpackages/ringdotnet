# the checks of ChessEndgame.ring: run with  ring ChessEndgame.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	# the data, and the result of a position
	dnAssert("the data has 28056 positions",len(gRows),28056)
	dnAssert("the statistics count them all",gCounts[1] + gCounts[2] + gCounts[3] + gCounts[4] + gCounts[5] + gCounts[6] + gCounts[7] + gCounts[8] + gCounts[9] + gCounts[10] + gCounts[11] + gCounts[12] + gCounts[13] + gCounts[14] + gCounts[15] + gCounts[16] + gCounts[17] + gCounts[18],28056)
	dnAssert("the table of the statistics has a row for each result",oStatList.Items.Count,18)
	dnAssert("a position of the data is known",knownResult([1,1],[2,3],[3,2]),"draw")
	dnAssert("the same position turned half a turn is known too",knownResult([8,8],[7,6],[6,7]),"draw")
	dnAssert("a position that the data does not have",knownResult([1,1],[1,1],[3,2]),"")
	dnAssert("the tabs",oTabs.TabPages.Count,4)

	# the board: the pieces are dragged with the mouse
	gPiece = [[1,1],[2,3],[3,2]]
	showPosition()
	dnAssert("the box of the white king shows its square",oKingBox.Text,"a1")
	dnAssert("the box of the white rook shows its square",oRookBox.Text,"b3")
	dnAssert("the pixels of the board are drawn",oCanvas.pixel(C_LEFT + 5 * C_CELL + 4,C_TOP + 4) != oCanvas.pixel(C_LEFT + 4 * C_CELL + 4,C_TOP + 4),true)
	boardDown(C_LEFT + 4 * C_CELL + 10,C_TOP + 6 * C_CELL + 10)          # the rook b3 is not here: nothing to drag
	dnAssert("an empty square drags nothing",gDrag,0)
	boardDown(C_LEFT + 1 * C_CELL + 10,C_TOP + 5 * C_CELL + 10)          # the white rook on b3
	dnAssert("a piece is picked",gDrag,2)
	boardMove(C_LEFT + 4 * C_CELL + 10,C_TOP + 4 * C_CELL + 10)
	boardUp(C_LEFT + 4 * C_CELL + 10,C_TOP + 4 * C_CELL + 10)          # dropped on e4
	dnAssert("the piece is on the new square",squareName(gPiece[2]),"e4")
	dnAssert("the box follows the board",oRookBox.Text,"e4")
	boardDown(C_LEFT + 4 * C_CELL + 10,C_TOP + 4 * C_CELL + 10)
	boardUp(C_LEFT + 10,C_TOP + 10 + 7 * C_CELL)          # dropped on the square of the white king (a1): not allowed
	dnAssert("a piece does not go to a square that is taken",squareName(gPiece[2]),"e4")
	boardDown(C_LEFT + 4 * C_CELL + 10,C_TOP + 4 * C_CELL + 10)
	boardUp(2,2)          # dropped outside the board
	dnAssert("a piece dropped outside the board stays",squareName(gPiece[2]),"e4")
	oBlackBox.SelectedIndex = 7 * 8 + 7          # the black king is moved with its box: h8
	dnAssert("the box moves the piece",squareName(gPiece[3]),"h8")
	cBefore = oCanvas.pixel(C_LEFT + 7 * C_CELL + 25,C_TOP + 25)
	oBlackBox.SelectedIndex = 0 * 8 + 4          # the black king goes to a5 with its box
	dnAssert("the board is drawn again when a box changes",oCanvas.pixel(C_LEFT + 25,C_TOP + 3 * C_CELL + 25) != cBefore or oCanvas.pixel(C_LEFT + 7 * C_CELL + 25,C_TOP + 25) != cBefore,true)
	dnAssert("the old square of the king is empty again",oCanvas.pixel(C_LEFT + 7 * C_CELL + 25,C_TOP + 25) != cBefore,true)
	dnAssert("a position that is not in the game: the kings touch",chessDistance(1,1,2,2) <= 1,true)

	# random positions are positions of a game
	for nTry = 1 to 20
		randomPosition()
		dnAssert("random: the kings do not touch",chessDistance(gPiece[1][1],gPiece[1][2],gPiece[3][1],gPiece[3][2]) > 1,true)
		dnAssert("random: the pieces are on different squares",pieceAt(gPiece[2]) = 2 and pieceAt(gPiece[1]) = 1 and pieceAt(gPiece[3]) = 3,true)
	next
	dataPosition()
	dnAssert("a position of the data is shown with its result",left(oReal.Text,14),"The data says:")

	# the data tab: the filter and the pages (the controls of a tab are made when it is shown)
	oTabs.SelectedIndex = 1
	dnAssert("the first page has 500 rows",oRowList.Items.Count,500)
	oFilterBox.SelectedIndex = 1          # draw
	dnAssert("the filter keeps the draws",len(gFilter),gCounts[1])
	dnAssert("the rows of the page are draws",oRowList.Items.Item(0).SubItems.Item(4).Text,"a draw")
	pageMove(1)
	dnAssert("the next page",gPage,2)
	oFilterBox.SelectedIndex = 0
	dnAssert("a new filter starts at the first page",gPage,1)
	oRowList.Items.Item(2).Selected = true
	showSelectedRow()
	dnAssert("a row of the data goes to the board",oTabs.SelectedIndex,0)
	dnAssert("with the squares of the row",squareName(gPiece[1]),gRows[3][1])

	# the statistics: a row selected colors its bar
	oTabs.SelectedIndex = 2
	oStatList.Items.Item(3).Selected = true
	dnAssert("a row is selected in the statistics",oStatList.SelectedIndices.Count,1)

	# the models: they come from the files of the example (a quick training if there are none)
	oTabs.SelectedIndex = 3
	if len(gModels) = 0
		trainModels(true)
	ok
	dnAssert("there are models",len(gModels) > 0,true)
	dnAssert("the list of the models",oModelList.Items.Count,len(gModels))
	dnAssert("the box of the models",oModelBox.Items.Count,len(gModels))
	gPiece = [[5,4],[5,1],[8,8]]
	oModelBox.SelectedIndex = 0
	showPosition()
	dnAssert("the model answers",left(oAnswer.Text,15),"The model says:")
	dnAssert("and the data answers",left(oReal.Text,14),"The data says:")
	dnAssert("the verdict is given",len(oVerdict.Text) > 0,true)
	cFirst = oAnswer.Text
	gPiece = [[4,5],[4,8],[1,1]]          # the same position turned half a turn (d5 d8 a1)
	showPosition()
	dnAssert("a position turned gives the same answer",oAnswer.Text,cFirst)
	askAll()
	dnAssert("all the models answer",oAll.Items.Count,len(gModels))
	oModelList.Items.Item(0).Selected = true
	testSelected()
	oTabs.SelectedIndex = 0
	dnAssert("the test of a model",substr(oModelNote.Text,"exactly right") > 0 or substr(oModelNote.Text,"no test positions") > 0,true)
