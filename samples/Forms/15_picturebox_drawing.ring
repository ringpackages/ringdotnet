# Draw shapes and text on a bitmap (UiCanvas)

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
using {
	"System.Drawing"
	"System.Windows.Forms"
}


oForm = uiForm("Drawing",320,240)
oPicture = uiPictureBox(oForm,10,10,300,220)
oCanvas = new UiCanvas(oPicture)
oCanvas.clear("White")
oCanvas.fillRect(20,20,100,60,"SteelBlue")
oCanvas.fillCircle(200,70,40,"Orange")
oCanvas.drawRect(20,110,120,80,"Black")
oCanvas.line(150,120,290,200,"Red",4)
oCanvas.text("Drawn from Ring",150,10,"Black",12)
oCanvas.show()

uiTest(oForm,"dnAssert('rectangle',oCanvas.pixel(60,50),'ff4682b4') dnAssert('circle',oCanvas.pixel(200,70),'ffffa500') dnAssert('background',oCanvas.pixel(5,5),'ffffffff')")
uiRun(oForm)
uiEnd()
