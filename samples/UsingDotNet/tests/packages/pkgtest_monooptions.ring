# Mono.Options: an OptionSet of option prototypes ("n|name=") with Ring callbacks for the values; Parse runs the callbacks and returns the arguments that were not options
load "pkg.ring"
pkgUse("monooptions",[["Mono.Options","6.12.0.148"]],[["Mono.Options.dll",["Mono.Options"]]])
pkgImport("monooptions","Mono.Options.dll","Mono.Options")
using { "System.IO" }

cName = ""
nCount = 0
nVerbose = 0
oSet = new OptionSet()
oSet.callMethod("Add",["n|name=","the name",dnCallback("setName")])
oSet.callMethod("Add",["c|count=","how many",dnCallback("setCount")])
oSet.callMethod("Add",["v|verbose","more output",dnCallback("addVerbose")])
aRest = oSet.Parse(["--name","ring","-c","3","-v","-v","file1","file2"]).toList()
dnAssert("a value option with a long name",cName,"ring")
dnAssert("a value option with a short name",nCount,3)
dnAssert("a flag option that was given twice",nVerbose,2)
dnAssert("the arguments that are not options",len(aRest),2)
dnAssert("the first of them",aRest[1],"file1")

# the other forms: name=value, a bundle of flags, a flag that was not given
cName = ""
nVerbose = 0
oSet.Parse(["--name=ann","-vv"])
dnAssert("the form name=value",cName,"ann")
dnAssert("a bundle of two flags",nVerbose,2)
nVerbose = 0
oSet.Parse(["x"])
dnAssert("a flag that was not given has not run",nVerbose,0)

# an option that needs a value and does not get one, and an unknown option
cError = ""
try
	oSet.Parse(["--name"])
catch
	cError = cCatchError
done
dnAssert("a missing value is an error",substr(cError,"OptionException") > 0,1)
aOther = oSet.Parse(["--unknown","a"]).toList()
dnAssert("an unknown option stays in the list of arguments",aOther[1],"--unknown")

# the description of the options
oWriter = new StringWriter()
oSet.WriteOptionDescriptions(oWriter)
cHelp = oWriter.ToString()
dnAssert("the help has the long names",substr(cHelp,"--name") > 0 and substr(cHelp,"--verbose") > 0,1)
dnAssert("the help has the descriptions",substr(cHelp,"how many") > 0,1)
dnTestSummary()

func setName aArgs

	cName = aArgs[1]

func setCount aArgs

	nCount = number(aArgs[1])

func addVerbose aArgs

	nVerbose++
