# CliWrap: run a program and read what it prints; a fluent command (arguments, working folder, validation), the result with its exit code and output
load "pkg.ring"
pkgUse("cliwrap",[["CliWrap","3.10.5"]],[["CliWrap.dll",["CliWrap","CliWrap.Buffered"]]])
pkgImport("cliwrap","CliWrap.dll","CliWrap")
pkgImport("cliwrap","CliWrap.dll","CliWrap.Buffered")

# dotnet is on the PATH of every computer that runs these tests: its version is the program to run
oCommand = dnStatic("CliWrap.Cli","Wrap",["dotnet"])
oCommand = oCommand.WithArguments("--version")
dnAssert("the program and its arguments",oCommand.Arguments,"--version")
dnAssert("the target file",oCommand.TargetFilePath,"dotnet")

# run it and buffer the output: ExecuteBufferedAsync gives a CommandTask, whose Task property is the task that Result waits for
oResult = runBuffered(oCommand)
dnAssert("the exit code",oResult.ExitCode,0)
dnAssert("the program succeeded",oResult.IsSuccess,1)
dnAssert("the standard output is a version number",substr(oResult.StandardOutput,".") > 0,1)
dnAssert("nothing on the error output",len(trim(oResult.StandardError)),0)
dnAssert("it ran for some time",oResult.RunTime.TotalMilliseconds > 0,1)

# a program that fails: the exit code is not zero, and by default that is an error
oFails = dnStatic("CliWrap.Cli","Wrap",["dotnet"]).WithArguments("this-is-not-a-command")
try
	runBuffered(oFails)
	dnAssert("a failing program is an error",1,0)
catch
	dnAssert("a failing program is an error",substr(cCatchError,"Command execution failed") > 0,1)
done

# validation turned off: the result has the exit code
oQuiet = oFails.WithValidation(dnStatic("CliWrap.CommandResultValidation","None",[]))
oBad = runBuffered(oQuiet)
dnAssert("the exit code of a failing program",oBad.ExitCode != 0,1)
dnAssert("and it is not a success",oBad.IsSuccess,0)

# the input of a program: a pipe from a text
oFind = dnStatic("CliWrap.Cli","Wrap",["dotnet"]).WithArguments("--list-sdks")
oList = runBuffered(oFind)
dnAssert("the SDKs that are installed",len(oList.StandardOutput) > 0,1)

dnTestSummary()

func runBuffered oCommand
	oRun = dnRequest("call",[dnType("CliWrap.Buffered.BufferedCommandExtensions"),"ExecuteBufferedAsync",oCommand])
	return oRun.getProp("Task").Result
