# Temperature converter: type in any box and the others follow (TextChanged events)

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
dnImport("System.Drawing")
dnImport("System.Windows.Forms")

lUpdating = false

oForm = uiForm("Temperature converter",320,170)
oForm.FormBorderStyle = "FixedDialog"
oForm.MaximizeBox = 0
uiLabel(oForm,"Celsius",20,20,80,24)
uiLabel(oForm,"Fahrenheit",20,60,80,24)
uiLabel(oForm,"Kelvin",20,100,80,24)
oCelsius = uiTextBox(oForm,110,18,180,26)
oFahrenheit = uiTextBox(oForm,110,58,180,26)
oKelvin = uiTextBox(oForm,110,98,180,26)
oCelsius.setTextChangedEvent("fromCelsius()")
oFahrenheit.setTextChangedEvent("fromFahrenheit()")
oKelvin.setTextChangedEvent("fromKelvin()")
oCelsius.Text = "20"

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

# --------------------------------------------------------------------------

func isValidNumber cText
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

func show oBox, nValue
	lUpdating = true
	oBox.Text = uiNumber(floor(nValue * 100 + 0.5) / 100)
	lUpdating = false

func fromCelsius
	if lUpdating or not isValidNumber(oCelsius.Text)
		return
	ok
	nValue = number(oCelsius.Text)
	show(oFahrenheit,nValue * 9 / 5 + 32)
	show(oKelvin,nValue + 273.15)

func fromFahrenheit
	if lUpdating or not isValidNumber(oFahrenheit.Text)
		return
	ok
	nValue = (number(oFahrenheit.Text) - 32) * 5 / 9
	show(oCelsius,nValue)
	show(oKelvin,nValue + 273.15)

func fromKelvin
	if lUpdating or not isValidNumber(oKelvin.Text)
		return
	ok
	nValue = number(oKelvin.Text) - 273.15
	show(oCelsius,nValue)
	show(oFahrenheit,nValue * 9 / 5 + 32)

func selfTest
	dnAssert("20 C in F",oFahrenheit.Text,"68")
	dnAssert("20 C in K",oKelvin.Text,"293.15")
	oCelsius.Text = "100"
	dnAssert("100 C in F",oFahrenheit.Text,"212")
	oFahrenheit.Text = "32"
	dnAssert("32 F in C",oCelsius.Text,"0")
	oKelvin.Text = "0"
	dnAssert("0 K in C",oCelsius.Text,"-273.15")
	oCelsius.Text = "abc"
	dnAssert("invalid text is ignored",oFahrenheit.Text,"-459.67")
