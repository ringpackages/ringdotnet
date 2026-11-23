# giving your program to others - a self check that a program made with Ring2EXE can run when it starts
#   ring ring2exe.ring ch13_distribution.ring -dist -dotnet        (the page explains the steps)
load "dotnet.ring"

using {
	"System"
	"System.IO"
}

func main

	? "Self check of RingDotNet"

	# 1. The .NET runtime. The program can not start without it, so a distributed program checks the version first and says clearly what to
	#    install. (The bridge needs .NET 6 or newer; the files of RingDotNet are made for .NET 9.)
	cVersion = dnVersion()                                   # a text like ".NET 9.0.15"
	cNumber = substr(cVersion,substr(cVersion,"NET ") + 4)    # "9.0.15"
	nMajor = number(left(cNumber,substr(cNumber,".") - 1))
	? nl + "1. the .NET runtime is version 6 or newer: " + (nMajor >= 6)

	# 2. The files of RingDotNet next to the program (the bridge and the libraries that Ring2EXE copies)
	cFolder = dnRequest("bridgefolder",[])
	? "2. the bridge assembly is in the program folder: " + new File().Exists(cFolder + "/RingDotNet.Bridge.dll")
	? "   the folder has the runtime configuration files: " + (new File().Exists(cFolder + "/RingDotNet.Bridge.runtimeconfig.json") and new File().Exists(cFolder + "/RingDotNet.Web.runtimeconfig.json"))

	# 3. The database libraries (Entity Framework and SQLite) with their native part: open a database in memory
	? "3. SQLite works: " + sqliteWorks()

	# 4. The web runtime. Programs that use the web server (the tutorial "A web service with a database") need the ASP.NET Core runtime on the computer; it is a separate
	#    runtime next to the .NET runtime. The folder of the .NET runtime tells where to look.
	? "4. the ASP.NET Core runtime is installed (needed only for web programs): " + aspNetInstalled()

	# 5. Writing next to the program is often not allowed (a program in "Program Files"): settings and data go to a folder of the user.
	#    The folder may not exist yet: the program makes it, and that shows that it can write there.
	cData = new Environment().GetFolderPath([ :folder = "ApplicationData", :option = "Create" ])          # "Create": made when it is missing (on Linux it often is)
	? "5. the folder for the data of the program exists or was made: " + (cData != "" and new Directory().Exists(cData))

func sqliteWorks

	try
		dnLoad(dnRequest("bridgefolder",[]) + "/RingDotNet.Data.dll")      # it knows where the native SQLite library of this system is
		dnLoadName("SQLitePCLRaw.batteries_v2")               # the assembly that starts the native SQLite library
		dnStatic("SQLitePCL.Batteries_V2","Init",[])
		oConnection = dnNew("Microsoft.Data.Sqlite.SqliteConnection",["Data Source=:memory:"])
		oConnection.Open()
		oCommand = oConnection.CreateCommand()
		oCommand.setProp("CommandText","SELECT 40 + 2")
		xAnswer = oCommand.ExecuteScalar()
		oConnection.Dispose()
		return (xAnswer = 42)
	catch
		return False
	done

func aspNetInstalled

	try
		cRuntime = dnStatic("System.Runtime.InteropServices.RuntimeEnvironment","GetRuntimeDirectory",[])
		# ...\shared\Microsoft.NETCore.App\9.0.15\ : two folders up is "shared", the folder of all the shared runtimes
		oShared = new Directory().GetParent(cRuntime).Parent.Parent
		return new Directory().Exists(new Path().Combine([oShared.FullName,"Microsoft.AspNetCore.App"]))
	catch
		return False
	done
