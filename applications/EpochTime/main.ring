# Epoch (Unix) time converter - both directions, UTC and local time (a port of ring/applications/epochtime)

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
using {
	"System"
	"System.Globalization"
	"System.Drawing"
	"System.Windows.Forms"
}

C_FORMAT = "yyyy-MM-dd HH:mm:ss"

oForm = uiForm("Epoch time converter",440,230)
oForm.FormBorderStyle = "FixedDialog"
oForm.MaximizeBox = 0
uiLabel(oForm,"Epoch (seconds)",15,20,110,24)
oEpoch = uiTextBox(oForm,130,17,170,26)
uiButton(oForm,"Convert",310,15,100,28,"epochToDate()")
uiLabel(oForm,"UTC date",15,70,110,24)
oUtc = uiTextBox(oForm,130,67,170,26)
uiButton(oForm,"To epoch",310,65,100,28,"dateToEpoch()")
uiLabel(oForm,"Local time",15,115,110,24)
oLocal = uiTextBox(oForm,130,112,280,26)
oLocal.ReadOnly = 1
uiButton(oForm,"Now",130,155,100,30,"showNow()")
oMessage = uiLabel(oForm,"",15,195,410,24)
oMessage.ForeColor = uiColor("Firebrick")

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

# --------------------------------------------------------------------------

# the epoch (seconds) of a UTC date text, raises an error for invalid text
func epochOf cDateText
	oDate = new DateTimeOffset().Parse_3(cDateText,new CultureInfo("en-US").InvariantCulture,"AssumeUniversal")
	return oDate.ToUnixTimeSeconds()

func dateOf nEpoch
	return new DateTimeOffset().FromUnixTimeSeconds(nEpoch)

func epochToDate
	oMessage.Text = ""
	try
		oDate = dateOf(number(oEpoch.Text))
		oUtc.Text = oDate.UtcDateTime.ToString_1(C_FORMAT)
		oLocal.Text = oDate.LocalDateTime.ToString_1(C_FORMAT)
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

func selfTest
	oEpoch.Text = "0"
	epochToDate()
	dnAssert("epoch 0",oUtc.Text,"1970-01-01 00:00:00")
	oEpoch.Text = "1700000000"
	epochToDate()
	dnAssert("known epoch",oUtc.Text,"2023-11-14 22:13:20")
	dnAssert("local time is filled",len(oLocal.Text),19)
	oUtc.Text = "2000-01-01 00:00:00"
	dateToEpoch()
	dnAssert("date to epoch",oEpoch.Text,"946684800")
	oUtc.Text = "not a date"
	dateToEpoch()
	dnAssert("invalid date message",left(oMessage.Text,12),"Invalid date")
	oEpoch.Text = "abc"
	epochToDate()
	dnAssert("invalid epoch message",oMessage.Text,"Invalid epoch value")
	showNow()
	dnAssert("now is after 2024",number(oEpoch.Text) > 1704067200,1)
