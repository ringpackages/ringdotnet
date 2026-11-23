# using { } starts the runtime mode that the namespaces need: Windows Forms names start the desktop mode
load "dotnet.ring"

func main

	dnAssert("no mode before the block",cDotNetMode,"")
	using {
		"System"
		"System.Drawing"
		"System.Windows.Forms"
	}
	dnAssert("the block started the desktop mode",cDotNetMode,"desktop")
	oForm = new Form()
	oForm.Text = "x"
	dnAssert("a form can be made",oForm.Text,"x")
	# the runtime can not change its mode: asking for the web mode now is an error with a clear message
	lFailed = False
	cMessage = ""
	try
		using { "RingDotNet.Web" }
	catch
		lFailed = True
		cMessage = cCatchError
	done
	dnAssert("another mode after the start is refused",lFailed,True)
	dnAssert("the message names the modes",substr(cMessage,"desktop") > 0 and substr(cMessage,"all") > 0,True)
	dnTestSummary()
