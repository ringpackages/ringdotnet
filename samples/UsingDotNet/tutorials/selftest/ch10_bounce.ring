# the checks of ch10_bounce.ring: run with  ring ch10_bounce.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	oTimer.Stop()
	nBefore = nX
	step() step() step()
	dnAssert("the ball moved",nX,nBefore + 3 * nDX)
	keyPressed("Left")
	dnAssert("the paddle moved",nPaddle,130)
	dnAssert("the ball is orange",oCanvas.pixel(nX,nY),"ffffa500")
