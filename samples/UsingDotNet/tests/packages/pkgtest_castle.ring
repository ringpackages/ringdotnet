# Castle.Core DynamicProxy: a proxy of an interface whose calls a Ring callback answers (the interceptor is a small .NET class in a helper project: it calls the callback with the name of the method and its arguments)
load "pkg.ring"
pkgUseProject("castle","helpers/CastleHelpers",[["CastleHelpers.dll",["CastleHelpers"]]])
pkgImport("castle","CastleHelpers.dll","CastleHelpers")

aCalls = []          # the calls that the callback saw
fail = 0             # 1: the callback raises an error for Add
lastArguments = ""
oGreeter = dnStatic("CastleHelpers.Proxies","Greeter",[dnCallback("handle")])
dnAssert("a proxy is an object of the interface",isobject(oGreeter),1)

# the callback answers the calls
dnAssert("a text result",oGreeter.Greet("Ann"),"hello Ann")
dnAssert("a number result (converted to Int32)",oGreeter.Add(2,3),5)
oGreeter.Ping()
dnAssert("the calls were seen in order",len(aCalls),3)
dnAssert("the name of the first call",aCalls[1],"Greet")
dnAssert("the name of the last call",aCalls[3],"Ping")

# another call, other arguments
dnAssert("another call",oGreeter.Greet("Bo"),"hello Bo")
dnAssert("the arguments were passed",lastArguments,"Bo")

# an error in the callback is an error of the call
fail = 1
try
	oGreeter.Add(1,1)
	dnAssert("an error of the callback is an error of the call",1,0)
catch
	dnAssert("an error of the callback is an error of the call",substr(cCatchError,"refused") > 0,1)
done

dnTestSummary()

func handle aArgs
	cName = aArgs[1]
	add(aCalls,cName)
	aValues = aArgs[2].toList()
	lastArguments = ""
	if len(aValues) > 0
		lastArguments = "" + aValues[1]
	ok
	if fail = 1 and cName = "Add"
		raise("refused")
	ok
	switch cName
		on "Greet"
			return "hello " + aValues[1]
		on "Add"
			return aValues[1] + aValues[2]
	off
	return NULL
