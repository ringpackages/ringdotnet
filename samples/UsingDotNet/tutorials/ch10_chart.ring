# a chart - turn numbers into a bar chart with UiCanvas, show it in a window and save it as a PNG
load "dotnet.ring"
using {
	"System"
	"System.IO"
	"System.Drawing"
	"System.Drawing.Imaging"
	"System.Windows.Forms"
}

C_WIDTH = 480
C_HEIGHT = 300

aLabels = ["Jan","Feb","Mar","Apr","May","Jun"]
aValues = [12,19,8,25,17,22]
aColors = ["SteelBlue","Orange","SeaGreen","Crimson","MediumPurple","Goldenrod"]

oForm = ""
oCanvas = ""

func main
	oForm = uiForm("Sales chart",C_WIDTH,C_HEIGHT + 36)
	oPicture = uiPictureBox(oForm,0,0,C_WIDTH,C_HEIGHT)
	oCanvas = new UiCanvas(oPicture)
	drawChart()
	uiButton(oForm,"Save as PNG",10,C_HEIGHT + 4,120,28,"savePng()")

	uiRun(oForm)

# ---------------------------------------------------------------- drawing

func drawChart
	nLeft = 50                                      # room for the numbers on the left
	nBottom = C_HEIGHT - 40                         # the y of the bottom axis
	nTop = 50
	nMax = maxOf(aValues)
	nScaleMax = niceMax(nMax)                       # the top of the vertical axis: a round number

	oCanvas.clear("White")
	oCanvas.text("Sales per month (thousands)",nLeft,12,"Black",13)

	# the horizontal grid lines with their numbers
	for nStep = 0 to 4
		nValue = nScaleMax * nStep / 4
		nY = nBottom - (nBottom - nTop) * nStep / 4
		oCanvas.line(nLeft,nY,C_WIDTH - 20,nY,"#DDDDDD",1)
		oCanvas.text("" + nValue,nLeft - 34,nY - 8,"#555555",9)
	next

	# one bar per value
	nBars = len(aValues)
	nSlot = (C_WIDTH - 20 - nLeft) / nBars          # the width of the place of one bar
	nBarWidth = nSlot * 0.6
	for nIndex = 1 to nBars
		nHeight = (nBottom - nTop) * aValues[nIndex] / nScaleMax
		nX = nLeft + (nIndex - 1) * nSlot + (nSlot - nBarWidth) / 2
		oCanvas.fillRect(nX,nBottom - nHeight,nBarWidth,nHeight,aColors[nIndex])
		oCanvas.text("" + aValues[nIndex],nX + 4,nBottom - nHeight - 18,"Black",10)
		oCanvas.text(aLabels[nIndex],nX + 2,nBottom + 6,"Black",10)
	next
	oCanvas.line(nLeft,nBottom,C_WIDTH - 20,nBottom,"Black",2)
	oCanvas.line(nLeft,nTop,nLeft,nBottom,"Black",2)
	oCanvas.show()

# the biggest value of a list
func maxOf aList
	nMax = aList[1]
	for nValue in aList
		if nValue > nMax
			nMax = nValue
		ok
	next
	return nMax

# the next "round" number at or above a value: 25 -> 30, 8 -> 10, 120 -> 150. Charts look better with round axes.
func niceMax nValue
	nPower = pow(10,floor(log10(nValue)))
	for nFactor in [1,1.5,2,3,4,5,6,8,10]
		if nFactor * nPower >= nValue
			return nFactor * nPower
		ok
	next
	return nValue

func savePng
	cFile = new Path().Combine([new Path().GetTempPath(),"sales-chart.png"])
	oCanvas.oBitmap.Save([ :filename = cFile, :format = new ImageFormat().Png ])
	uiMessage("Saved to " + cFile,"Chart")
