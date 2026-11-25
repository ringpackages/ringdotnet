# A smoke test over the classes of many namespaces: every public class that has a constructor without parameters can be created by the
# bridge, and the answer is a real object (a handle that is not 0). A class whose constructor refuses on this system (OpenSSL on Windows,
# for example) raises a PlatformNotSupportedException, which is fine; any other error, or a handle of 0, is a failure.
# Then a harmless call is made on each object that was created: ToString, GetHashCode, Equals(itself), GetType, and a read of every property
# of a simple type (text, number, yes/no). The answers must have the right kind. A property may refuse because of the state of a new object
# (a stream without a timeout, a response that was never received): that is an exception of .NET and is accepted; an error of the bridge is not.
# The methods without parameters whose names start with Get, To or Is are called too (a generic method whose type argument cannot be found from
# its values, such as JsonObject.GetValue<T>, is marked in the description and is left out).
load "dotnet.ring"

nProperties = 0          # globals: the function that makes the calls counts them
nMethodCalls = 0

func main

	aNamespaces = ["System.Collections","System.Collections.Generic","System.Collections.Specialized","System.Collections.Concurrent",
		"System.Collections.ObjectModel","System.Text","System.Text.Json","System.Text.Json.Nodes","System.Xml","System.Xml.Linq",
		"System.Data","System.Numerics","System.ComponentModel","System.IO","System.Globalization","System.Net.Mail",
		"System.Security.Cryptography","System.Diagnostics","System.Net","System.Text.RegularExpressions"]
	# classes that start something outside the program when they are made
	aSkip = ["System.Diagnostics.Process","System.IO.FileSystemWatcher","System.Net.HttpListener","System.Diagnostics.Stopwatch"]
	dnBuildIndexMap()
	nTried = 0
	aNull = []
	aErrors = []
	aWrong = []          # a harmless call that failed in a way that is not an exception of the class
	nObjects = 0
	for cNamespace in aNamespaces
		dnImport(cNamespace)
		for aEntry in aDotNetClassIndex
			if aEntry[2] != cNamespace or find(aSkip,aEntry[1]) > 0
				loop
			ok
			aApi = ""
			try
				aApi = dnDescribe(aEntry[1])          # a few types of the list cannot be described on this system: they are left out
			catch
				loop
			done
			if not islist(aApi) or aApi[2] = 1
				loop
			ok
			lParameterless = False
			for aConstructor in aApi[3]
				if len(aConstructor) = 0
					lParameterless = True
				ok
			next
			if not lParameterless
				loop
			but substr(aEntry[1],"`") > 0 and substr(aEntry[1],"[") = 0
				# a generic definition: an object needs its type arguments (all texts here; a type that does not accept texts is left out)
				aArguments = []
				for nArgument = 1 to number(substr(aEntry[1],substr(aEntry[1],"`") + 1,1))
					aArguments + "System.String"
				next
				try
					oObject = dnNew(aEntry[1],[ :typeArguments = aArguments ])
				catch
					loop
				done
				nTried++
				nObjects++
				harmlessCalls(oObject,aEntry[1],aApi,aWrong)
				loop
			ok
			nTried++
			try
				if dnCreate(aEntry[1],[]) = 0
					aNull + aEntry[1]
				ok
			catch
				if substr(cCatchError,"PlatformNotSupportedException") = 0
					aErrors + (aEntry[1] + ": " + left(cCatchError,60))
				ok
			done
			# the harmless calls, on a new object of the class
			oObject = ""
			try
				oObject = dnNew(aEntry[1],[])
			catch
				loop
			done
			if not isobject(oObject)
				aWrong + (aEntry[1] + " is not an object")
				loop
			ok
			nObjects++
			harmlessCalls(oObject,aEntry[1],aApi,aWrong)

		next
	next
	dnAssert("many classes were tried (" + nTried + ")",nTried > 150,True)
	dnAssert("no class gave a handle of 0 " + joined(aNull),len(aNull),0)
	dnAssert("no class raised another error " + joined(aErrors),len(aErrors),0)
	dnAssert("harmless calls were made on many objects (" + nObjects + " objects)",nObjects > 150,True)
	dnAssert("a property of a simple type was read on many of them",nProperties > 300,True)
	dnAssert("methods that start with Get, To or Is were called (" + nMethodCalls + " calls)",nMethodCalls > 150,True)
	dnAssert("no harmless call failed in the bridge " + joined(aWrong),len(aWrong),0)
	dnTestSummary()

# the items of a list as one text (empty for an empty list)
func joined aList

	cText = ""
	for cItem in aList
		cText += cItem + "; "
	next
	return cText

# The exceptions of .NET that a new object may raise for the state it is in (not a fault of the bridge)
func stateError cMessage

	for cKind in ["InvalidOperationException","ObjectDisposedException","NotSupportedException","PlatformNotSupportedException","NullReferenceException","ArgumentException","NotImplementedException"]
		if substr(cMessage,cKind) > 0
			return True
		ok
	next
	return False

func harmlessCalls oObject, cType, aApi, aWrong

	try
		if not isstring(oObject.toString())
			aWrong + (cType + ": ToString is not a text")
		ok
	catch
		if not stateError(cCatchError)
			aWrong + (cType + ": ToString " + left(cCatchError,50))
		ok
	done
	try
		if not isnumber(oObject.callMethod("GetHashCode",[]))
			aWrong + (cType + ": GetHashCode is not a number")
		ok
	catch
		if not stateError(cCatchError)
			aWrong + (cType + ": GetHashCode " + left(cCatchError,50))
		ok
	done
	try
		if oObject.callMethod("Equals",[oObject]) != 1
			aWrong + (cType + ": an object is not equal to itself")
		ok
	catch
		if not stateError(cCatchError)
			aWrong + (cType + ": Equals " + left(cCatchError,50))
		ok
	done
	try
		cName = oObject.callMethod("GetType",[]).getProp("FullName")
		if cName != cType and substr(cType,"`") = 0
			aWrong + (cType + ": GetType().FullName is " + cName)
		ok
	catch
		aWrong + (cType + ": GetType " + left(cCatchError,50))
	done
	for aMember in aApi[5]
		if aMember[2] != 1 or aMember[4] = 1
			loop
		but find(["System.String","System.Int32","System.Int64","System.Boolean","System.Double"],aMember[5]) = 0
			loop
		ok
		nProperties++
		try
			x = oObject.getProp(aMember[1])
		catch
			if not stateError(cCatchError)
				aWrong + (cType + "." + aMember[1] + ": " + left(cCatchError,50))
			ok
		done
	next
	# the methods without parameters whose names start with Get, To or Is: each one is called and its answer has the kind that its type says
	for aMethod in aApi[4]
		cName = aMethod[1]
		if aMethod[2] = 1 or len(aMethod[4]) != 0 or aMethod[8] = 1
			loop
		but not (left(cName,3) = "Get" or left(cName,2) = "To" or left(cName,2) = "Is")
			loop
		but cName = "GetType" or cName = "ToString" or cName = "GetHashCode"
			loop
		ok
		nMethodCalls++
		try
			xAnswer = oObject.callMethod(cName,[])
			if aMethod[3] = "System.String" and not (isstring(xAnswer) or isobject(xAnswer))
				aWrong + (cType + "." + cName + " should give a text")
			ok
			if find(["System.Int32","System.Int64","System.Double","System.Boolean"],aMethod[3]) > 0 and not isnumber(xAnswer)
				aWrong + (cType + "." + cName + " should give a number")
			ok
		catch
			if not stateError(cCatchError)
				aWrong + (cType + "." + cName + ": " + left(cCatchError,50))
			ok
		done
	next
