# Calculator with a WPF window described in XAML (the calculator logic is the one of the Windows Forms Calculator)

load "dotnet.ring"
using {
	"System"
	"System.Globalization"
	"System.Windows"
	"System.Windows.Controls"
	"System.Windows.Controls.Primitives"
	"System.Windows.Media"
}

cDisplay = "0"
nAccumulator = 0
cOperator = ""
lFresh = true
oWindow = ""
oScreen = ""
oHistory = ""

cXaml = '<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Title="WPF Calculator" Width="300" Height="420" ResizeMode="CanMinimize" WindowStartupLocation="CenterScreen">'
cXaml += '<DockPanel Margin="10"><StackPanel DockPanel.Dock="Top">'
cXaml += '<TextBlock x:Name="history" Height="20" TextAlignment="Right" Foreground="Gray"/>'
cXaml += '<TextBlock x:Name="screen" Height="60" FontSize="36" TextAlignment="Right" Text="0"/></StackPanel>'
cXaml += '<UniformGrid x:Name="keys" Columns="4" Margin="0,10,0,0"/></DockPanel></Window>'

func main
	oWindow = wpfXaml(cXaml)
	oScreen = wpfFind(oWindow,"screen")
	oHistory = wpfFind(oWindow,"history")
	oKeys = wpfFind(oWindow,"keys")
	for cKey in ["C","±","%","/","7","8","9","*","4","5","6","-","1","2","3","+","0",".","√","="]
		oButton = wpfButton(cKey,"press('" + cKey + "')")
		oButton {
			FontSize = 18
			Margin = new Thickness(2,2,2,2)
		}
		oKeys.Children.Add(oButton)
	next
	wpfRun(oWindow)

func press cKey
	if find(["0","1","2","3","4","5","6","7","8","9"],cKey) > 0
		if lFresh
			cDisplay = cKey
			lFresh = false
		but len(cDisplay) < 16
			if cDisplay = "0"
				cDisplay = cKey
			else
				cDisplay += cKey
			ok
		ok
	but cKey = "."
		if lFresh
			cDisplay = "0."
			lFresh = false
		but not substr(cDisplay,".")
			cDisplay += "."
		ok
	but cKey = "C"
		cDisplay = "0"
		nAccumulator = 0
		cOperator = ""
		lFresh = true
		oHistory.Text = ""
	but cKey = "±"
		if cDisplay != "0"
			if left(cDisplay,1) = "-"
				cDisplay = substr(cDisplay,2)
			else
				cDisplay = "-" + cDisplay
			ok
		ok
	but cKey = "%"
		cDisplay = uiNumberWpf(number(cDisplay) / 100)
		lFresh = true
	but cKey = "√"
		if number(cDisplay) < 0
			cDisplay = "Error"
		else
			cDisplay = uiNumberWpf(sqrt(number(cDisplay)))
		ok
		lFresh = true
	but find(["+","-","*","/"],cKey) > 0
		if cOperator != "" and not lFresh
			calculate()
		ok
		nAccumulator = number(cDisplay)
		cOperator = cKey
		oHistory.Text = cDisplay + " " + cKey
		lFresh = true
	but cKey = "="
		if cOperator != ""
			oHistory.Text = uiNumberWpf(nAccumulator) + " " + cOperator + " " + cDisplay + " ="
			calculate()
			cOperator = ""
		ok
	ok
	oScreen.Text = cDisplay

func calculate
	nRight = number(cDisplay)
	switch cOperator
	on "+"
		nResult = nAccumulator + nRight
	on "-"
		nResult = nAccumulator - nRight
	on "*"
		nResult = nAccumulator * nRight
	on "/"
		if nRight = 0
			cDisplay = "Cannot divide by zero"
			lFresh = true
			nAccumulator = 0
			cOperator = ""
			return
		ok
		nResult = nAccumulator / nRight
	off
	cDisplay = uiNumberWpf(nResult)
	nAccumulator = nResult
	lFresh = true

# a number as text without Ring's fixed decimals
func uiNumberWpf nValue
	return new Convert().Format([ :value = nValue, :provider = new CultureInfo("").InvariantCulture ])
