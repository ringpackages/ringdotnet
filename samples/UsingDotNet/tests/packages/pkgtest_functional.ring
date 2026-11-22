# CSharpFunctionalExtensions: Result and Maybe types; generic structs with static factories and members
load "pkg.ring"
pkgUse("functional",[["CSharpFunctionalExtensions","3.7.0"]],[["CSharpFunctionalExtensions.dll",["CSharpFunctionalExtensions"]]])
pkgImport("functional","CSharpFunctionalExtensions.dll","CSharpFunctionalExtensions")

oOk = dnStatic("CSharpFunctionalExtensions.Result","Success",[])
dnAssert("a success",oOk.IsSuccess,1)
dnAssert("not a failure",oOk.IsFailure,0)

oFail = dnStatic("CSharpFunctionalExtensions.Result","Failure",["bad input"])
dnAssert("a failure",oFail.IsFailure,1)
dnAssert("its error text",oFail.Error,"bad input")

oValue = dnType("CSharpFunctionalExtensions.Result").callGeneric("Success",["System.Int32"],[42])
dnAssert("a success with a value",oValue.Value,42)

oBad = dnType("CSharpFunctionalExtensions.Result").callGeneric("Failure",["System.Int32"],["no number"])
dnAssert("a failure with a type",oBad.IsFailure,1)
dnAssert("and its error",oBad.Error,"no number")

cError = ""
try
	oBad.Value
catch
	cError = cCatchError
done
dnAssert("the value of a failure raises an error",len(cError) > 0,1)

oSome = dnType("CSharpFunctionalExtensions.Maybe").callGeneric("From",["System.String"],["ring"])
dnAssert("a maybe with a value",oSome.HasValue,1)
dnAssert("its value",oSome.Value,"ring")
oNone = dnStatic("CSharpFunctionalExtensions.Maybe`1[[System.String]]","None",[])
dnAssert("a maybe without a value",oNone.HasNoValue,1)
dnAssert("a default for none",oNone.GetValueOrDefault("fallback"),"fallback")

dnTestSummary()
