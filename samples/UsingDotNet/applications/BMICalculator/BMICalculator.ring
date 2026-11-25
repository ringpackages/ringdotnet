# BMI calculator with history (a port of ring/applications/bmicalculator to RingDotNet)

load "dotnet.ring"

using {
	"System.Drawing"
	"System.Windows.Forms"
}

aHistory = []

oForm = uiForm("BMI calculator",340,360)
oForm {
	FormBorderStyle = "FixedDialog"
	MaximizeBox = False
}
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

uiRun(oForm)

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
	but oUnits.SelectedIndex = 0
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
