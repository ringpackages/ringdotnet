# the checks of AnalogClock.ring: run with  ring AnalogClock.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

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
