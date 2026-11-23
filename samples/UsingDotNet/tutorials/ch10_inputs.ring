# more input controls - a date picker, a track bar, radio buttons, tool tips and an error marker (a booking form)
load "dotnet.ring"

using {
	"System"
	"System.Drawing"
	"System.Windows.Forms"
}

# controls that the event code uses are global variables
oForm = ""
oName = ""
oDate = ""
oNights = ""
oNightsLabel = ""
oSingle = ""
oDouble = ""
oSuite = ""
oPrice = ""
oErrors = ""
oTips = ""
oResult = ""
oBook = ""

func main

	oForm = uiForm("Booking",420,330)

	uiLabel(oForm,"Name",20,20,80,22)
	oName = uiTextBox(oForm,110,18,270,24)

	# a date picker: Value is a DateTime. MinDate and MaxDate limit the choice, and Format chooses how the date is shown.
	uiLabel(oForm,"Arrival",20,56,80,22)
	oDate = new DateTimePicker()
	oDate.Location = new Point(110,54)
	oDate.Size = new Size(150,24)
	oDate.Format = "Short"
	oDate.Value = new DateTime(2030,5,10)
	oDate.MinDate = new DateTime(2030,1,1)
	oDate.MaxDate = new DateTime(2030,12,31)
	oForm.Controls.Add(oDate)

	# a track bar: a slider with whole numbers
	uiLabel(oForm,"Nights",20,92,80,22)
	oNights = new TrackBar()
	oNights.Location = new Point(105,86)
	oNights.Size = new Size(200,40)
	oNights.Minimum = 1
	oNights.Maximum = 14
	oNights.Value = 3
	oNights.TickFrequency = 1
	oNights.setValueChangedEvent("showPrice()")
	oForm.Controls.Add(oNights)
	oNightsLabel = uiLabel(oForm,"3",315,92,60,22)

	# radio buttons: in the same container only one of them is on
	oGroup = new GroupBox()
	oGroup.Text = "Room"
	oGroup.Location = new Point(20,130)
	oGroup.Size = new Size(360,56)
	oSingle = new RadioButton()
	oSingle.Text = "Single"
	oSingle.Location = new Point(15,22)
	oSingle.Size = new Size(90,24)
	oSingle.Checked = True
	oSingle.setCheckedChangedEvent("showPrice()")
	oDouble = new RadioButton()
	oDouble.Text = "Double"
	oDouble.Location = new Point(120,22)
	oDouble.Size = new Size(90,24)
	oDouble.setCheckedChangedEvent("showPrice()")
	oSuite = new RadioButton()
	oSuite.Text = "Suite"
	oSuite.Location = new Point(225,22)
	oSuite.Size = new Size(90,24)
	oSuite.setCheckedChangedEvent("showPrice()")
	oGroup.Controls.Add(oSingle)
	oGroup.Controls.Add(oDouble)
	oGroup.Controls.Add(oSuite)
	oForm.Controls.Add(oGroup)

	oPrice = uiLabel(oForm,"",20,198,360,24)
	oBook = uiButton(oForm,"Book",20,232,100,32,"book()")
	oResult = uiLabel(oForm,"",20,274,380,24)

	# a tool tip: the text that appears when the mouse rests on a control. An error marker: a small icon next to a control with a message.
	oTips = new ToolTip()
	oTips.SetToolTip(oName,"Your full name")
	oTips.SetToolTip(oNights,"How many nights? From 1 to 14")
	oErrors = new ErrorProvider()

	showPrice()
	uiRun(oForm)

# the price of one night in each room, and a discount for a long stay
func roomPrice

	if oSuite.Checked
		return 180
	ok
	if oDouble.Checked
		return 110
	ok
	return 70

func roomName

	if oSuite.Checked
		return "Suite"
	ok
	if oDouble.Checked
		return "Double"
	ok
	return "Single"

func total

	nNights = oNights.Value
	nTotal = nNights * roomPrice()
	if nNights >= 7
		nTotal = nTotal * 0.9                         # 10 percent off from seven nights
	ok
	return nTotal

func showPrice

	oNightsLabel.Text = "" + oNights.Value
	oPrice.Text = "" + oNights.Value + " nights, " + roomName() + ": " + total() + " (a week or more: 10 percent off)"

func book

	cName = trim(oName.Text)
	if cName = ""
		oErrors.SetError(oName,"Please type a name")
		oResult.Text = ""
		return
	ok
	oErrors.SetError(oName,"")                        # an empty message removes the marker
	oResult.Text = "Booked for " + cName + ": arrival " + oDate.Value.Format("d MMMM yyyy") + ", " + total()
