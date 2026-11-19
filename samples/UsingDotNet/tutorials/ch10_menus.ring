# menus, toolbars, context menus and shortcuts - one action, several ways to reach it
load "dotnet.ring"
using {
	"System.Drawing"
	"System.Windows.Forms"
}

oForm = ""
oText = ""
oStatus = ""
oWrapItem = ""
nActions = 0

func main
	oForm = uiForm("Menus",480,300)

	# The text area first (it fills the window: see the tutorial "A small text editor")
	oText = uiMemo(oForm,0,0,480,260)
	oText {
		Dock = "Fill"
		Font = new Font("Consolas",11)
		Text = "Select some text, then use the menu, the toolbar, the right mouse button or a shortcut key."
	}

	# 1. A toolbar: buttons for the same actions. Controls docked at the top are placed in the reverse order of adding:
	#    the toolbar is added BEFORE the menu bar, so that the menu bar ends up above it.
	oTools = new ToolStrip()
	for aTool in [["Upper","upperCase()"],["Clear","newText()"]]
		oButton = new ToolStripButton()
		oButton.Text = aTool[1]
		oButton.setClickEvent(aTool[2])
		oTools.Items.Add(oButton)
	next
	oForm.Controls.Add(oTools)

	# 2. A menu bar. uiMenu takes [title, [ [item, code, shortcut], ... ]] ; "-" is a separator.
	#    A shortcut is written as the .NET text of the Keys enum: "Control, A"
	uiMenu(oForm,[
		["File",[["New","newText()","Control, N"],["-",""],["Exit","oForm.Close()","Alt, F4"]]],
		["Edit",[["Cut","oText.Cut()","Control, X"],["Copy","oText.Copy()","Control, C"],["Paste","oText.Paste()","Control, V"],["-",""],["Select all","oText.SelectAll()","Control, A"]]],
		["Text",[["Upper case","upperCase()","Control, U"],["Clear","newText()"]]],
		["Help",[["About","uiMessage('Menus tutorial','About')"]]]
	])

	# 3. A menu item that can be ticked: a ToolStripMenuItem with CheckOnClick. Added to the "Text" menu by hand.
	oWrapItem = new ToolStripMenuItem().New_([ :text = "Word wrap" ])
	oWrapItem.CheckOnClick = True
	oWrapItem.Checked = True
	oWrapItem.setCheckedChangedEvent("wrapChanged()")
	oForm.MainMenuStrip.Items.Item(2).DropDownItems.Add(oWrapItem)

	# 4. A context menu: opens with the right mouse button on the text
	oContext = new ContextMenuStrip()
	for aItem in [["Select all","oText.SelectAll()"],["Upper case","upperCase()"],["Clear","newText()"]]
		oEntry = new ToolStripMenuItem().New_([ :text = aItem[1] ])
		oEntry.setClickEvent(aItem[2])
		oContext.Items.Add(oEntry)
	next
	oText.ContextMenuStrip = oContext

	# 5. A status bar tells what happened
	oStatus = new StatusStrip()
	oStatusLabel = new ToolStripStatusLabel()
	oStatusLabel.Text = "Ready"
	oStatus.Items.Add(oStatusLabel)
	oForm.Controls.Add(oStatus)

	uiRun(oForm)

# ---------------------------------------------------------------- the actions: written once, reached from many places

func say cMessage
	nActions++
	oStatus.Items.Item(0).Text = cMessage

func upperCase
	if oText.SelectionLength > 0
		oText.SelectedText = upper(oText.SelectedText)
		say("Upper case applied to the selection")
	else
		oText.Text = upper(oText.Text)
		say("Upper case applied to all the text")
	ok

func newText
	oText.Text = ""
	say("Cleared")

func wrapChanged
	oText.WordWrap = oWrapItem.Checked
	say("Word wrap is " + iif(oWrapItem.Checked,"on","off"))

func iif lCondition, xYes, xNo
	if lCondition
		return xYes
	ok
	return xNo
