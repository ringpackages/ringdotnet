# BMI calculator with history (a port of ring/applications/bmicalculator to RingDotNet)

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
dnImport("System.Drawing")
dnImport("System.Windows.Forms")

aHistory = []

oForm = uiForm("BMI calculator",340,360)
oForm.FormBorderStyle = "FixedDialog"
oForm.MaximizeBox = 0
uiLabel(oForm,"Units",15,15,90,24)
oUnits = uiComboBox(oForm,110,12,200,["Metric (kg, cm)","Imperial (lb, in)"])
oWeightLabel = uiLabel(oForm,"Weight (kg)",15,50,90,24)
oWeight = uiTextBox(oForm,110,48,200,26)
oHeightLabel = uiLabel(oForm,"Height (cm)",15,85,90,24)
oHeight = uiTextBox(oForm,110,83,200,26)
uiButton(oForm,"Calculate",110,120,95,30,"calculate()")
uiButton(oForm,"Clear history",215,120,95,30,"oHistory.Items.Clear() aHistory = []")
oBmi = uiLabel(oForm,"",15,160,300,34)
oBmi.Font = uiFont("Segoe UI",16,true)
oCategory = uiLabel(oForm,"",15,195,300,24)
oHistory = uiListBox(oForm,15,230,300,115)
oUnits.setSelectedIndexChangedEvent("unitsChanged()")

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

# --------------------------------------------------------------------------

func bmi nKilograms, nMeters
	return nKilograms / (nMeters * nMeters)

func category nBmi
	if nBmi < 18.5
		return "Underweight"
	but nBmi < 25
		return "Normal weight"
	but nBmi < 30
		return "Overweight"
	ok
	return "Obese"

func unitsChanged
	if oUnits.SelectedIndex = 0
		oWeightLabel.Text = "Weight (kg)"
		oHeightLabel.Text = "Height (cm)"
	else
		oWeightLabel.Text = "Weight (lb)"
		oHeightLabel.Text = "Height (in)"
	ok

func calculate
	nWeight = number(oWeight.Text)
	nHeight = number(oHeight.Text)
	if nWeight <= 0 or nHeight <= 0
		oBmi.Text = "Enter a weight and a height"
		oCategory.Text = ""
		return
	ok
	if oUnits.SelectedIndex = 0
		nKilograms = nWeight
		nMeters = nHeight / 100
	else
		nKilograms = nWeight * 0.45359237
		nMeters = nHeight * 0.0254
	ok
	nValue = bmi(nKilograms,nMeters)
	oBmi.Text = "BMI " + uiNumber(floor(nValue * 10 + 0.5) / 10)
	oCategory.Text = category(nValue)
	cLine = oBmi.Text + " - " + oCategory.Text
	aHistory + cLine
	oHistory.Items.Insert(0,cLine)

func selfTest
	dnAssert("category underweight",category(17),"Underweight")
	dnAssert("category normal",category(22),"Normal weight")
	dnAssert("category overweight",category(27),"Overweight")
	dnAssert("category obese",category(35),"Obese")
	oWeight.Text = "70"
	oHeight.Text = "175"
	calculate()
	dnAssert("metric BMI",oBmi.Text,"BMI 22.9")
	dnAssert("metric category",oCategory.Text,"Normal weight")
	oUnits.SelectedIndex = 1
	dnAssert("labels follow the units",oWeightLabel.Text,"Weight (lb)")
	oWeight.Text = "220"
	oHeight.Text = "70"
	calculate()
	dnAssert("imperial BMI",oBmi.Text,"BMI 31.6")
	dnAssert("imperial category",oCategory.Text,"Obese")
	dnAssert("history",oHistory.Items.Count,2)
	oWeight.Text = ""
	calculate()
	dnAssert("empty input",oBmi.Text,"Enter a weight and a height")
