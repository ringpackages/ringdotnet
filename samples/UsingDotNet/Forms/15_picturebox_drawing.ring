# Draw shapes and text on a bitmap (UiCanvas)

load "dotnet.ring"

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

uiRun(oForm)
