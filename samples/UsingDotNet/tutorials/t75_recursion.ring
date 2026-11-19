# recursion - a function that calls itself: factorial, the Hanoi towers, permutations, a folder tree and a flood fill
load "dotnet.ring"
using {
	"System"
	"System.IO"
}

nMoves = 0

func main
	# 1. Recursion = a function solves a big problem by solving a smaller one with itself. It needs a STOP: a case that is answered directly.
	? "1. factorial(5) = " + factorial(5) + "   (5 * factorial(4), ..., and factorial(1) = 1 stops it)"
	? "   sum of the numbers 1..100 = " + sumTo(100)

	# 2. The danger: a recursion without a stop (or too deep) never ends. Count the depth to see how the calls pile up.
	? nl + "2. the depth of the calls for countdown(5):"
	countdown(5,0)

	# 3. Towers of Hanoi: move n discs from one peg to another, one at a time, never a bigger disc on a smaller one.
	#    To move n discs: move n-1 out of the way, move the biggest, move the n-1 back on top. The solution writes itself.
	? nl + "3. 3 discs from A to C:"
	hanoi(3,"A","C","B")
	? "   moves needed: " + nMoves + " (2^3 - 1); for 10 discs: " + (pow(2,10) - 1) + ", for 64 discs about 18 quintillion (the legend says the world ends when the monks finish)"

	# 4. Permutations: all the orders of a list. Choose the first item, then permute the rest.
	aPermutations = permutations(["a","b","c"])
	? nl + "4. the " + len(aPermutations) + " orders of a, b, c: " + joinWith(aPermutations,", ")

	# 5. A tree: a folder holds files and folders that hold files and folders... A recursive function walks it.
	cRoot = new Path().Combine([new Path().GetTempPath(),"tutorial75"])
	makeTree(cRoot)
	? nl + "5. the folder tree:"
	showTree(cRoot,0)
	? "   the total size of the files: " + folderSize(cRoot) + " bytes"
	new Directory().Delete([ :path = cRoot, :recursive = True ])

	# 6. A flood fill: color an area, then do the same for the four neighbours. (The "paint bucket" of a drawing program.)
	aImage = ["..#####..","..#...#..","..#...#..","..#####..","........."]
	? nl + "6. fill the inside of the frame, starting at row 2, column 4:"
	aGrid = []
	for cRow in aImage
		aLine = []
		for nCol = 1 to len(cRow)
			aLine + substr(cRow,nCol,1)
		next
		aGrid + aLine
	next
	nFilled = fill(aGrid,2,4)
	for aLine in aGrid
		? "   " + joinWith(aLine,"")
	next
	? "   " + nFilled + " cells filled; the outside of the frame stayed empty"

# factorial(n) = n * factorial(n - 1); factorial(1) = 1
func factorial n
	if n <= 1
		return 1
	ok
	return n * factorial(n - 1)

func sumTo n
	if n = 0
		return 0
	ok
	return n + sumTo(n - 1)

func countdown n, nDepth
	? "   " + copy("  ",nDepth) + "countdown(" + n + ")"
	if n > 0
		countdown(n - 1,nDepth + 1)
	ok

func hanoi n, cFrom, cTo, cVia
	if n = 0
		return
	ok
	hanoi(n - 1,cFrom,cVia,cTo)                     # the smaller tower out of the way
	nMoves++
	? "   disc " + n + " from " + cFrom + " to " + cTo
	hanoi(n - 1,cVia,cTo,cFrom)                     # and back on top

# all the orders of a list of letters, as texts
func permutations aItems
	if len(aItems) <= 1
		return aItems
	ok
	aResult = []
	for nIndex = 1 to len(aItems)
		aRest = []
		for nOther = 1 to len(aItems)
			if nOther != nIndex
				aRest + aItems[nOther]
			ok
		next
		aShorter = permutations(aRest)
		for cEnd in aShorter
			aResult + (aItems[nIndex] + cEnd)
		next
	next
	return aResult

func makeTree cRoot
	new Directory().CreateDirectory(new Path().Combine([cRoot,"docs"]))
	new Directory().CreateDirectory(new Path().Combine([cRoot,"docs","old"]))
	new Directory().CreateDirectory(new Path().Combine([cRoot,"src"]))
	new File().WriteAllText([ :path = new Path().Combine([cRoot,"readme.txt"]), :contents = "hello" ])
	new File().WriteAllText([ :path = new Path().Combine([cRoot,"docs/guide.txt"]), :contents = "guide text" ])
	new File().WriteAllText([ :path = new Path().Combine([cRoot,"docs","old","v1.txt"]), :contents = "old" ])
	new File().WriteAllText([ :path = new Path().Combine([cRoot,"src/main.ring"]), :contents = "? 1" ])

func showTree cFolder, nLevel
	? "   " + copy("   ",nLevel) + new Path().GetFileName(cFolder) + "/"
	aFolders = sort(new Directory().GetDirectories(cFolder).toList())
	for cSub in aFolders
		showTree(cSub,nLevel + 1)                  # the recursive step: the same work for each subfolder
	next
	aFiles = sort(new Directory().GetFiles(cFolder).toList())
	for cFile in aFiles
		? "   " + copy("   ",nLevel + 1) + new Path().GetFileName(cFile)
	next

func folderSize cFolder
	nTotal = 0
	aFiles = new Directory().GetFiles(cFolder).toList()
	for cFile in aFiles
		nTotal += new FileInfo(cFile).Length
	next
	aFolders = new Directory().GetDirectories(cFolder).toList()
	for cSub in aFolders
		nTotal += folderSize(cSub)
	next
	return nTotal

# fill the empty cells ('.') that touch the cell (nRow, nCol), turning them into '*'. Returns how many cells were filled.
func fill aGrid, nRow, nCol
	if nRow < 1 or nRow > len(aGrid) or nCol < 1 or nCol > len(aGrid[1])
		return 0
	ok
	if aGrid[nRow][nCol] != "."
		return 0
	ok
	aGrid[nRow][nCol] = "*"
	return 1 + fill(aGrid,nRow - 1,nCol) + fill(aGrid,nRow + 1,nCol) + fill(aGrid,nRow,nCol - 1) + fill(aGrid,nRow,nCol + 1)

func joinWith aList, cSeparator
	cText = ""
	for cItem in aList
		if cText != ""
			cText += cSeparator
		ok
		cText += cItem
	next
	return cText
