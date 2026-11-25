# System.CommandLine: a command line described by a root command with options and arguments, parsed from an array of arguments; the values are
# read with the option objects (generic Option<T>), and the action of a command is a Ring callback
load "pkg.ring"
pkgUse("systemcommandline",[["System.CommandLine","2.0.0"]],[["System.CommandLine.dll",["System.CommandLine","System.CommandLine.Parsing"]]])
pkgImport("systemcommandline","System.CommandLine.dll","System.CommandLine")
pkgImport("systemcommandline","System.CommandLine.dll","System.CommandLine.Parsing")

oRoot = new RootCommand()
oRoot.Description = "A tool"
oName = dnNew("System.CommandLine.Option`1[[System.String]]",["--name"])
oCount = dnNew("System.CommandLine.Option`1[[System.Int32]]",["--count"])
oRoot.Options.Add(oName)
oRoot.Options.Add(oCount)
oResult = oRoot.Parse(["--name","ring","--count","3"])
dnAssert("a line without errors",len(oResult.Errors.toList()),0)
dnAssert("a text option",oResult.GetValue(oName),"ring")
dnAssert("a number option",oResult.GetValue(oCount),3)

# a line with a value that is not a number
oBad = oRoot.Parse(["--count","many"])
aErrors = oBad.Errors.toList()
dnAssert("an error for a value of the wrong type",len(aErrors),1)
dnAssert("the text of the error",substr(aErrors[1].Message,"many") > 0,1)

# an option that is not there, and an unknown option
dnAssert("an option that was not given has no value",dnIsNull(oRoot.Parse(["--count","1"]).GetValue(oName)),1)
dnAssert("an unknown option is an error",len(oRoot.Parse(["--other","x"]).Errors.toList()) > 0,1)

# a sub command with an argument, and its action (a Ring callback; a method named SetAction is written @SetAction, because setAction is the setter of the
# property Action)
aRan = []
oAdd = dnNew("System.CommandLine.Command",["add","Adds a name"])
oWho = dnNew("System.CommandLine.Argument`1[[System.String]]",["who"])
oAdd.Arguments.Add(oWho)
oRoot.Subcommands.Add(oAdd)
oAdd.@SetAction(dnCallback("runAdd"))
oParsed = oRoot.Parse(["add","bob"])
dnAssert("the sub command was found",oParsed.CommandResult.Command.Name,"add")
dnAssert("its argument",oParsed.GetValue(oWho),"bob")
oParsed.Invoke(NULL)
dnAssert("the action ran with the parsed values",aRan[1],"added bob")
dnTestSummary()

func runAdd aArgs

	aRan + ("added " + aArgs[1].callGeneric("GetValue",["System.String"],["who"]))
