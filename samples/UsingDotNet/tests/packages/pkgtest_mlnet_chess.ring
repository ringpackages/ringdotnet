# The chess end game example (samples/UsingDotNet/tests/packages/ChessEndgame): its programs are run as a user runs them: train.ring --quick (a split of 70 and 30 percent, three
# algorithms, the models saved), evaluate.ring (the saved models tested), and predict.ring (the result of positions). The example restores ML.NET into its own folder.
load "pkg.ring"

cExample = cPkgHere + "/ChessEndgame"
chdir(cExample)
cRing = exefilename()

# ---- train.ring --quick
cOutput = run(cRing + " train.ring --quick")
dnAssert("the example gets ML.NET and trains (no error)",substr(cOutput,"Error") + substr(cOutput,"error"),0)
dnAssert("the positions are split: 70 percent to train",substr(cOutput,"positions to train the models: 2805 (70%)") > 0,1)
dnAssert("and 30 percent to test",substr(cOutput,"positions to test them:        1203 (30%)") > 0,1)
dnAssert("the logistic regression was tried",substr(cOutput,"Logistic regression (SDCA)") > 0,1)
dnAssert("the decision tree was tried",substr(cOutput,"Decision tree (one versus all)") > 0,1)
dnAssert("LightGBM was tried",substr(cOutput,"LightGBM (boosted trees)") > 0,1)
dnAssert("the ranking is printed",substr(cOutput,"the ranking on the test positions") > 0,1)

# the two files of the split: the header and the positions, with no position in both
aTrain = str2list(read("data/train.csv"))
aTest = str2list(read("data/test.csv"))
dnAssert("the training file has a header and 2805 positions",len(aTrain),2806)
dnAssert("the test file has a header and 1203 positions",len(aTest),1204)
dnAssert("the header has the features and the result",right(aTrain[1],10),"GameResult")
aSeen = [:x = 0]
for nLine = 2 to len(aTrain)
	aParts = str2list(substr(aTrain[nLine],",",nl))
	aSeen[aParts[1] + "," + aParts[2] + "," + aParts[3] + "," + aParts[4] + "," + aParts[5] + "," + aParts[6]] = 1
next
nShared = 0
for nLine = 2 to len(aTest)
	aParts = str2list(substr(aTest[nLine],",",nl))
	if isnumber(aSeen[aParts[1] + "," + aParts[2] + "," + aParts[3] + "," + aParts[4] + "," + aParts[5] + "," + aParts[6]])
		nShared++
	ok
next
dnAssert("no position is in both files",nShared,0)

# the models: a file for each algorithm, and the index with the accuracy (the best first)
dnAssert("the model of the logistic regression was saved",fexists("models/logistic_onehot.zip"),1)
dnAssert("the model of the decision tree was saved",fexists("models/tree_engineered.zip"),1)
dnAssert("the model of LightGBM was saved",fexists("models/lightgbm_engineered.zip"),1)
aIndex = str2list(read("models/index.txt"))
aBest = str2list(substr(aIndex[1],"|",nl))
aLast = str2list(substr(aIndex[3],"|",nl))
dnAssert("the best model is LightGBM",aBest[1],"lightgbm")
dnAssert("the best model gets more than half of the test positions right",number(aBest[4]) / 100000 > 0.5,1)
dnAssert("and is within one move for most of them",number(aBest[5]) / 100000 > 0.75,1)
dnAssert("the index is sorted by accuracy",number(aBest[4]) >= number(aLast[4]),1)

# ---- evaluate.ring: the saved models tested again; the answers are the same as the ones of train.ring
cOutput = run(cRing + " evaluate.ring")
dnAssert("evaluate.ring read the test positions",substr(cOutput,"test positions: 1203") > 0,1)
dnAssert("it tested the saved model of LightGBM",substr(cOutput,"LightGBM (boosted trees) [engineered]") > 0,1)
dnAssert("it gives the best model result by result",substr(cOutput,"result by result") > 0,1)
dnAssert("a draw is a result of the list",substr(cOutput,"draw") > 0,1)
dnAssert("and the answers for the wins",substr(cOutput,"exactly right:") > 0,1)
nTenths = floor(number(aBest[4]) / 100 + 0.5)
cAccuracy = "" + floor(nTenths / 10) + "." + (nTenths % 10)
dnAssert("the accuracy of the saved model is the one that train.ring measured",substr(cOutput,cAccuracy + "%") > 0,1)

# ---- predict.ring: the result of positions
cOutput = run(cRing + " predict.ring e4 e1 h8")
dnAssert("predict.ring uses the best model",substr(cOutput,"LightGBM (boosted trees) [engineered]") > 0,1)
dnAssert("the board is drawn",substr(cOutput,"    a b c d e f g h") > 0,1)
dnAssert("the pieces are on the board",substr(cOutput,"K") > 0 and substr(cOutput,"R") > 0 and substr(cOutput,"k") > 0,1)
dnAssert("a position that white wins: the model says white wins",substr(cOutput,"the model says: white wins in") > 0,1)
cOutput = run(cRing + " predict.ring e4 e1 h8 --model=logistic_onehot")
dnAssert("another saved model can be chosen",substr(cOutput,"the model: logistic_onehot") > 0,1)
dnAssert("it gives an answer too",substr(cOutput,"the model says:") > 0,1)
cOutput = run(cRing + " predict.ring a1 b3 c2 f6 g7 h8")
dnAssert("two positions are two answers",substr(cOutput,"the model says:") > 0 and substr(cOutput,"white king f6") > 0,1)
cOutput = run(cRing + " predict.ring e4 e1 h8")
cMirror = run(cRing + " predict.ring d5 d8 a1")          # the same position turned half a turn: the same answer
dnAssert("a position and the same position turned give the same answer",substr(cOutput,"the model says:") > 0 and right(trim(cOutput),20) = right(trim(cMirror),20),1)
cOutput = run(cRing + " predict.ring a1 a1 c2")
dnAssert("two pieces on the same square are not a position",substr(cOutput,"not a position") > 0,1)
cOutput = run(cRing + " predict.ring a1 b3 b2")
dnAssert("kings that touch each other are called impossible",substr(cOutput,"the kings touch each other") > 0,1)
cOutput = run(cRing + " predict.ring")
dnAssert("without squares it shows positions of the test file",substr(cOutput,"real result") > 0 and substr(cOutput,"the model says") > 0,1)
# ---- the window (Windows only: Windows Forms): it tests itself with the models that were just made
if iswindows()
	cOutput = run(cRing + " ChessEndgame.ring --selftest")
	dnAssert("the window tests itself",substr(cOutput,"SELFTEST OK") > 0,1)
ok
dnTestSummary()

# Run a command and give what it prints (the output goes to a file)
func run cCommand

	system(cCommand + " > chess_output.txt 2>&1")
	return read("chess_output.txt")
