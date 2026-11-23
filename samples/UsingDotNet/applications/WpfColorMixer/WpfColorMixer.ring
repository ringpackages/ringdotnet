# Color mixer in WPF: three sliders, a rectangle that shows the color and its #RRGGBB code

load "dotnet.ring"

using {
	"System"
	"System.IO"
	"System.Drawing"
	"System.Windows"
	"System.Windows.Controls"
	"System.Windows.Media"
	"System.Windows.Media.Imaging"
	"System.Windows.Shapes"
}

oWindow = ""
aSliders = []
aValues = []
oSwatch = ""
oCode = ""

func main

	oWindow = wpfWindow("Color mixer",380,300)
	oGrid = new Grid()
	oGrid.Margin = new Thickness(15,15,15,15)
	oWindow.Content = oGrid
	for nIndex = 1 to 4
		oGrid.RowDefinitions.Add(new RowDefinition())
	next
	for cName in ["Red","Green","Blue"]
		oRow = new StackPanel() {
			Orientation = "Horizontal"
			Margin = new Thickness(0,5,0,5)
		}
		oLabel = wpfLabel(cName)
		oLabel.Width = 60
		oRow.Children.Add(oLabel)
		oSlider = new Slider() {
			Minimum = 0
			Maximum = 255
			Width = 220
			setValueChangedEvent("mix()")
		}
		oRow.Children.Add(oSlider)
		oValue = wpfLabel("0")
		oRow.Children.Add(oValue)
		oGrid.Children.Add(oRow)
		oGrid.SetRow(oRow,len(aSliders))
		aSliders + oSlider
		aValues + oValue
	next
	oSwatch = new WpfRectangle() {
		Height = 80
		Margin = new Thickness(0,10,0,0)
	}
	oGrid.Children.Add(oSwatch)
	oGrid.SetRow(oSwatch,3)
	oCode = wpfLabel("")
	oCode.HorizontalAlignment = "Center"
	oGrid.Children.Add(oCode)
	oGrid.SetRow(oCode,3)
	oCode.VerticalAlignment = "Bottom"
	aSliders[1].Value = 200
	aSliders[2].Value = 120
	aSliders[3].Value = 40
	wpfRun(oWindow)

func hex2 nValue

	cText = upper(hex(floor(nValue)))
	if len(cText) < 2
		cText = "0" + cText
	ok
	return cText

func mix

	if len(aSliders) < 3 or not isobject(oSwatch)
		return
	ok
	cColor = "#" + hex2(aSliders[1].Value) + hex2(aSliders[2].Value) + hex2(aSliders[3].Value)
	for nIndex = 1 to 3
		aValues[nIndex].Content = "" + floor(aSliders[nIndex].Value)
	next
	oBrush = wpfBrush(cColor)
	oSwatch.Fill = oBrush
	oCode.Content = cColor
