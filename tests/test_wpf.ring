# WPF: windows, layout panels, controls, XAML, data binding, shapes and rendering, events, timers
load "../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
dnImport("System")
dnImport("System.Diagnostics")
dnImport("System.Threading")
dnImport("System.IO")
dnImport("System.Drawing")
dnImport("System.Windows")
dnImport("System.Windows.Controls")
dnImport("System.Windows.Controls.Primitives")
dnImport("System.Windows.Data")
dnImport("System.Windows.Media")
dnImport("System.Windows.Media.Imaging")
dnImport("System.Windows.Shapes")
dnImport("System.Windows.Threading")

# the window closes itself
if not wpfSelfTest()
	sysargv + "--selftest"
ok
nClicks = 0
nTicks = 0
cLog = ""

oWindow = wpfWindow("WPF test",420,320)
oGrid = new Grid()
oWindow.Content = oGrid
for nRowDef = 1 to 2
	oGrid.RowDefinitions.Add(new RowDefinition())
next
oGrid.ColumnDefinitions.Add(new ColumnDefinition())
oGrid.ColumnDefinitions.Add(new ColumnDefinition())

oButton = wpfButton("Click me","nClicks++")
oGrid.Children.Add(oButton)
oText = new WpfTextBox()
oText.Text = "hello"
oGrid.Children.Add(oText)
oGrid.SetRow(oText,1)
oGrid.SetColumn(oText,1)
oCheck = new WpfCheckBox()
oCheck.Content = "Check me"
oCheck.setCheckedEvent("cLog += 'checked '")
oCheck.setUncheckedEvent("cLog += 'unchecked '")
oSlider = new Slider()
oSlider.Minimum = 0
oSlider.Maximum = 100
oList = new WpfListBox()
oList.Items.Add("one")
oList.Items.Add("two")
oList.Items.Add("three")

wpfTest(oWindow,"selfTest()")
wpfRun(oWindow)

# layout (the window was shown)
dnAssert("window got its size",oWindow.Width,420)

# ---- things that work without showing the window
oStack = new StackPanel()
oStack.Orientation = "Horizontal"
oStack.Children.Add(wpfLabel("A"))
oStack.Children.Add(wpfLabel("B"))
dnAssert("stack panel children",oStack.Children.Count,2)
dnAssert("orientation is an enum string",oStack.Orientation,"Horizontal")

oThickness = new Thickness(4,5,6,7)
dnAssert("Thickness",oThickness.Left + oThickness.Top + oThickness.Right + oThickness.Bottom,22)
oRect = new Rect(1,2,30,40)
dnAssert("Rect",oRect.Right,31)
dnAssert("Rect contains",oRect.Contains_2(10,10),1)
oPoint = new WpfPoint(3,4)
dnAssert("Point",oPoint.X + oPoint.Y,7)

# XAML
oRoot = wpfXaml('<StackPanel xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"><TextBlock x:Name="title" Text="From XAML" FontSize="20"/><Button x:Name="go" Content="Go"/></StackPanel>')
dnAssert("XAML root",classname(oRoot),"stackpanel")
dnAssert("XAML child",wpfFind(oRoot,"title").Text,"From XAML")
dnAssert("XAML attribute",wpfFind(oRoot,"title").FontSize,20)
dnAssert("XAML button",wpfFind(oRoot,"go").Content,"Go")

# brushes and colors
oBrush = wpfBrush("#336699")
dnAssert("brush color",oBrush.Color.ToString(),"#FF336699")
dnAssert("named brush",wpfBrush("Red").Color.R,255)

# rendering to pixels
oCanvas = new Canvas()
oCanvas.Width = 100
oCanvas.Height = 100
oCanvas.Background = wpfBrush("White")
oEllipse = new Ellipse()
oEllipse.Width = 60
oEllipse.Height = 60
oEllipse.Fill = wpfBrush("Red")
oCanvas.Children.Add(oEllipse)
oCanvas.SetLeft(oEllipse,20)
oCanvas.SetTop(oEllipse,20)
dnAssert("ellipse center is red",wpfPixel(oCanvas,100,100,50,50),"ffff0000")
dnAssert("corner is white",wpfPixel(oCanvas,100,100,2,2),"ffffffff")

# data binding: the text box follows the slider
oSource = new Slider()
oSource.Maximum = 100
oTarget = new WpfTextBox()
oBinding = new WpfBinding().New_1("Value")
oBinding.Source = oSource
oTarget.SetBinding(oTarget.TextProperty,oBinding)
oSource.Value = 42
dnAssert("binding updates the target",oTarget.Text,"42")

# a dispatcher timer ticks inside the message loop and closes the window after 3 ticks
oWindow2 = wpfWindow("Timer",200,100)
oTimer = new DispatcherTimer()
oTimer.Interval = new TimeSpan().FromMilliseconds(30)
oTimer.setTickEvent("tick()")
oTimer.Start()
wpfRun(oWindow2)
dnAssert("dispatcher timer ticked 3 times",nTicks,3)

nFail = dnTestSummary()

func tick
	nTicks++
	if nTicks = 3
		oTimer.Stop()
		oWindow2.Close()
	ok

func selfTest
	dnAssert("title",oWindow.Title,"WPF test")
	dnAssert("rendered: the window has a real size",oWindow.ActualWidth > 100,1)
	dnAssert("button was laid out",oButton.ActualWidth > 10,1)
	dnAssert("row and column of an attached property",oGrid.GetRow(oText) * 10 + oGrid.GetColumn(oText),11)
	# click: raise the Click routed event
	oArgs = new RoutedEventArgs().New_1(new WpfButtonBase().ClickEvent)
	oButton.RaiseEvent(oArgs)
	oButton.RaiseEvent(oArgs)
	dnAssert("Click event",nClicks,2)
	# check box events and nullable bool
	oCheck.IsChecked = 1
	oCheck.IsChecked = 0
	dnAssert("Checked and Unchecked events",cLog,"checked unchecked ")
	oSlider.setValueChangedEvent("cLog = 'slider ' + oSlider.Value")
	oSlider.Value = 30
	dnAssert("ValueChanged event",cLog,"slider 30")
	oList.SelectedIndex = 1
	dnAssert("list selection",oList.SelectedItem,"two")
	dnAssert("list count",oList.Items.Count,3)
	oText.Text = "changed"
	dnAssert("text box text",oText.Text,"changed")
