/*
	WPF helpers (loaded with the namespace System.Windows)

	load "dotnet.ring"
	using {
		"System.Windows"
		"System.Windows.Controls"
	}

	oWindow = wpfWindow("Hello",300,200)
	oPanel = new StackPanel()
	oWindow.Content = oPanel
	oPanel.Children.Add(wpfLabel("Hello from WPF"))
	wpfRun(oWindow)

	WPF class names that exist in Windows Forms / System.Drawing / System too (Button, Label, TextBox, Brush, Point, Color,
	Application, MessageBox...) start with Wpf: WpfButton, WpfLabel, WpfTextBox... The others keep their name (Window, Grid, StackPanel).
	Programs can run themselves as a test: ring app.ring --selftest (see wpfTest and wpfEnd).
*/

# ---------------------------------------------------------------- windows and XAML

# A window of nWidth x nHeight, centered on the screen
func wpfWindow  cTitle, nWidth, nHeight
	wpf_oWindow = new Window()
	wpf_oWindow.Title = cTitle
	wpf_oWindow.Width = nWidth
	wpf_oWindow.Height = nHeight
	wpf_oWindow.WindowStartupLocation = "CenterScreen"
	return wpf_oWindow

# Build the objects of a XAML text: wpfXaml('<Button xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Content="Hi"/>')
func wpfXaml  cXaml
	return dnRequest("call",[dnTypeCached("System.Windows.Markup.XamlReader, PresentationFramework"),"Parse",cXaml])

# The element called cName (x:Name / Name in XAML) inside oRoot
func wpfFind  oRoot, cName
	return oRoot.FindName(cName)

# A brush from a name or a code: wpfBrush("Red"), wpfBrush("#336699")
func wpfBrush  cColor
	return new BrushConverter().ConvertFromString(cColor)

# A color from a name or a code
func wpfColor  cColor
	return new ColorConverter().ConvertFromString(cColor)

# ---------------------------------------------------------------- quick controls

# A Label (a content control, the class WpfLabel) with a text
func wpfLabel  cText
	wpf_oLabel = new WpfLabel()
	wpf_oLabel.Content = cText
	return wpf_oLabel

# A TextBlock (a plain text) with a text
func wpfText  cText
	wpf_oText = new TextBlock()
	wpf_oText.Text = cText
	return wpf_oText

# A button; cClickCode is Ring code run when it is clicked
func wpfButton  cText, cClickCode
	wpf_oButton = new WpfButton()
	wpf_oButton.Content = cText
	if cClickCode != ""
		wpf_oButton.setClickEvent(cClickCode)
	ok
	return wpf_oButton

# ---------------------------------------------------------------- running and testing

# True when the program was started with --selftest: it drives itself and exits
func wpfSelfTest
	return find(sysargv,"--selftest") > 0

# A window that runs as a test is invisible and not in the taskbar (set the environment variable RINGDOTNET_SHOW to see it)
func wpfQuiet  oWindow
	if wpfSelfTest() and sysget("RINGDOTNET_SHOW") = ""
		oWindow.ShowInTaskbar = False
		oWindow.Opacity = 0
	ok

# Show the window and run the message loop until it is closed (modal; works more than once in a program). With --selftest the checks in
# selftest/<program>.ring next to the program run once the window is rendered (see dnLoadSelfTest), and the result is printed at the end.
func wpfRun  oWindow
	wpfQuiet(oWindow)
	lChecks = False
	if wpfSelfTest()
		lChecks = dnLoadSelfTest()
		if lChecks
			wpfTest(oWindow,"selfTest()")
		ok
	ok
	oWindow.ShowDialog()
	if lChecks
		wpfEnd()
	ok

# The automatic part of a program: when running as a test, cCode runs once the window is rendered and the window closes afterwards.
# The window must be in the global variable oWindow (the code that closes it is oWindow.Close()).
func wpfTest  oWindow, cCode
	if not wpfSelfTest()
		return
	ok
	wpfQuiet(oWindow)
	oWindow.setContentRenderedEvent(cCode + nl + "oWindow.Close()")

# Print the result of a test run ("SELFTEST OK" or "SELFTEST FAILED")
func wpfEnd
	if not wpfSelfTest()
		return
	ok
	if nDotNetFail = 0
		? "SELFTEST OK (" + nDotNetPass + " checks)"
	else
		? "SELFTEST FAILED"
	ok

# The color of a pixel of a rendered element: "ffff0000" is opaque red (needs System.Drawing to read the picture)
func wpfPixel  oElement, nWidth, nHeight, nX, nY
	wpf_oElement = oElement
	wpf_oElement.Measure(new WpfSize(nWidth,nHeight))
	wpf_oElement.Arrange(new Rect(0,0,nWidth,nHeight))
	wpf_oTarget = new RenderTargetBitmap(nWidth,nHeight,96,96,new PixelFormats().Pbgra32)
	wpf_oTarget.Render(wpf_oElement)
	wpf_oEncoder = new PngBitmapEncoder()
	wpf_oFrame = new BitmapFrame().Create(wpf_oTarget)
	wpf_oEncoder.Frames.callMethod("Add",[wpf_oFrame])
	wpf_oStream = new MemoryStream()
	wpf_oEncoder.Save(wpf_oStream)
	wpf_oStream.Position = 0
	wpf_oPicture = new Bitmap(wpf_oStream,0)
	return wpf_oPicture.GetPixel(nX,nY).Name
