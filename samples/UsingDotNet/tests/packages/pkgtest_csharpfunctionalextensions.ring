# CSharpFunctionalExtensions: Result and Maybe types (success or failure with a message, a value or no value), built with generic static methods and chained with Map, Bind and Match
load "pkg.ring"
pkgUse("cfe",[["CSharpFunctionalExtensions","3.7.0"]],[["CSharpFunctionalExtensions.dll",["CSharpFunctionalExtensions"]]])
pkgImport("cfe","CSharpFunctionalExtensions.dll","CSharpFunctionalExtensions")

oResultType = dnType("CSharpFunctionalExtensions.Result")

# a Result without a value
oOk = oResultType.callMethod("Success",[])
dnAssert("a success",oOk.IsSuccess,1)
dnAssert("a success is not a failure",oOk.IsFailure,0)
oBad = oResultType.callMethod("Failure",["no money"])
dnAssert("a failure",oBad.IsFailure,1)
dnAssert("the error of a failure",oBad.Error,"no money")

# a Result with a value: the type of the value is a type argument
oFive = oResultType.callGeneric("Success",["System.Int32"],[5])
dnAssert("a result with a value",oFive.IsSuccess,1)
dnAssert("the value",oFive.Value,5)
oNoText = oResultType.callGeneric("Failure",["System.String"],["not found"])
dnAssert("a failure with a value type",oNoText.IsFailure,1)
dnAssert("its error",oNoText.Error,"not found")

# reading the value of a failure is an error
lRefused = 0
try
	oNoText.Value
catch
	lRefused = 1
done
dnAssert("the value of a failure raises an error",lRefused,1)

# Map changes the value of a success and keeps a failure as it is
# (Map is an extension method of Result<T>: it is a method of the static class ResultExtensions, with the Result as its first argument)
oExtensions = dnType("CSharpFunctionalExtensions.ResultExtensions")
oTen = oExtensions.callGeneric("Map",["System.Int32","System.Int32"],[oFive,dnCallback("double")])
dnAssert("Map on a success",oTen.Value,10)
oMissing = oResultType.callGeneric("Failure",["System.Int32"],["no number"])
oStillMissing = oExtensions.callGeneric("Map",["System.Int32","System.Int32"],[oMissing,dnCallback("double")])
dnAssert("Map on a failure keeps the failure",oStillMissing.IsFailure,1)
dnAssert("and its error",oStillMissing.Error,"no number")

# combine several results: the first failure wins, all the messages are joined
aResults = [oOk,oBad,oBad]
oCombined = oResultType.callMethod("Combine",[ aResults ])
dnAssert("a combination with failures is a failure",oCombined.IsFailure,1)
oAllGood = oResultType.callMethod("Combine",[ [oOk,oOk] ])
dnAssert("a combination of successes is a success",oAllGood.IsSuccess,1)

# Maybe: a value that may be missing
oMaybeType = dnType("CSharpFunctionalExtensions.Maybe")
oSome = oMaybeType.callGeneric("From",["System.String"],["ring"])
dnAssert("a Maybe with a value has a value",oSome.HasValue,1)
dnAssert("the value of a Maybe",oSome.Value,"ring")
dnAssert("GetValueOrDefault gives the value",oSome.GetValueOrDefault("other"),"ring")
oMaybeString = dnType("CSharpFunctionalExtensions.Maybe`1[[System.String]]")
oNone = oMaybeString.getProp("None")          # None is a static property of Maybe<T>
dnAssert("a Maybe without a value",oNone.HasNoValue,1)
dnAssert("GetValueOrDefault gives the other value",oNone.GetValueOrDefault("other"),"other")

dnTestSummary()

func double aArgs

	return aArgs[1] * 2
