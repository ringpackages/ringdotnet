# the checks of ch12_chat.ring: run with  ring ch12_chat.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

# wait (at most about a second) until the logs have changed: network messages arrive a little later
func waitForText cText

	for nTry = 1 to 50
		pump()
		if substr(aLogs[1].Text,cText) > 0 and substr(aLogs[2].Text,cText) > 0
			return True
		ok
		new Thread().Sleep(20)
	next
	return False

func selfTest

	oTimer.Stop()
	aInputs[1].Text = "Hello Bob"
	sendFrom(1)
	dnAssert("Bob received Alice's line",waitForText("Alice: Hello Bob"),True)
	dnAssert("Alice sees her own line too",substr(aLogs[1].Text,"Alice: Hello Bob") > 0,True)
	aInputs[2].Text = "Hi Alice"
	sendFrom(2)
	dnAssert("both windows show Bob's line",waitForText("Bob: Hi Alice"),True)
	dnAssert("the server has two clients",oServer.count(),2)
	aInputs[1].Text = "   "
	sendFrom(1)
	dnAssert("an empty line is not sent",len(aClients[1].sent()),1)

# ---------------------------------------------------------------- reading lines without waiting
