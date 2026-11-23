# the checks of Pong.ring: run with  ring Pong.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	oTimer.Stop()
	# keys
	keyChanged("Down",true)
	nPlayerY = 100
	tick()
	dnAssert("paddle moves down while the key is held",nPlayerY,107)
	keyChanged("Down",false)
	tick()
	dnAssert("paddle stops",nPlayerY,107)
	nPlayerY = 0
	keyChanged("Up",true)
	tick()
	dnAssert("paddle stays inside the field",nPlayerY,0)
	keyChanged("Up",false)
	nKeyEvents = 0
	if uiSendKeys(oForm,"{DOWN}{UP}")
		dnAssert("real arrow keys reach the game (down and up, and their releases)",nKeyEvents,4)
	ok
	# the ball bounces on the top
	nBallX = 300
	nBallY = 8
	nBallDY = -3
	tick()
	dnAssert("bounce",nBallDY,3)
	# a goal for the player
	nBallX = C_WIDTH - 2
	nBallDX = 5
	nBallY = 200
	nComputerY = 0
	tick()
	dnAssert("player scores",nPlayerScore,1)
	dnAssert("the ball is served again",nBallX,300)
	# the paddle returns the ball
	nPlayerY = 150
	nBallX = 40
	nBallY = 190
	nBallDX = -5
	nBallDY = 0
	tick()
	dnAssert("paddle hit reverses the ball",nBallDX > 0,True)
	dnAssert("score text",oScore.Text,"You 1  :  0 Computer")
	dnAssert("the paddle is drawn",oCanvas.pixel(36,nPlayerY + 10),"ff1e90ff")
