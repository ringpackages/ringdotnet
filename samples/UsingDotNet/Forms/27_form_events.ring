# The life of a form: Load, Shown, Resize and FormClosing events

load "dotnet.ring"
using {
	"System.Drawing"
	"System.Windows.Forms"
}

aLog = []
oForm = uiForm("Form events",320,120)
oForm {
	setLoadEvent("aLog + 'Load'")
	setResizeEvent("aLog + 'Resize'")
	setFormClosingEvent("aLog + 'FormClosing'")
}
uiLabel(oForm,"Watch the events in the console",15,20,280,24)

uiRun(oForm)
dnAssert("closing event ran",find(aLog,"FormClosing") > 0,True)
return

# --------------------------------------------------------------------------
