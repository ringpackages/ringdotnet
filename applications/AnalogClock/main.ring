# Analog clock - a port of ring/applications/analogclock to RingDotNet

load "dotnet.ring"
dnUseDesktop()
using {
	"System"
	"System.Drawing"
	"System.Windows.Forms"
}

C_CENTER = 150
C_PI = 3.14159265358979

oForm = uiForm("Analog clock",300,330)
oForm {
	FormBorderStyle = "FixedSingle"
	MaximizeBox = False
}
oPicture = uiPictureBox(oForm,0,0,300,300)
oCanvas = new UiCanvas(oPicture)
oDigital = uiLabel(oForm,"",0,302,300,24)
oDigital {
	TextAlign = "MiddleCenter"
	Font = uiFont("Consolas",12,true)
}
oTimer = uiTimer(1000,"tick()")
tick()
oTimer.Start()

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

# --------------------------------------------------------------------------

# the end of a hand: nAngle in degrees (0 = 12 o'clock, clockwise)
func handX nAngle, nLength
	return C_CENTER + nLength * sin(nAngle * C_PI / 180)

func handY nAngle, nLength
	return C_CENTER - nLength * cos(nAngle * C_PI / 180)

func drawClock nHour, nMinute, nSecond
	oCanvas.clear("White")
	oCanvas.fillCircle(C_CENTER,C_CENTER,140,"#f4f1e8")
	oCanvas.drawCircle(C_CENTER,C_CENTER,140,"Black")
	for nMark = 0 to 59
		nAngle = nMark * 6
		if nMark % 5 = 0
			oCanvas.line(handX(nAngle,122),handY(nAngle,122),handX(nAngle,136),handY(nAngle,136),"Black",3)
		else
			oCanvas.line(handX(nAngle,130),handY(nAngle,130),handX(nAngle,136),handY(nAngle,136),"Gray",1)
		ok
	next
	nHourAngle = (nHour % 12) * 30 + nMinute * 0.5
	nMinuteAngle = nMinute * 6 + nSecond * 0.1
	nSecondAngle = nSecond * 6
	oCanvas.line(C_CENTER,C_CENTER,handX(nHourAngle,70),handY(nHourAngle,70),"Black",6)
	oCanvas.line(C_CENTER,C_CENTER,handX(nMinuteAngle,105),handY(nMinuteAngle,105),"DarkBlue",4)
	oCanvas.line(C_CENTER,C_CENTER,handX(nSecondAngle,120),handY(nSecondAngle,120),"Red",2)
	oCanvas.fillCircle(C_CENTER,C_CENTER,6,"Black")
	oCanvas.show()

func twoDigits n
	cText = "" + floor(n)
	if len(cText) < 2
		cText = "0" + cText
	ok
	return cText

func tick
	oNow = dnType("System.DateTime").getProp("Now")
	drawClock(oNow.Hour,oNow.Minute,oNow.Second)
	oDigital.Text = twoDigits(oNow.Hour) + ":" + twoDigits(oNow.Minute) + ":" + twoDigits(oNow.Second)

func selfTest
	oTimer.Stop()
	drawClock(3,0,30)
	dnAssert("hour hand points right at 3:00",oCanvas.pixel(C_CENTER + 40,C_CENTER),"ff000000")
	dnAssert("minute hand points up at :00",oCanvas.pixel(C_CENTER + 4,C_CENTER - 80),"ff00008b")
	dnAssert("the second hand points down at :30",oCanvas.pixel(C_CENTER,C_CENTER + 60),"ffff0000")
	dnAssert("empty face in a quadrant without hands",oCanvas.pixel(C_CENTER + 60,C_CENTER + 60),"fff4f1e8")
	drawClock(6,30,0)
	dnAssert("hour hand points down at 6:30",oCanvas.pixel(C_CENTER,C_CENTER + 40) != "fff4f1e8",1)
	dnAssert("angle math",floor(handX(90,100)),250)
	tick()
	dnAssert("digital clock text",len(oDigital.Text),8)
