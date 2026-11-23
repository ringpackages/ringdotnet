# a tray icon - NotifyIcon: a program that lives in the notification area, a context menu, hiding the window, and a balloon message
load "dotnet.ring"

using {
	"System"
	"System.Drawing"
	"System.Windows.Forms"
}

# controls and state that the event code uses are global variables
oForm = ""
oTray = ""
oMenu = ""
oStatus = ""
nShown = 0                        # how many times the window was brought back from the tray

func main

	oForm = uiForm("Tray demo",380,160)
	oStatus = uiLabel(oForm,"The window is visible",20,20,330,24)
	uiButton(oForm,"Hide to the tray",20,60,160,32,"hideToTray()")

	# The tray icon needs an ICON (a small picture). SystemIcons has the standard ones, and an icon can also be made from a file.
	oTray = new NotifyIcon()
	oTray.Icon = new SystemIcons().Application
	oTray.Text = "Tray demo (double-click to open)"           # the tip when the mouse rests on the icon (63 characters at most)
	oTray.Visible = True

	# The icon has a context menu (right click): the same ContextMenuStrip that other controls have.
	oMenu = new ContextMenuStrip()
	oOpen = oMenu.Items.Add("Open")
	oQuit = oMenu.Items.Add("Quit")
	oOpen.setClickEvent("showFromTray()")
	oQuit.setClickEvent("oForm.Close()")
	oTray.ContextMenuStrip = oMenu
	oTray.setDoubleClickEvent("showFromTray()")

	# When the window closes the icon must be removed: it stays in the tray until the mouse moves over it if it is left there.
	oForm.setFormClosedEvent("oTray.Visible = False oTray.Dispose()")

	uiRun(oForm)

# hide the window: it is not minimized, it is gone from the screen and the taskbar; only the icon remains
func hideToTray

	oForm.Hide()
	if not uiSelfTest()                                    # (a test does not show a message on the screen)
		oTray.ShowBalloonTip([ :timeout = 2000, :tipTitle = "Tray demo", :tipText = "Still running in the tray", :tipIcon = "Info" ])
	ok

func showFromTray

	nShown++
	oForm.Show(NULL)
	oForm.Activate()
	oStatus.Text = "Back from the tray " + nShown + " time(s)"
