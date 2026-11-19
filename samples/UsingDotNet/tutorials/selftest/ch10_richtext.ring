# the checks of ch10_richtext.ring: run with  ring ch10_richtext.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

# Selection: SelectionStart is the first character (counted from 0) and SelectionLength how many. Everything that is set through
# SelectionFont or SelectionColor applies to the selected part only.
func selectWord cWord
	nStart = oRich.Find(cWord)                      # the place of the first match, or -1
	if nStart < 0
		oStatus.Text = "'" + cWord + "' was not found"
		return False
	ok
	oRich.Select([ :start = nStart, :length = len(cWord) ])
	return True

func selfTest
	# finding and selecting a word
	dnAssert("find a word",oRich.Find("Ring"),0)
	dnAssert("a missing word",oRich.Find("zebra"),-1)

	# bold: select "bold" and click the button
	selectWord("bold")
	dnAssert("the selection",oRich.SelectedText,"bold")
	dnAssert("not bold before",oRich.SelectionFont.Bold,False)
	oBold.PerformClick()
	dnAssert("bold after",oRich.SelectionFont.Bold,True)
	oBold.PerformClick()
	dnAssert("bold off again",oRich.SelectionFont.Bold,False)
	oBold.PerformClick()

	# color: another word
	selectWord("red")
	makeRed()
	dnAssert("the color",oRich.SelectionColor.Name,"Red")

	# the text itself is unchanged by the formatting, but the RTF text has the codes
	dnAssert("the plain text is the same",left(oRich.Text,15),"Ring talks to .")
	dnAssert("the RTF has the bold code",substr(oRich.Rtf,"\b") > 0,True)
	dnAssert("the RTF has a color table",substr(oRich.Rtf,"\colortbl") > 0,True)

	# find all: by default the search does not care about upper and lower case, so "ring" finds "Ring" and "ring" (the option MatchCase
	# in findAll would find one)
	oFind.Text = "ring"
	findAll()
	dnAssert("find all",oStatus.Text,"Found 2 times")

	# save as RTF and load it again into a second box: the formatting stays
	cFile = new Path().Combine([ new Path().GetTempPath(),"ringdotnet-rich.rtf" ])
	oRich.SaveFile([ :path = cFile, :fileType = "RichText" ])
	oOther = new RichTextBox()
	oOther.LoadFile([ :path = cFile, :fileType = "RichText" ])
	dnAssert("the same text",oOther.Text,oRich.Text)
	oOther.Select([ :start = oOther.Find("bold"), :length = 4 ])
	dnAssert("the bold is saved",oOther.SelectionFont.Bold,True)
	new File().Delete(cFile)
