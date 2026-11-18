# desktop and web names in one block start the "all" mode
load "dotnet.ring"

func main
	using {
		"System.Windows.Forms"
		"Microsoft.AspNetCore.Builder"
	}
	dnAssert("both names start the all mode",cDotNetMode,"all")
	oForm = new Form()
	oForm.Text = "y"
	oServer = new WebServer("http://127.0.0.1:0")
	dnAssert("a form and a web server in one program",oForm.Text + "/" + (len(oServer.url()) > 0),"y/1")
	dnTestSummary()
