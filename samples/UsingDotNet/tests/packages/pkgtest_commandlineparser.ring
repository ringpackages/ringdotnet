# CommandLineParser: the options are a class with attributes ([Option], [Value]: a helper project); Ring gives the arguments, the parser answers with a result, and a Ring callback gets the options object
load "pkg.ring"
pkgUseProject("commandline","helpers/AttributeHelpers",[["CommandLine.dll",["CommandLine"]],["AttributeHelpers.dll",["AttributeHelpers"]]])
pkgImport("commandline","CommandLine.dll","CommandLine")
pkgImport("commandline","AttributeHelpers.dll","AttributeHelpers")

# a parser whose help is not written to the console: the settings callback gets the settings object
oParser = dnNew("CommandLine.Parser",[dnCallback("quietSettings")])
cOptions = "AttributeHelpers.Options"

# a good command line: short and long names, a value that follows, and a positional value
oResult = oParser.callGeneric("ParseArguments",[cOptions],[ ["-n","Ring","--verbose","-c","3","input.txt"] ])
dnAssert("the command line was parsed",oResult.Tag,"Parsed")
oOptions = oResult.Value
dnAssert("a text option",oOptions.Name,"Ring")
dnAssert("a flag",oOptions.Verbose,1)
dnAssert("a number option",oOptions.Count,3)
dnAssert("a positional value",oOptions.File,"input.txt")

# the defaults
oDefaults = oParser.callGeneric("ParseArguments",[cOptions],[ ["--name=Bo"] ]).Value
dnAssert("a long name with an equal sign",oDefaults.Name,"Bo")
dnAssert("a flag that was not given",oDefaults.Verbose,0)
dnAssert("a default value",oDefaults.Count,1)

# a required option that is missing
oMissing = oParser.callGeneric("ParseArguments",[cOptions],[ ["--verbose"] ])
dnAssert("a missing required option is not parsed",oMissing.Tag,"NotParsed")
dnAssert("the errors are listed",len(oMissing.Errors.toList()) > 0,1)

# a value of the wrong type
dnAssert("a number that is not a number",oParser.callGeneric("ParseArguments",[cOptions],[ ["-n","x","-c","many"] ]).Tag,"NotParsed")

# an option that does not exist
dnAssert("an unknown option",oParser.callGeneric("ParseArguments",[cOptions],[ ["-n","x","--nothing"] ]).Tag,"NotParsed")

dnTestSummary()

func quietSettings aArgs
	aArgs[1].HelpWriter = dnNull()
