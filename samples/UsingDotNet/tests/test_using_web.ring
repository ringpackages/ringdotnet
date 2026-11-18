# using { } with "RingDotNet.Web" and "RingDotNet.Data" starts the web mode and loads Entity Framework
load "dotnet.ring"

func main
	using {
		"System"
		"RingDotNet.Web"
		"RingDotNet.Data"
	}
	dnAssert("the block started the web mode",cDotNetMode,"web")
	oServer = new WebServer("http://127.0.0.1:0")
	dnAssert("the web server can be made",len(oServer.url()) > 0,True)
	oServer.close()
	aSchema = [["Things",[["Id","int",1],["Name","string",0]]]]
	oDb = new RingDatabase("Data Source=:memory:",aSchema)
	oDb.insert("Things",[["Name","a"]])
	dnAssert("the database works",oDb.count("Things"),1)
	oDb.close()
	dnTestSummary()
