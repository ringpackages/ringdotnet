# Unit converter - length, weight, volume and temperature

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
using {
	"System.Drawing"
	"System.Windows.Forms"
}

# each category: [name, [[unit, factor to the base unit], ...]] (temperature is handled separately)
aCategories = [
	["Length",[["Meter",1],["Kilometer",1000],["Centimeter",0.01],["Millimeter",0.001],["Mile",1609.344],["Yard",0.9144],["Foot",0.3048],["Inch",0.0254]]],
	["Weight",[["Kilogram",1],["Gram",0.001],["Milligram",0.000001],["Pound",0.45359237],["Ounce",0.028349523125],["Ton",1000]]],
	["Volume",[["Liter",1],["Milliliter",0.001],["Cubic meter",1000],["Gallon (US)",3.785411784],["Quart (US)",0.946352946],["Cup (US)",0.2365882365]]],
	["Temperature",[["Celsius",0],["Fahrenheit",0],["Kelvin",0]]]
]

oForm = uiForm("Unit converter",420,200)
oForm.FormBorderStyle = "FixedDialog"
oForm.MaximizeBox = 0
aNames = []
for aCategory in aCategories
	aNames + aCategory[1]
next
uiLabel(oForm,"Category",15,18,70,22)
oCategory = uiComboBox(oForm,90,15,150,aNames)
oValue = uiTextBox(oForm,15,60,110,26)
oFrom = uiComboBox(oForm,130,60,110,["-"])
uiLabel(oForm,"=",248,62,16,22)
oResult = uiTextBox(oForm,268,60,130,26)
oResult.ReadOnly = 1
oTo = uiComboBox(oForm,268,95,130,["-"])
oFormula = uiLabel(oForm,"",15,135,380,40)
oCategory.setSelectedIndexChangedEvent("fillUnits()")
oValue.setTextChangedEvent("convert()")
oFrom.setSelectedIndexChangedEvent("convert()")
oTo.setSelectedIndexChangedEvent("convert()")
fillUnits()
oValue.Text = "1"

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

# --------------------------------------------------------------------------

func fillUnits
	aUnits = aCategories[oCategory.SelectedIndex + 1][2]
	oFrom.Items.Clear()
	oTo.Items.Clear()
	for aUnit in aUnits
		oFrom.Items.Add(aUnit[1])
		oTo.Items.Add(aUnit[1])
	next
	oFrom.SelectedIndex = 0
	oTo.SelectedIndex = 1
	convert()

func toCelsius cUnit, nValue
	switch cUnit
	on "Celsius"	return nValue
	on "Fahrenheit"	return (nValue - 32) * 5 / 9
	on "Kelvin"	return nValue - 273.15
	off

func fromCelsius cUnit, nValue
	switch cUnit
	on "Celsius"	return nValue
	on "Fahrenheit"	return nValue * 9 / 5 + 32
	on "Kelvin"	return nValue + 273.15
	off

# convert nValue between two units of a category
func convertValue cCategory, cFromUnit, cToUnit, nValue
	if cCategory = "Temperature"
		return fromCelsius(cToUnit,toCelsius(cFromUnit,nValue))
	ok
	for aCategory in aCategories
		if aCategory[1] = cCategory
			nFromFactor = 0
			nToFactor = 0
			for aUnit in aCategory[2]
				if aUnit[1] = cFromUnit
					nFromFactor = aUnit[2]
				ok
				if aUnit[1] = cToUnit
					nToFactor = aUnit[2]
				ok
			next
			return nValue * nFromFactor / nToFactor
		ok
	next

func isNumeric cText
	cText = trim(cText)
	if cText = "" or cText = "-" or cText = "."
		return false
	ok
	cDigits = substr(substr(cText,"-",""),".","")
	for x = 1 to len(cDigits)
		if not isdigit(cDigits[x])
			return false
		ok
	next
	return true

func convert
	if oFrom.SelectedIndex < 0 or oTo.SelectedIndex < 0 or not isNumeric(oValue.Text)
		oResult.Text = ""
		return
	ok
	nResult = convertValue(oCategory.Text,oFrom.Text,oTo.Text,number(oValue.Text))
	oResult.Text = uiNumber(floor(nResult * 1000000 + 0.5) / 1000000)
	oFormula.Text = oValue.Text + " " + oFrom.Text + " = " + oResult.Text + " " + oTo.Text

func selfTest
	dnAssert("default is meter to kilometer",oFormula.Text,"1 Meter = 0.001 Kilometer")
	oValue.Text = "5"
	oTo.SelectedIndex = 4
	dnAssert("5 m in miles",oResult.Text,"0.003107")
	oCategory.SelectedIndex = 3
	dnAssert("units follow the category",oFrom.Items.Count,3)
	oValue.Text = "100"
	oFrom.SelectedIndex = 0
	oTo.SelectedIndex = 1
	dnAssert("100 C in F",oResult.Text,"212")
	oTo.SelectedIndex = 2
	dnAssert("100 C in K",oResult.Text,"373.15")
	oCategory.SelectedIndex = 1
	oValue.Text = "2"
	oFrom.SelectedIndex = 3
	oTo.SelectedIndex = 0
	dnAssert("2 lb in kg",oResult.Text,"0.907185")
	oValue.Text = "abc"
	dnAssert("invalid input clears the result",oResult.Text,"")
