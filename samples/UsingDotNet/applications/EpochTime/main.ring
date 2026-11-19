# Epoch (Unix) time converter - both directions, UTC and local time (a port of ring/applications/epochtime)

load "dotnet.ring"
using {
	"System"
	"System.Globalization"
	"System.Drawing"
	"System.Windows.Forms"
}

C_FORMAT = "yyyy-MM-dd HH:mm:ss"

oForm = uiForm("Epoch time converter",440,230)
oForm {
	FormBorderStyle = "FixedDialog"
	MaximizeBox = False
}
uiLabel(oForm,"Epoch (seconds)",15,20,110,24)
oEpoch = uiTextBox(oForm,130,17,170,26)
uiButton(oForm,"Convert",310,15,100,28,"epochToDate()")
uiLabel(oForm,"UTC date",15,70,110,24)
oUtc = uiTextBox(oForm,130,67,170,26)
uiButton(oForm,"To epoch",310,65,100,28,"dateToEpoch()")
uiLabel(oForm,"Local time",15,115,110,24)
oLocal = uiTextBox(oForm,130,112,280,26)
oLocal.ReadOnly = True
uiButton(oForm,"Now",130,155,100,30,"showNow()")
oMessage = uiLabel(oForm,"",15,195,410,24)
oMessage.ForeColor = uiColor("Firebrick")

uiRun(oForm)

# --------------------------------------------------------------------------

# the epoch (seconds) of a UTC date text, raises an error for invalid text
func epochOf cDateText
	oDate = new DateTimeOffset().Parse([ :input = cDateText, :formatProvider = new CultureInfo("en-US").InvariantCulture, :styles = "AssumeUniversal" ])
	return oDate.ToUnixTimeSeconds()

func dateOf nEpoch
	return new DateTimeOffset().FromUnixTimeSeconds(nEpoch)

func epochToDate
	oMessage.Text = ""
	try
		oDate = dateOf(number(oEpoch.Text))
		oUtc.Text = oDate.UtcDateTime.Format(C_FORMAT)
		oLocal.Text = oDate.LocalDateTime.Format(C_FORMAT)
	catch
		oMessage.Text = "Invalid epoch value"
	done

func dateToEpoch
	oMessage.Text = ""
	try
		nEpoch = epochOf(oUtc.Text)
		oEpoch.Text = "" + floor(nEpoch)
		epochToDate()
	catch
		oMessage.Text = "Invalid date (use yyyy-MM-dd HH:mm:ss)"
	done

func showNow
	# (creating an object while an attribute is being assigned would confuse Ring's setter: use a variable)
	nNow = new DateTimeOffset().UtcNow.ToUnixTimeSeconds()
	oEpoch.Text = "" + floor(nNow)
	epochToDate()
