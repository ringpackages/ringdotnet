# ASCII table in a ListView with a filter (a port of ring/applications/asciitable)

load "dotnet.ring"
using {
	"System.Drawing"
	"System.Windows.Forms"
}

aNames = ["NUL","SOH","STX","ETX","EOT","ENQ","ACK","BEL","BS","TAB","LF","VT","FF","CR","SO","SI","DLE","DC1","DC2","DC3","DC4","NAK","SYN","ETB","CAN","EM","SUB","ESC","FS","GS","RS","US"]

oForm = uiForm("ASCII table",420,520)
uiLabel(oForm,"Filter",10,12,40,22)
oFilter = uiTextBox(oForm,55,9,200,26)
oCount = uiLabel(oForm,"",270,12,140,22)
oList = new ListView() {
	Location = new Point(10,45)
	Size = new Size(400,465)
	View = "Details"
	FullRowSelect = True
	GridLines = True
}
oList.Columns.Add([ :text = "Dec", :width = 60 ])
oList.Columns.Add([ :text = "Hex", :width = 60 ])
oList.Columns.Add([ :text = "Binary", :width = 100 ])
oList.Columns.Add([ :text = "Char", :width = 150 ])
oForm.Controls.Add(oList)
oFilter.setTextChangedEvent("fillTable()")
fillTable()

uiRun(oForm)

# --------------------------------------------------------------------------

func charName nCode
	if nCode < 32
		return aNames[nCode + 1]
	but nCode = 32
		return "SPACE"
	but nCode = 127
		return "DEL"
	ok
	return char(nCode)

func binary nCode
	cBits = ""
	for nBit = 7 to 0 step -1
		if floor(nCode / pow(2,nBit)) % 2 = 1
			cBits += "1"
		else
			cBits += "0"
		ok
	next
	return cBits

func fillTable
	cFilter = lower(oFilter.Text)
	oList.BeginUpdate()
	oList.Items.Clear()
	nShown = 0
	for nCode = 0 to 127
		cName = charName(nCode)
		cHex = upper(hex(nCode))
		if len(cHex) = 1
			cHex = "0" + cHex
		ok
		cRow = "" + nCode + " " + lower(cHex) + " " + lower(cName)
		if cFilter = "" or substr(cRow,cFilter)
			oItem = new ListViewItem().New_([ :text = "" + nCode ])
			oItem.SubItems.Add(cHex)
			oItem.SubItems.Add(binary(nCode))
			oItem.SubItems.Add(cName)
			oList.Items.Add(oItem)
			nShown++
		ok
	next
	oList.EndUpdate()
	oCount.Text = string(nShown) + " characters"
