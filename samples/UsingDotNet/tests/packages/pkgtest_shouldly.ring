# Shouldly: ShouldBe and the like as extension methods of any object (static class ShouldBeTestExtensions), with messages that show the code that failed
load "pkg.ring"
pkgUse("shouldly",[["Shouldly","4.3.0"]],[["Shouldly.dll",["Shouldly"]]])
pkgImport("shouldly","Shouldly.dll","Shouldly")

cBe = "Shouldly.ShouldBeTestExtensions"
cString = "Shouldly.ShouldBeStringTestExtensions"
cCollection = "Shouldly.ShouldBeEnumerableTestExtensions"

# values: ShouldBe is generic, the type argument is the type of the value
dnType(cBe).callGeneric("ShouldBe",["System.String"],["ring","ring"])
dnType(cBe).callGeneric("ShouldBe",["System.Int32"],[5,5])
dnType(cBe).callGeneric("ShouldNotBe",["System.String"],["a","b"])
dnAssert("the checks that hold raise nothing",1,1)

# a failed check is an error with a message
try
	dnType(cBe).callGeneric("ShouldBe",["System.String"],["actual","expected"])
	dnAssert("a failed ShouldBe is an error",1,0)
catch
	dnAssert("a failed ShouldBe is an error",substr(cCatchError,"expected") > 0 and substr(cCatchError,"actual") > 0,1)
done

# strings
dnType(cString).callMethod("ShouldContain",["hello ring world","ring"])
dnType(cString).callMethod("ShouldStartWith",["hello ring","hello"])
dnType(cString).callMethod("ShouldEndWith",["hello ring","ring"])
dnType(cString).callMethod("ShouldNotBeNullOrEmpty",["x"])
try
	dnType(cString).callMethod("ShouldContain",["hello","zzz"])
	dnAssert("a string that does not contain is an error",1,0)
catch
	dnAssert("a string that does not contain is an error",substr(cCatchError,"zzz") > 0,1)
done

# numbers: ShouldBeGreaterThan
dnType(cBe).callGeneric("ShouldBeGreaterThan",["System.Int32"],[10,5])
dnType(cBe).callGeneric("ShouldBeInRange",["System.Int32"],[7,1,10])

# a collection
oItems = dnNewGeneric("System.Collections.Generic.List",["System.String"],[])
oItems.callMethod("Add",["a"])
oItems.callMethod("Add",["b"])
dnType(cCollection).callGeneric("ShouldContain",["System.String"],[oItems,"a"])
dnType(cCollection).callGeneric("ShouldNotBeEmpty",["System.String"],[oItems])

# an exception: Should.Throw with a callback
oThrown = dnType("Shouldly.Should").callGeneric("Throw",["System.InvalidOperationException"],[dnCallback("failing")])
dnAssert("the exception that was thrown",substr(oThrown.Message,"boom") > 0,1)

dnTestSummary()

func failing aArgs
	raise("boom")
