# Word counter - live statistics of the text and the most frequent words (uses a .NET Regex and Dictionary)

load "dotnet.ring"
using {
	"System.Text.RegularExpressions"
	"System.Collections.Generic"
	"System.Linq"
	"System.Drawing"
	"System.Windows.Forms"
}

oForm = uiForm("Word counter",620,420)
oText = uiMemo(oForm,10,10,380,400)
oText {
	WordWrap = True
	ScrollBars = "Vertical"
}
oStats = uiLabel(oForm,"",400,10,210,120)
oStats.Font = uiFont("Segoe UI",10,false)
uiLabel(oForm,"Most frequent words",400,140,200,20)
oTop = uiListBox(oForm,400,162,210,248)
oText.setTextChangedEvent("update()")
update()

uiRun(oForm)

# --------------------------------------------------------------------------

# the words of a text (letters and digits, lower case)
func wordsOf cText
	oMatches = new Regex("[\p{L}\p{N}']+").Matches(cText)
	aWords = []
	for oMatch in oMatches.toList()
		aWords + lower(oMatch.Value)
	next
	return aWords

func update
	cText = oText.Text
	aWords = wordsOf(cText)
	nChars = len(cText)
	nLines = 0
	if cText != ""
		nLines = len(str2list(cText))
	ok
	oStats.Text = "Characters: " + nChars + nl + "Words: " + len(aWords) + nl + "Lines: " + nLines + nl + "Unique words: " + len(uniqueWords(aWords))
	oTop.Items.Clear()
	aCounts = countWords(aWords)
	nShown = 0
	for nIndex = len(aCounts) to 1 step -1
		if nShown < 10
			oTop.Items.Add(aCounts[nIndex][1] + "  x" + aCounts[nIndex][2])
			nShown++
		ok
	next

func uniqueWords aWords
	return dnQuery(aWords).Distinct().ToList()

# [[word, count], ...] sorted by count: the most frequent word is the last one
func countWords aWords
	oCounts = new NumberDictionary()
	for cWord in aWords
		aGot = oCounts.TryGetValue(cWord)
		nOld = 0
		if aGot[1]
			nOld = aGot[2]
		ok
		oCounts.SetItem(cWord,nOld + 1)
	next
	aList = []
	for oPair in oCounts.toList()
		aList + [oPair.Key,oPair.Value]
	next
	return sort(aList,2)
