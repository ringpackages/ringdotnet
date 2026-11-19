# the checks of 14_richtextbox.ring: run with  ring 14_richtextbox.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	oRich.Select([ :start = 0, :length = 4 ])
	oRich.SelectionColor = uiColor("Red")
	oBoldFont = uiFont("Segoe UI",14,true)
	oRich.SelectionFont = oBoldFont
	oRich.Select([ :start = 9, :length = 4 ])
	oRich.SelectionColor = uiColor("Blue")
	oRich.Select([ :start = 0, :length = 0 ])
	dnAssert("text is kept",oRich.Text,"Ring and .NET make a good team")
	oRich.Select([ :start = 1, :length = 1 ])
	dnAssert("first word is red",oRich.SelectionColor.Name,"Red")
	dnAssert("rtf has formatting",substr(oRich.Rtf,"\b") > 0,True)
