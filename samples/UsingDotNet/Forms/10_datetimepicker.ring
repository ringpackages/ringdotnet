# A date picker and the weekday of the chosen date

load "dotnet.ring"
using {
	"System.Drawing"
	"System.Windows.Forms"
}


oForm = uiForm("Date picker",330,120)
oPicker = new DateTimePicker() {
	Location = new Point(20,20)
	Size = new Size(160,26)
	Format = "Short"
}
oForm.Controls.Add(oPicker)
oDay = uiLabel(oForm,"",20,65,290,24)
oPicker.setValueChangedEvent("showDay()")

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

# --------------------------------------------------------------------------

func showDay
	oDay.Text = oPicker.Value.DayOfWeek + ", day " + oPicker.Value.DayOfYear + " of the year"

func selfTest
	oDate = new DateTime(2024,12,25)
	oPicker.Value = oDate
	dnAssert("weekday",oDay.Text,"Wednesday, day 360 of the year")
