# Keyboard in games: a focused button takes the arrow keys, Space and Enter unless the form uses uiGameKeys().
# The keys are posted to the controls of this program (uiSendKeys), so nothing can reach another application.
load "../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
dnImport("System.Drawing")
dnImport("System.Windows.Forms")

aLog = []
nClicks = 0
oForm = ""
oButton = ""

# a plain form: the arrow keys are lost, Space and Enter press the button
newForm(false)
uiSendKeys(oForm,"{LEFT}{DOWN}a b{ENTER}")
dnAssert("plain form: arrow keys are lost",find(aLog,"Left") + find(aLog,"Down"),0)
dnAssert("plain form: letters arrive",find(aLog,"A") > 0,1)
dnAssert("plain form: Space and Enter press the focused button",nClicks,2)
oForm.Close()

# with uiGameKeys everything arrives and the button is left alone
aLog = []
nClicks = 0
newForm(true)
uiSendKeys(oForm,"{LEFT}{DOWN}{UP}{RIGHT} {ENTER}")
dnAssert("uiGameKeys: all arrow keys arrive",list2str(aLog),list2str(["Left","Down","Up","Right","Space","Enter"]))
dnAssert("uiGameKeys: the button is not pressed",nClicks,0)
aLog = []
uiSendKeys(oForm,"ab")
dnAssert("uiGameKeys: letters still arrive",list2str(aLog),list2str(["A","B"]))
oForm.Close()

nFail = dnTestSummary()

func newForm lFixed
	oForm = uiForm("Keyboard",300,160)
	oButton = uiButton(oForm,"New game",10,10,100,30,"nClicks++")
	if lFixed
		uiGameKeys(oForm,"aLog + aDotNetArgs[2].KeyCode")
	else
		oForm.KeyPreview = 1
		oForm.setKeyDownEvent("aLog + aDotNetArgs[2].KeyCode")
	ok
	oForm.Show(NULL)
	oButton.Focus()
