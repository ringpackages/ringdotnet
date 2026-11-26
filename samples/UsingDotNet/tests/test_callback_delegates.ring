# The delegates that Ring callbacks become: bound to a method that has a type (a library may read it: ML.NET CustomMapping does), for every number of parameters, with the
# results and the arguments of the callback unchanged; a delegate with more than 8 parameters is made another way and works too
load "dotnet.ring"

cHere = currentdir()
cLib = cHere + "/UserLib/bin/UserLib.dll"
if not fexists(cLib)
	system("dotnet build UserLib -c Release -o UserLib/bin -nologo -v q")
ok
cOut = cHere + "/UserLib/generated"
# the generator loads its files relative to the folder it runs from
chdir("../../../tools/dotnettools")
system(exefilename() + " wrapassembly.ring " + cLib + " " + cOut + " > nul")
chdir(cHere)
dnLoad(cLib)
dnImportFrom(cOut + "/","MyCompany.Tools")

nCalls = 0
cSeen = ""
cInfo = "MyCompany.Tools.DelegateInfo"

# the method of the delegate has a type
dnAssert("an Action with two parameters",dnStatic(cInfo,"TypeOfAction2",[dnCallback("seeTwo")]) != "none",1)
dnAssert("a Func with two parameters",dnStatic(cInfo,"TypeOfFunc2",[dnCallback("addTwo")]) != "none",1)
dnAssert("a delegate of 8 parameters",dnStatic(cInfo,"TypeOfEight",[dnCallback("addEight")]) != "none",1)

# every arity: the arguments arrive and the answer is used
dnStatic(cInfo,"CallAction0",[dnCallback("noArguments")])
dnAssert("an Action without parameters ran",nCalls,1)
dnStatic(cInfo,"CallAction2",[dnCallback("seeTwo"),7,9])
dnAssert("an Action with two parameters got its arguments",cSeen,"7,9")
dnAssert("a Func without parameters gives its answer",dnStatic(cInfo,"CallFunc0",[dnCallback("fortyTwo")]),42)
dnAssert("a Func with two parameters gives its answer",dnStatic(cInfo,"CallFunc2",[dnCallback("addTwo"),20,22]),42)
dnAssert("a Func of texts",dnStatic(cInfo,"CallText",[dnCallback("shout"),"ring"]),"RING!")
dnAssert("a delegate of 8 parameters",dnStatic(cInfo,"CallEight",[dnCallback("addEight")]),36)
dnAssert("a delegate of 9 parameters (made another way)",dnStatic(cInfo,"CallNine",[dnCallback("addNine")]),45)

# an event handler (EventHandler: an object and its arguments) and a callback used twice
dnAssert("the same callback gives a delegate each time",dnStatic(cInfo,"CallFunc0",[dnCallback("fortyTwo")]) + dnStatic(cInfo,"CallFunc0",[dnCallback("fortyTwo")]),84)

# an error in the callback comes back as an error of the call
cError = ""
try
	dnStatic(cInfo,"CallFunc0",[dnCallback("fails")])
catch
	cError = cCatchError
done
dnAssert("an error of the callback is an error of the call",len(cError) > 0,1)
dnTestSummary()

func noArguments aArgs

	nCalls++

func seeTwo aArgs

	cSeen = "" + aArgs[1] + "," + aArgs[2]

func fortyTwo aArgs

	return 42

func addTwo aArgs

	return aArgs[1] + aArgs[2]

func shout aArgs

	return upper(aArgs[1]) + "!"

func addEight aArgs

	return aArgs[1] + aArgs[2] + aArgs[3] + aArgs[4] + aArgs[5] + aArgs[6] + aArgs[7] + aArgs[8]

func addNine aArgs

	return addEight(aArgs) + aArgs[9]

func fails aArgs

	raise("the callback failed")
