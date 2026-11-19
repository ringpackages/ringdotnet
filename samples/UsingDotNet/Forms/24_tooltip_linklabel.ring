# A tooltip and a link label

load "dotnet.ring"
using {
	"System.Drawing"
	"System.Windows.Forms"
}

oForm = uiForm("Tooltip and link",320,140)
oButton = uiButton(oForm,"Hover me",20,20,110,32,"")
oTip = new ToolTip()
oTip.SetToolTip(oButton,"This button only has a tooltip")
oLink = new LinkLabel() {
	Text = "Visit ring-lang.github.io"
	Location = new Point(20,75)
	Size = new Size(260,24)
	setLinkClickedEvent("linkClicked()")
}
oForm.Controls.Add(oLink)
oOpened = uiLabel(oForm,"",20,105,260,24)

uiRun(oForm)

# --------------------------------------------------------------------------

func linkClicked
	oOpened.Text = "link clicked"
