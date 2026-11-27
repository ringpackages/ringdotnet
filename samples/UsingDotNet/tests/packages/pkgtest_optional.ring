# Optional: the Option<T> type (a value that may be missing): Some and None, Map, Match with callbacks, and the extension methods
load "pkg.ring"
pkgUse("optional",[["Optional","4.0.0"]],[["Optional.dll",["Optional","Optional.Collections","Optional.Linq","Optional.Unsafe"]]])
pkgImport("optional","Optional.dll","Optional")
pkgImport("optional","Optional.dll","Optional.Unsafe")

oOptionType = dnType("Optional.Option")
oSome = oOptionType.callGeneric("Some",["System.Int32"],[5])
dnAssert("an option with a value has a value",oSome.HasValue,1)
oNone = oOptionType.callGeneric("None",["System.Int32"],[])
dnAssert("an option without a value has none",oNone.HasValue,0)
dnAssert("a value is not a missing value",oSome.Equals(oNone),0)

# the value is read with Match: two callbacks, one for each case
cSome = matched(oSome)
dnAssert("Match calls the callback of a value",cSome,"value 5")
cNone = matched(oNone)
dnAssert("Match calls the callback of no value",cNone,"nothing")

# Map changes the value (and does nothing to a missing one)
oDoubled = oSome.callGeneric("Map",["System.Int32"],[dnCallback("double")])
dnAssert("Map changes the value",matched(oDoubled),"value 10")
oNoneMapped = oNone.callGeneric("Map",["System.Int32"],[dnCallback("double")])
dnAssert("Map keeps a missing value missing",oNoneMapped.HasValue,0)

dnTestSummary()

# Match<TResult> only gets its result type from you: the callbacks return text
func matched oOption

	return oOption.callGeneric("Match",["System.String"],[dnCallback("whenSome"),dnCallback("whenNone")])

# a callback gets the arguments of .NET as a list
func whenSome aArgs

	return "value " + aArgs[1]

func whenNone aArgs

	return "nothing"

func double aArgs

	return aArgs[1] * 2
