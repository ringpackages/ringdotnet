# A tooltip and a link label

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
dnImport("System.Drawing")
dnImport("System.Windows.Forms")


oForm = uiForm("Tooltip and link",320,140)
oButton = uiButton(oForm,"Hover me",20,20,110,32,"")
oTip = new ToolTip()
oTip.SetToolTip(oButton,"This button only has a tooltip")
oLink = new LinkLabel()
oLink.Text = "Visit ring-lang.github.io"
oLink.Location = new Point(20,75)
oLink.Size = new Size(260,24)
oLink.setLinkClickedEvent("linkClicked()")
oForm.Controls.Add(oLink)
oOpened = uiLabel(oForm,"",20,105,260,24)

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

# --------------------------------------------------------------------------

func linkClicked
	oOpened.Text = "link clicked"

func selfTest
	dnAssert("tooltip",oTip.GetToolTip(oButton),"This button only has a tooltip")
	linkClicked()
	dnAssert("link handler",oOpened.Text,"link clicked")
