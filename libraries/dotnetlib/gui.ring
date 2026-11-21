/*
	GUI helpers for Windows Forms programs (loaded with the namespace System.Windows.Forms: using { "System.Windows.Forms" }).
	They keep small applications short; everything they do can also be written with the plain classes.

	oForm = uiForm("Title",400,300)
	uiLabel(oForm,"Name:",10,10,80,20)
	oEdit = uiTextBox(oForm,100,10,200,24)
	uiButton(oForm,"OK",10,50,80,28,"uiMessage('Hello ' + oEdit.Text,'Hi')")
	uiRun(oForm)

	Programs can run themselves as a test: ring app.ring --selftest (the checks are in selftest/<program>.ring, loaded by uiRun; see also uiTest and uiEnd). In a test the form is invisible, a message
	box prints its text, and the form is closed when the test code ends (so the form is kept in the global variable oForm).
*/

# ---------------------------------------------------------------- forms and controls

# A form with a client area of nWidth x nHeight, centered on the screen
func uiForm  cTitle, nWidth, nHeight
	ui_oForm = new Form()
	ui_oForm.Text = cTitle
	ui_oForm.ClientSize = new Size(nWidth,nHeight)
	ui_oForm.StartPosition = "CenterScreen"
	return ui_oForm

# A label with a text, placed at (nX, nY) in the parent (a form or a container)
func uiLabel  oParent, cText, nX, nY, nWidth, nHeight
	ui_oLabel = new Label()
	ui_oLabel.Text = cText
	ui_oLabel.Location = new Point(nX,nY)
	ui_oLabel.Size = new Size(nWidth,nHeight)
	oParent.Controls.Add(ui_oLabel)
	return ui_oLabel

# A button; cClickCode is Ring code run on click ("" for none)
func uiButton  oParent, cText, nX, nY, nWidth, nHeight, cClickCode
	ui_oButton = new Button()
	ui_oButton.Text = cText
	ui_oButton.Location = new Point(nX,nY)
	ui_oButton.Size = new Size(nWidth,nHeight)
	if cClickCode != ""
		ui_oButton.setClickEvent(cClickCode)
	ok
	oParent.Controls.Add(ui_oButton)
	return ui_oButton

# A one-line text box (uiMemo has several lines); read and write its Text
func uiTextBox  oParent, nX, nY, nWidth, nHeight
	ui_oText = new TextBox()
	ui_oText.Location = new Point(nX,nY)
	ui_oText.Size = new Size(nWidth,nHeight)
	oParent.Controls.Add(ui_oText)
	return ui_oText

# A text box with several lines, scroll bars, Enter and Tab keys, and no word wrap
func uiMemo  oParent, nX, nY, nWidth, nHeight
	ui_oMemo = uiTextBox(oParent,nX,nY,nWidth,nHeight)
	ui_oMemo.Multiline = 1
	ui_oMemo.ScrollBars = "Both"
	ui_oMemo.AcceptsReturn = 1
	ui_oMemo.AcceptsTab = 1
	ui_oMemo.WordWrap = 0
	return ui_oMemo

# A check box; cClickCode is Ring code run on a click ("" for none); Checked is its state
func uiCheckBox  oParent, cText, nX, nY, nWidth, nHeight, cClickCode
	ui_oCheck = new CheckBox()
	ui_oCheck.Text = cText
	ui_oCheck.Location = new Point(nX,nY)
	ui_oCheck.Size = new Size(nWidth,nHeight)
	if cClickCode != ""
		ui_oCheck.setClickEvent(cClickCode)
	ok
	oParent.Controls.Add(ui_oCheck)
	return ui_oCheck

# A list box: Items.Add(text) adds an item, SelectedIndex is the chosen one (-1 for none)
func uiListBox  oParent, nX, nY, nWidth, nHeight
	ui_oList = new ListBox()
	ui_oList.Location = new Point(nX,nY)
	ui_oList.Size = new Size(nWidth,nHeight)
	oParent.Controls.Add(ui_oList)
	return ui_oList

# A drop-down list that is filled from the Ring list aItems; the first item is chosen
func uiComboBox  oParent, nX, nY, nWidth, aItems
	ui_oCombo = new ComboBox()
	ui_oCombo.Location = new Point(nX,nY)
	ui_oCombo.Width = nWidth
	ui_oCombo.DropDownStyle = "DropDownList"
	for ui_cItem in aItems
		ui_oCombo.Items.Add(ui_cItem)
	next
	if len(aItems) > 0
		ui_oCombo.SelectedIndex = 0
	ok
	oParent.Controls.Add(ui_oCombo)
	return ui_oCombo

# A panel: a container for other controls (give it as the parent)
func uiPanel  oParent, nX, nY, nWidth, nHeight
	ui_oPanel = new Panel()
	ui_oPanel.Location = new Point(nX,nY)
	ui_oPanel.Size = new Size(nWidth,nHeight)
	oParent.Controls.Add(ui_oPanel)
	return ui_oPanel

# A picture box that shows a UiCanvas
func uiPictureBox  oParent, nX, nY, nWidth, nHeight
	ui_oPicture = new PictureBox()
	ui_oPicture.Location = new Point(nX,nY)
	ui_oPicture.Size = new Size(nWidth,nHeight)
	oParent.Controls.Add(ui_oPicture)
	return ui_oPicture

# A timer that runs Ring code every nMilliseconds (call .Start() / .Stop())
func uiTimer  nMilliseconds, cCode
	ui_oTimer = new FormsTimer()
	ui_oTimer.Interval = nMilliseconds
	ui_oTimer.setTickEvent(cCode)
	return ui_oTimer

# A menu: uiMenu(oForm,[["File",[["Open","openFile()"],["-",""],["Exit","oForm.Close()"]]], ["Help",[["About","showAbout()"]]]])
func uiMenu  oForm, aMenus
	ui_oStrip = new MenuStrip()
	for ui_aMenu in aMenus
		ui_oTop = new ToolStripMenuItem().@New([ :text = ui_aMenu[1] ])
		for ui_aItem in ui_aMenu[2]
			if ui_aItem[1] = "-"
				ui_oTop.DropDownItems.Add(new ToolStripSeparator())
			else
				ui_oItem = new ToolStripMenuItem().@New([ :text = ui_aItem[1] ])
				if len(ui_aItem) >= 2 and ui_aItem[2] != ""
					ui_oItem.setClickEvent(ui_aItem[2])
				ok
				if len(ui_aItem) >= 3
					ui_oItem.ShortcutKeys = ui_aItem[3]
				ok
				ui_oTop.DropDownItems.Add(ui_oItem)
			ok
		next
		ui_oStrip.Items.Add(ui_oTop)
	next
	oForm.MainMenuStrip = ui_oStrip
	oForm.Controls.Add(ui_oStrip)
	return ui_oStrip

# ---------------------------------------------------------------- keyboard

/*
	Keys in games. A button (or any control that can take the focus) steals the arrow keys, Space and Enter for
	itself: the form's KeyDown event never sees the arrows, and Space "presses" the button. uiGameKeys() fixes that:
	every control reports the arrow keys as normal input keys and the keys that cCode handles are marked as handled.

	uiGameKeys(oForm,"keyPressed(aDotNetArgs[2].KeyCode)")	# call it after the controls were added
*/
func uiGameKeys  oForm, cCode
	oForm.KeyPreview = 1
	uiInputKeys(oForm)
	oForm.setKeyDownEvent(cCode + nl + "aDotNetArgs[2].Handled = 1")

# Make the arrow keys (and Enter, Escape) arrive as KeyDown events on every control of the container
func uiInputKeys  oParent
	for ui_oControl in oParent.Controls.toList()
		ui_oControl.setPreviewKeyDownEvent("aDotNetArgs[2].IsInputKey = 1")
		uiInputKeys(ui_oControl)
	next

# Type keys into the form like a user does, for tests: "12{+}30{ENTER}", "{LEFT}", " " (SendKeys syntax: {LEFT} {RIGHT} {UP} {DOWN}
# {ENTER} {ESC} {BACKSPACE} {TAB} {DELETE}, {+} for a plus sign). The keys are posted to the focused control of THIS form, so they
# go through the real Windows Forms key processing and can never reach another program (SendKeys would).
func uiSendKeys  oForm, cKeys
	ui_oTarget = oForm.ActiveControl
	if not isobject(ui_oTarget) or ui_oTarget.nHandle = 0
		ui_oTarget = oForm
	ok
	for ui_cToken in dnRequest("keytokens",[cKeys])
		# the focus may move with a key (Tab, an arrow on a button): the target is looked up again for every key
		ui_oTarget = oForm.ActiveControl
		if not isobject(ui_oTarget) or ui_oTarget.nHandle = 0
			ui_oTarget = oForm
		ok
		dnRequest("postkey",[ui_oTarget,ui_cToken])
		# the form processes the key (and the character message the message loop makes of it)
		for ui_nTry = 1 to 3
			new Application().DoEvents()
			dnStatic("System.Threading.Thread","Sleep",[5])
		next
	next
	return true

# ---------------------------------------------------------------- colors, fonts, dialogs

# A color from its red, green and blue parts (0 to 255)
func uiRGB  nRed, nGreen, nBlue
	return new Color().FromArgb([ :red = nRed, :green = nGreen, :blue = nBlue ])

# A color from its name: uiColor("Red")
func uiColor  cName
	return new Color().FromName(cName)

# A font of a family and size (lBold = true for bold): uiFont("Segoe UI",12,false)
func uiFont  cName, nSize, lBold
	if lBold
		return new Font(cName,nSize).@New([ :familyName = cName, :emSize = nSize, :style = "Bold" ])
	ok
	return new Font(cName,nSize)

# A message box (printed instead when running as a test)
func uiMessage  cText, cTitle
	if uiSelfTest()
		? "[message] " + cTitle + ": " + cText
		return
	ok
	new MessageBox().Show([ :text = cText, :caption = cTitle ])

# Yes/No question: true for Yes (a test prints the question and answers yes)
func uiAsk  cText, cTitle
	if uiSelfTest()
		? "[question] " + cTitle + ": " + cText
		return true
	ok
	return new MessageBox().Show([ :text = cText, :caption = cTitle, :buttons = "YesNo", :icon = "Question" ]) = "Yes"

# Open file dialog: returns the file name or ""
func uiOpenFileName  cTitle, cFilter
	ui_oDialog = new OpenFileDialog()
	ui_oDialog.Title = cTitle
	ui_oDialog.Filter = cFilter
	if ui_oDialog.ShowDialog(NULL) = "OK"
		return ui_oDialog.FileName
	ok
	return ""

# Save file dialog: returns the file name or ""
func uiSaveFileName  cTitle, cFilter
	ui_oDialog = new SaveFileDialog()
	ui_oDialog.Title = cTitle
	ui_oDialog.Filter = cFilter
	if ui_oDialog.ShowDialog(NULL) = "OK"
		return ui_oDialog.FileName
	ok
	return ""

# A number as text without Ring's fixed decimals: 2.5 --> "2.5", 1e21 --> "1E+21" (uses .NET)
func uiNumber  nValue
	return dnRequest("call",[dnTypeCached("System.Convert, System.Private.CoreLib"),"ToString",nValue,dnType("System.Globalization.CultureInfo").getProp("InvariantCulture")])

# ---------------------------------------------------------------- running and testing

# True when the program was started with --selftest: it drives itself and exits
func uiSelfTest
	return find(sysargv,"--selftest") > 0

# A form that runs as a test is invisible and not in the taskbar (set the environment variable RINGDOTNET_SHOW to see it)
func uiQuiet  oForm
	if uiSelfTest() and sysget("RINGDOTNET_SHOW") = ""
		oForm.ShowInTaskbar = False
		oForm.Opacity = 0
	ok

# Show the form and run the message loop. When running as a test (--selftest) the form closes itself after 30 seconds, and the checks
# in selftest/<program>.ring next to the program run once the form is shown (see dnLoadSelfTest); the result is printed at the end.
func uiRun  oForm
	uiQuiet(oForm)
	lChecks = False
	if uiSelfTest()
		ui_oGuard = uiTimer(30000,"? 'SELFTEST TIMEOUT' oForm.Close()")
		ui_oGuard.Start()
		lChecks = dnLoadSelfTest()
		if lChecks
			uiTest(oForm,"selfTest()")
		ok
	ok
	new Application().EnableVisualStyles()
	new Application().Run(oForm)
	if lChecks
		uiEnd()
	ok

# The automatic part of an application: when running as a test, cCode runs once the form is shown and the form closes afterwards.
# The form must be in the global variable oForm (the code that closes it is oForm.Close()).
func uiTest  oForm, cCode
	if not uiSelfTest()
		return
	ok
	uiQuiet(oForm)
	oForm.setShownEvent(cCode + nl + "oForm.Close()")

# Print the result of a test run: "SELFTEST OK" or the failures (call after uiRun)
func uiEnd
	if not uiSelfTest()
		return
	ok
	if nDotNetFail = 0
		? "SELFTEST OK (" + nDotNetPass + " checks)"
	else
		? "SELFTEST FAILED"
	ok

# ---------------------------------------------------------------- drawing

/*
	UiCanvas: draw with simple calls on a bitmap and show it in a PictureBox

	oCanvas = new UiCanvas(oPicture)
	oCanvas.clear("White")
	oCanvas.fillRect(10,10,50,50,"Red")
	oCanvas.show()
*/
class UiCanvas

	oPicture
	oBitmap
	oGraphics
	nWidth
	nHeight
	aBrushes = []
	aPens = []

	func init  oPictureBox
		oPicture = oPictureBox
		nWidth = oPictureBox.Width
		nHeight = oPictureBox.Height
		oBitmap = new Bitmap(nWidth,nHeight)
		oGraphics = new Graphics().FromImage(oBitmap)
		oGraphics.SmoothingMode = "AntiAlias"
		oPictureBox.Image = oBitmap
		return self

	# A color is a name ("Red"), "#RRGGBB" or a .NET Color object
	func color  xColor
		if isstring(xColor)
			if left(xColor,1) = "#"
				return uiRGB(dec(substr(xColor,2,2)),dec(substr(xColor,4,2)),dec(substr(xColor,6,2)))
			ok
			return uiColor(xColor)
		ok
		return xColor

	func brush  xColor
		ui_cKey = "" + xColor
		if isstring(xColor)
			ui_nPos = find(aBrushes,ui_cKey,1)
			if ui_nPos > 0
				return aBrushes[ui_nPos][2]
			ok
			ui_oNew = new SolidBrush(color(xColor))
			aBrushes + [ui_cKey,ui_oNew]
			return ui_oNew
		ok
		return new SolidBrush(xColor)

	func pen  xColor, nPenWidth
		ui_cKey = "" + xColor + "|" + nPenWidth
		if isstring(xColor)
			ui_nPos = find(aPens,ui_cKey,1)
			if ui_nPos > 0
				return aPens[ui_nPos][2]
			ok
			ui_oNew = new Pen(color(xColor))
			ui_oNew.Width = nPenWidth
			aPens + [ui_cKey,ui_oNew]
			return ui_oNew
		ok
		return new Pen(xColor)

	func clear  xColor
		oGraphics.Clear(color(xColor))

	func fillRect  nX, nY, nW, nH, xColor
		oGraphics.FillRectangle([ :brush = brush(xColor), :x = nX, :y = nY, :width = nW, :height = nH ])

	func drawRect  nX, nY, nW, nH, xColor
		oGraphics.DrawRectangle([ :pen = pen(xColor,1), :x = nX, :y = nY, :width = nW, :height = nH ])

	func fillCircle  nX, nY, nRadius, xColor
		oGraphics.FillEllipse([ :brush = brush(xColor), :x = nX - nRadius, :y = nY - nRadius, :width = nRadius * 2, :height = nRadius * 2 ])

	func drawCircle  nX, nY, nRadius, xColor
		oGraphics.DrawEllipse([ :pen = pen(xColor,1), :x = nX - nRadius, :y = nY - nRadius, :width = nRadius * 2, :height = nRadius * 2 ])

	func fillEllipse  nX, nY, nW, nH, xColor
		oGraphics.FillEllipse([ :brush = brush(xColor), :x = nX, :y = nY, :width = nW, :height = nH ])

	func line  nX1, nY1, nX2, nY2, xColor, nPenWidth
		oGraphics.DrawLine([ :pen = pen(xColor,nPenWidth), :x1 = nX1, :y1 = nY1, :x2 = nX2, :y2 = nY2 ])

	func text  cText, nX, nY, xColor, nSize
		ui_oFont = new Font("Segoe UI",nSize)
		oGraphics.DrawString([ :s = cText, :font = ui_oFont, :brush = brush(xColor), :point = new PointF(nX,nY) ])

	# Refresh the picture box after drawing
	func show
		oPicture.Refresh()

	func pixel  nX, nY
		return oBitmap.GetPixel(nX,nY).Name

	func close
		oGraphics.Dispose()
