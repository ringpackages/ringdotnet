# a project: an object inspector - reflection shows the properties of any .NET object, with their types and values, in a list
load "dotnet.ring"

using {
	"System"
	"System.IO"
	"System.Text"
	"System.Reflection"
	"System.Drawing"
	"System.Windows.Forms"
}

# controls and data that the event code uses are global variables
oForm = ""
oChoice = ""
oList = ""
oStatus = ""
aObjects = []                     # [ name, the .NET object ]
cTempFile = ""

func main

	# Some objects to look at. They are made here; the inspector does not care what they are.
	cTempFile = new Path().Combine([ new Path().GetTempPath(), "ringdotnet-inspect.txt" ])
	new File().WriteAllText([ :path = cTempFile, :contents = "Hello, inspector" ])
	aObjects + [ "A Uri", new Uri("https://example.com:8080/docs/page?x=1#top") ]
	aObjects + [ "A DateTime", dnNew("DateTime",[ :year = 2030, :month = 3, :day = 9, :hour = 14, :minute = 5, :second = 7 ]) ]
	aObjects + [ "A FileInfo", new FileInfo(cTempFile) ]
	aObjects + [ "A StringBuilder", new StringBuilder("Hello") ]

	oForm = uiForm("Inspector",560,380)
	uiLabel(oForm,"Object",15,18,60,22)
	oChoice = uiComboBox(oForm,80,15,250,[ "A Uri","A DateTime","A FileInfo","A StringBuilder" ])
	oChoice.setSelectedIndexChangedEvent("inspect(oChoice.SelectedIndex + 1)")

	oList = new ListView()
	oList.Location = new Point(15,50)
	oList.Size = new Size(520,260)
	oList.View = "Details"
	oList.FullRowSelect = True
	oList.GridLines = True
	oList.Columns.Add([ :text = "Property", :width = 150 ])
	oList.Columns.Add([ :text = "Type", :width = 110 ])
	oList.Columns.Add([ :text = "Value", :width = 240 ])
	oForm.Controls.Add(oList)
	oStatus = uiLabel(oForm,"",15,320,520,22)

	oChoice.SelectedIndex = 0
	inspect(1)                                           # the first object is shown at the start
	uiRun(oForm)
	new File().Delete(cTempFile)

# Fill the list with the properties of the object. GetType() gives the Type of any object, and the Type lists its properties; each
# property can read its value from the object: GetValue(object). A property with parameters (an indexer such as Chars[i]) is skipped.
func inspect n

	oObject = aObjects[n][2]
	oList.Items.Clear()
	nShown = 0
	nFailed = 0
	aRows = []
	for oProperty in oObject.GetType().GetProperties(NULL).toList()
		if len(oProperty.GetIndexParameters().toList()) > 0
			loop
		ok
		cValue = ""
		try
			cValue = showValue(oProperty.GetValue(oObject))
		catch
			cValue = "(cannot be read)"
			nFailed++
		done
		aRows + [ oProperty.Name, oProperty.PropertyType.Name, cValue ]
	next
	for aRow in sortRows(aRows)
		oItem = new ListViewItem().@New([ :text = aRow[1] ])
		oItem.SubItems.Add(aRow[2])
		oItem.SubItems.Add(aRow[3])
		oList.Items.Add(oItem)
		nShown++
	next
	oStatus.Text = aObjects[n][1] + ": " + nShown + " properties, " + nFailed + " could not be read"

# a value for the list: a Ring text or number as it is; an object (a date, another .NET object) by its ToString
func showValue xValue

	if isObject(xValue)
		return xValue.toString()
	ok
	return "" + xValue

# the rows sorted by the name of the property (a bubble sort on the first item; the lists are short)
func sortRows aRows

	for i = 1 to len(aRows) - 1
		for j = 1 to len(aRows) - i
			if strcmp(aRows[j][1],aRows[j + 1][1]) > 0
				aTemp = aRows[j]
				aRows[j] = aRows[j + 1]
				aRows[j + 1] = aTemp
			ok
		next
	next
	return aRows
