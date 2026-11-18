# Dice roller - draws five dice with their pips and keeps statistics

load "dotnet.ring"
using {
	"System.Drawing"
	"System.Windows.Forms"
}

C_DICE = 5
aDice = [1,1,1,1,1]
aCounts = list(6)
nRolls = 0

oForm = uiForm("Dice roller",420,330)
oForm {
	FormBorderStyle = "FixedSingle"
	MaximizeBox = False
}
oPicture = uiPictureBox(oForm,0,0,420,100)
oCanvas = new UiCanvas(oPicture)
uiButton(oForm,"Roll",10,110,100,34,"rollAll()")
uiButton(oForm,"Roll 1000 times",120,110,140,34,"rollMany(1000)")
oTotal = uiLabel(oForm,"",270,118,140,24)
oStats = uiLabel(oForm,"",10,155,400,150)
oStats.Font = uiFont("Consolas",10,false)
draw()

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

# --------------------------------------------------------------------------

# the pips of a die face: positions in a 3x3 grid
func pips nFace
	switch nFace
	on 1	return [5]
	on 2	return [1,9]
	on 3	return [1,5,9]
	on 4	return [1,3,7,9]
	on 5	return [1,3,5,7,9]
	on 6	return [1,3,4,6,7,9]
	off

func drawDie nIndex, nFace
	nX = 10 + (nIndex - 1) * 80
	oCanvas.fillRect(nX,10,70,70,"White")
	oCanvas.drawRect(nX,10,70,70,"Black")
	for nPip in pips(nFace)
		nRow = floor((nPip - 1) / 3)
		nCol = (nPip - 1) % 3
		oCanvas.fillCircle(nX + 15 + nCol * 20,25 + nRow * 20,6,"Black")
	next

func draw
	oCanvas.clear("#2e7d32")
	for nIndex = 1 to C_DICE
		drawDie(nIndex,aDice[nIndex])
	next
	nSum = 0
	for nFace in aDice
		nSum += nFace
	next
	oTotal.Text = "Total: " + nSum
	cText = "Rolls of a single die: " + nRolls + nl
	for nFace = 1 to 6
		nBar = 0
		if nRolls > 0
			nBar = floor(aCounts[nFace] * 30 / nRolls)
		ok
		cText += string(nFace) + ": " + copy("#",nBar) + " " + aCounts[nFace] + nl
	next
	oStats.Text = cText
	oCanvas.show()

func rollAll
	for nIndex = 1 to C_DICE
		aDice[nIndex] = random(5) + 1
		aCounts[aDice[nIndex]]++
		nRolls++
	next
	draw()

func rollMany nTimes
	for nTime = 1 to nTimes
		nFace = random(5) + 1
		aCounts[nFace]++
		nRolls++
	next
	draw()

func selfTest
	aDice = [1,2,3,4,6]
	draw()
	dnAssert("total",oTotal.Text,"Total: 16")
	dnAssert("the 1 has a center pip",oCanvas.pixel(10 + 35,25 + 20),"ff000000")
	dnAssert("the 1 has no corner pip",oCanvas.pixel(10 + 15,25),"ffffffff")
	dnAssert("the 6 has a pip in the middle row",oCanvas.pixel(10 + 4 * 80 + 15,25 + 20),"ff000000")
	dnAssert("pip counts",len(pips(1)) + len(pips(2)) + len(pips(3)) + len(pips(4)) + len(pips(5)) + len(pips(6)),21)
	rollAll()
	dnAssert("5 rolls counted",nRolls,5)
	rollMany(1000)
	dnAssert("1005 rolls",nRolls,1005)
	nSum = 0
	for nCount in aCounts
		nSum += nCount
	next
	dnAssert("statistics add up",nSum,1005)
	dnAssert("each face came up",aCounts[1] > 80 and aCounts[6] > 80,True)
	lValid = true
	for nFace in aDice
		if nFace < 1 or nFace > 6
			lValid = false
		ok
	next
	dnAssert("dice are between 1 and 6",lValid,1)
