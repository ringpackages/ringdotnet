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

uiRun(oForm)

# --------------------------------------------------------------------------

func showDay
	oDay.Text = oPicker.Value.DayOfWeek + ", day " + oPicker.Value.DayOfYear + " of the year"
