# watching sorting algorithms - an animation, a timer and counting the work
load "dotnet.ring"

using {
	"System.Drawing"
	"System.Windows.Forms"
}

C_COUNT = 36
C_BAR = 12
C_HEIGHT = 300

oForm = ""
oPicture = ""
oCanvas = ""
oAlgorithm = ""
oInfo = ""
oTimer = ""
aValues = []              # the bars as they are shown now
aSteps = []               # the work of the algorithm: ["compare", i, j] or ["swap", i, j]
nStep = 0
nCompares = 0
nSwaps = 0
nSeed = 12345
aHot = []                 # the two bars that are touched by the step being shown

func main

	oForm = uiForm("Sorting",C_COUNT * C_BAR + 30,C_HEIGHT + 100)
	oPicture = uiPictureBox(oForm,5,5,C_COUNT * C_BAR,C_HEIGHT)
	oCanvas = new UiCanvas(oPicture)
	oAlgorithm = uiComboBox(oForm,10,C_HEIGHT + 20,130,["Bubble sort","Selection sort","Insertion sort"])
	uiButton(oForm,"Shuffle",150,C_HEIGHT + 18,80,28,"shuffle()")
	uiButton(oForm,"Sort",240,C_HEIGHT + 18,80,28,"startSorting()")
	oInfo = uiLabel(oForm,"",10,C_HEIGHT + 55,400,22)
	oTimer = uiTimer(15,"showStep()")
	shuffle()
	uiRun(oForm)

# a small random number generator with a fixed start, so that every run shows the same bars
func nextRandom nLimit

	nSeed = (nSeed * 1103515245 + 12345) % 2147483648
	return (floor(nSeed / 65536) % nLimit) + 1

func shuffle

	oTimer.Stop()
	aValues = []
	for nI = 1 to C_COUNT
		aValues + nI
	next
	for nI = C_COUNT to 2 step -1
		nJ = nextRandom(nI)
		aTemp = aValues[nI]
		aValues[nI] = aValues[nJ]
		aValues[nJ] = aTemp
	next
	aSteps = []
	nStep = 0
	nCompares = 0
	nSwaps = 0
	aHot = []
	oInfo.Text = "Press Sort"
	draw()

# the algorithms only RECORD what they do on a copy; the timer replays it step by step
func startSorting

	oTimer.Stop()
	aWork = aValues
	aSteps = []
	nStep = 0
	nCompares = 0
	nSwaps = 0
	switch oAlgorithm.SelectedIndex
	on 0
		bubbleSort(aWork)
	on 1
		selectionSort(aWork)
	on 2
		insertionSort(aWork)
	off
	oTimer.Start()

func bubbleSort aWork

	for nEnd = len(aWork) to 2 step -1
		for nI = 1 to nEnd - 1
			aSteps + ["compare",nI,nI + 1]
			if aWork[nI] > aWork[nI + 1]
				aTemp = aWork[nI]
				aWork[nI] = aWork[nI + 1]
				aWork[nI + 1] = aTemp
				aSteps + ["swap",nI,nI + 1]
			ok
		next
	next

func selectionSort aWork

	for nI = 1 to len(aWork) - 1
		nMin = nI
		for nJ = nI + 1 to len(aWork)
			aSteps + ["compare",nMin,nJ]
			if aWork[nJ] < aWork[nMin]
				nMin = nJ
			ok
		next
		if nMin != nI
			aTemp = aWork[nI]
			aWork[nI] = aWork[nMin]
			aWork[nMin] = aTemp
			aSteps + ["swap",nI,nMin]
		ok
	next

func insertionSort aWork

	for nI = 2 to len(aWork)
		nJ = nI
		while nJ > 1
			aSteps + ["compare",nJ - 1,nJ]
			if aWork[nJ - 1] > aWork[nJ]
				aTemp = aWork[nJ]
				aWork[nJ] = aWork[nJ - 1]
				aWork[nJ - 1] = aTemp
				aSteps + ["swap",nJ - 1,nJ]
				nJ--
			else
				exit
			ok
		end
	next

# show the next recorded step (the timer calls this)
func showStep

	if nStep >= len(aSteps)
		oTimer.Stop()
		aHot = []
		oInfo.Text = "Sorted: " + nCompares + " comparisons, " + nSwaps + " swaps"
		draw()
		return
	ok
	nStep++
	aStep = aSteps[nStep]
	aHot = [aStep[2],aStep[3]]
	if aStep[1] = "compare"
		nCompares++
	else
		nSwaps++
		aTemp = aValues[aStep[2]]
		aValues[aStep[2]] = aValues[aStep[3]]
		aValues[aStep[3]] = aTemp
	ok
	oInfo.Text = oAlgorithm.Text + ": " + nCompares + " comparisons, " + nSwaps + " swaps"
	draw()

func draw

	oCanvas.clear("White")
	for nI = 1 to len(aValues)
		nHeight = aValues[nI] * (C_HEIGHT - 10) / C_COUNT
		cColor = "SteelBlue"
		if find(aHot,nI) > 0
			cColor = "OrangeRed"
		ok
		oCanvas.fillRect((nI - 1) * C_BAR + 1,C_HEIGHT - nHeight,C_BAR - 2,nHeight,cColor)
	next
	oCanvas.show()
