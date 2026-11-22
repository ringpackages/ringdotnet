# DiffPlex: the differences between two texts, line by line and in a side-by-side view
load "pkg.ring"
pkgUse("diffplex",[["DiffPlex","1.9.0"]],[["DiffPlex.dll",["DiffPlex","DiffPlex.DiffBuilder","DiffPlex.DiffBuilder.Model","DiffPlex.Model"]]])
pkgImport("diffplex","DiffPlex.dll","DiffPlex")
pkgImport("diffplex","DiffPlex.dll","DiffPlex.DiffBuilder")
pkgImport("diffplex","DiffPlex.dll","DiffPlex.DiffBuilder.Model")
pkgImport("diffplex","DiffPlex.dll","DiffPlex.Model")

cOld = "one" + nl + "two" + nl + "three" + nl + "four"
cNew = "one" + nl + "2" + nl + "three" + nl + "four" + nl + "five"

# the blocks of changes
oDiffer = new Differ()
oResult = dnRequest("callnamed",[oDiffer,"CreateLineDiffs",[ ["oldText",cOld], ["newText",cNew], ["ignoreWhitespace",0] ]])
aBlocks = oResult.DiffBlocks.toList()
dnAssert("two blocks of changes",len(aBlocks),2)
dnAssert("the first block starts at the second line (0 based)",aBlocks[1].DeleteStartA,1)
dnAssert("the first block deletes one line",aBlocks[1].DeleteCountA,1)
dnAssert("the first block inserts one line",aBlocks[1].InsertCountB,1)
dnAssert("the pieces of both texts",len(oResult.PiecesOld.toList()),4)
dnAssert("the pieces of the new text",len(oResult.PiecesNew.toList()),5)

# the side-by-side view: a model for each text, every line has a type
oSideBySide = new SideBySideDiffBuilder().@New(oDiffer)
oModel = oSideBySide.BuildDiffModel([ :oldText = cOld, :newText = cNew, :ignoreWhitespace = 0 ])
aOldLines = oModel.OldText.Lines.toList()
aNewLines = oModel.NewText.Lines.toList()
dnAssert("both sides have as many lines as the new text (an imaginary line is aligned with the added one)",len(aOldLines),5)
dnAssert("the types of the old lines",aOldLines[1].Type + "," + aOldLines[2].Type,"Unchanged,Modified")
dnAssert("a line was added at the end of the new text",aNewLines[5].Type,"Inserted")
dnAssert("the text of a changed line",aNewLines[2].Text,"2")

# identical texts have no change
oSame = oSideBySide.BuildDiffModel([ :oldText = cOld, :newText = cOld, :ignoreWhitespace = 0 ])
dnAssert("no change in identical texts",oSame.OldText.HasDifferences,0)

dnTestSummary()
