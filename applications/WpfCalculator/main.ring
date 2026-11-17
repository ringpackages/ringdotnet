# Calculator with a WPF window described in XAML (the calculator logic is the one of the Windows Forms Calculator)

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
using {
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
	wpfTest(oWindow,"selfTest()")
	wpfRun(oWindow)
	wpfEnd()

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
	return dnRequest("call",[dnTypeCached("System.Convert, System.Private.CoreLib"),"ToString",nValue,dnType("System.Globalization.CultureInfo").getProp("InvariantCulture")])

func typeKeys cKeys
	for nIndex = 1 to len(cKeys)
		press(cKeys[nIndex])
	next

func selfTest
	typeKeys("12+30=")
	dnAssert("12+30",oScreen.Text,"42")
	press("C")
	typeKeys("9/3=")
	dnAssert("9/3",oScreen.Text,"3")
	press("C")
	typeKeys("0.1+0.2=")
	dnAssert("floating point",oScreen.Text,"0.30000000000000004")
	press("C")
	typeKeys("81")
	press("√")
	dnAssert("square root",oScreen.Text,"9")
	press("C")
	typeKeys("5/0=")
	dnAssert("division by zero",oScreen.Text,"Cannot divide by zero")
	press("C")
	# the buttons of the window work
	oKeys = wpfFind(oWindow,"keys")
	dnAssert("20 buttons",oKeys.Children.Count,20)
	oEvent = dnNew("RoutedEventArgs",[ :routedEvent = new WpfButtonBase().ClickEvent ])
	oSeven = oKeys.Children.Item(4)
	dnAssert("the 5th key is a 7",oKeys.Children.Item(4).Content,"7")
	oSeven.RaiseEvent(oEvent)
	oSeven.RaiseEvent(oEvent)
	dnAssert("two clicks on 7",oScreen.Text,"77")
	dnAssert("history",oHistory.Text,"")
