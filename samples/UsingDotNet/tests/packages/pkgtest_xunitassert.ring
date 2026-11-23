# xunit.assert: the Assert class (static methods with many overloads: generic Equal<T>, collections, strings, exceptions); a failed assertion is an error with the expected and the actual value
load "pkg.ring"
pkgUse("xunitassert",[["xunit.assert","2.9.3"]],[["xunit.assert.dll",["Xunit"]]])
pkgImport("xunitassert","xunit.assert.dll","Xunit")
dnImport("System.Collections.Generic")

cAssert = "Xunit.Assert"

# Equal: texts, numbers, lists
dnStatic(cAssert,"Equal",["ring","ring"])
dnStatic(cAssert,"Equal",[42.0,42.0])
dnStatic(cAssert,"NotEqual",["a","b"])
dnStatic(cAssert,"True",[1 = 1])
dnStatic(cAssert,"False",[1 = 2])
dnStatic(cAssert,"Contains",["bridge","ring bridge here"])
dnStatic(cAssert,"StartsWith",["ring","ring bridge"])
dnStatic(cAssert,"DoesNotContain",["zzz","ring bridge"])
dnStatic(cAssert,"Empty",[ [] ])
dnStatic(cAssert,"NotEmpty",[ [1,2] ])
dnAssert("the assertions that hold raise nothing",1,1)

# a failed Equal is an error that shows both values
try
	dnStatic(cAssert,"Equal",["expected text","actual text"])
	dnAssert("a failed Equal is an error",1,0)
catch
	dnAssert("a failed Equal is an error",substr(cCatchError,"expected text") > 0 and substr(cCatchError,"actual text") > 0,1)
done
try
	dnStatic(cAssert,"True",[0])
	dnAssert("a failed True is an error",1,0)
catch
	dnAssert("a failed True is an error",substr(cCatchError,"True") > 0,1)
done

# numbers with a precision
dnStatic(cAssert,"Equal",[3.14159,3.1416,3])
try
	dnStatic(cAssert,"Equal",[3.14159,3.2,3])
	dnAssert("numbers that differ are an error",1,0)
catch
	dnAssert("numbers that differ are an error",substr(cCatchError,"Assert.Equal") > 0 or substr(cCatchError,"Expected") > 0,1)
done

# collections
oList = new StringList()
oList.Add("a")
oList.Add("b")
dnStatic(cAssert,"Equal",[ ["a","b"],oList ])
dnStatic(cAssert,"Single",[ ["only"] ])
try
	dnStatic(cAssert,"Single",[ [1,2] ])
	dnAssert("two items are not a single item",1,0)
catch
	dnAssert("two items are not a single item",substr(cCatchError,"single") > 0 or substr(cCatchError,"Single") > 0,1)
done

# null and the same object
dnStatic(cAssert,"Null",[dnNull()])
dnStatic(cAssert,"NotNull",["x"])

# an exception is expected: Throws with the type argument, and an Action that is a Ring callback
oThrown = dnType(cAssert).callGeneric("Throws",["System.InvalidOperationException"],[dnCallback("failing")])
dnAssert("the exception that was thrown is returned (a Ring error becomes the .NET exception with its message)",substr(oThrown.Message,"boom") > 0,1)

dnTestSummary()

func failing aArgs

	raise("boom")
