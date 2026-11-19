# the checks of main.ring: run with  ring main.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	dnAssert("default length",len(oPassword.Text),16)
	dnAssert("strong by default",oStrengthText.Text,"Strong")
	oLength.Value = 30
	generate()
	dnAssert("longer password",len(oPassword.Text),30)
	oUpper.Checked = False
	oDigits.Checked = False
	oSymbols.Checked = False
	oLength.Value = 20
	generate()
	dnAssert("only lower case",hasAny(oPassword.Text,"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#"),0)
	dnAssert("lower case letters present",hasAny(oPassword.Text,"abcdefghijklmnopqrstuvwxyz"),1)
	oLength.Value = 4
	generate()
	dnAssert("short and simple is weak",oStrengthText.Text,"Weak")
	oLower.Checked = False
	generate()
	dnAssert("no characters selected",oStrengthText.Text,"Choose at least one kind of characters")
	dnAssert("the random numbers are in range",secureRandom(10) < 10,True)
	nSeen = ""
	for x = 1 to 200
		nSeen += "" + secureRandom(3)
	next
	dnAssert("all values appear",substr(nSeen,"0") > 0 and substr(nSeen,"1") > 0 and substr(nSeen,"2") > 0,True)
