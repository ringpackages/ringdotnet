# OneOf: a value that is one of several types; the generic type is made with its type arguments, Match and Switch take callbacks
load "pkg.ring"
pkgUse("oneof",[["OneOf","3.0.271"]],[["OneOf.dll",["OneOf"]]])
pkgImport("oneof","OneOf.dll","OneOf")

cType = "OneOf.OneOf`2[[System.String],[System.Int32]]"
oText = dnStatic(cType,"FromT0",["hello"])
dnAssert("a union that holds a text",oText.IsT0,1)
dnAssert("it does not hold a number",oText.IsT1,0)
dnAssert("the text",oText.AsT0,"hello")
dnAssert("the index of the type",oText.Index,0)

oNumber = dnStatic(cType,"FromT1",[42])
dnAssert("a union that holds a number",oNumber.IsT1,1)
dnAssert("the number",oNumber.AsT1,42)
dnAssert("the value as an object",oNumber.Value,42)

# Match: one callback for each type, the result of the one that fits
cDescribed = oText.callMethod("Match",[dnCallback("describeText"),dnCallback("describeNumber")])
dnAssert("Match with a text",cDescribed,"text: hello")
dnAssert("Match with a number",oNumber.callMethod("Match",[dnCallback("describeText"),dnCallback("describeNumber")]),"number: 42")

# Switch: the callback of the type runs
cSeen = ""
oNumber.callMethod("Switch",[dnCallback("seeText"),dnCallback("seeNumber")])
dnAssert("Switch runs the callback of the type",cSeen,"saw number 42")

# TryPickT0: the answer is a list [yes, value, the rest]
aPick = oText.callMethod("TryPickT0",[])
dnAssert("TryPickT0 of a text",aPick[1],1)
dnAssert("the value",aPick[2],"hello")

dnTestSummary()

func describeText aArgs

	return "text: " + aArgs[1]

func describeNumber aArgs

	return "number: " + aArgs[1]

func seeText aArgs

	cSeen = "saw text " + aArgs[1]

func seeNumber aArgs

	cSeen = "saw number " + aArgs[1]
