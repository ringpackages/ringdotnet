# the checks of ch12_runner.ring: run with  ring ch12_runner.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	oCommand.Text = "echo one && echo two"
	runCommand()
	dnAssert("the output has both lines",substr(oOutput.Text,"one") > 0 and substr(oOutput.Text,"two") > 0,True)
	dnAssert("the exit code is shown",substr(oStatus.Text,"Exit code 0") > 0,True)
	oCommand.Text = "dir c:\folder\that\does\not\exist"
	runCommand()
	dnAssert("an error text appears",len(trim(oOutput.Text)) > 0,True)
	dnAssert("the exit code is not 0",substr(oStatus.Text,"Exit code 0") = 0,True)
	oCommand.Text = "echo done"
	runCommand()
	dnAssert("the status",substr(oStatus.Text," ms") > 0,True)
