# FluentResults: result objects instead of exceptions; generic static factories (Result.Ok<T>), errors and successes with messages
load "pkg.ring"
pkgUse("fluentresults",[["FluentResults","4.0.0"]],[["FluentResults.dll",["FluentResults"]]])
pkgImport("fluentresults","FluentResults.dll","FluentResults")

oOk = dnStatic("FluentResults.Result","Ok",[])
dnAssert("an ok result",oOk.IsSuccess,1)
dnAssert("it is not failed",oOk.IsFailed,0)

oFail = dnStatic("FluentResults.Result","Fail",["it broke"])
dnAssert("a failed result",oFail.IsFailed,1)
dnAssert("one error",len(oFail.Errors.toList()),1)
dnAssert("the message of the error",oFail.Errors.toList()[1].Message,"it broke")

oValue = dnType("FluentResults.Result").callGeneric("Ok",["System.Int32"],[42])
dnAssert("a result with a value",oValue.Value,42)
dnAssert("and is a success",oValue.IsSuccess,1)

oBad = dnType("FluentResults.Result").callGeneric("Fail",["System.Int32"],["no value"])
dnAssert("a failed result of a type",oBad.IsFailed,1)
dnAssert("its value is the default",oBad.ValueOrDefault,0)

oMany = dnStatic("FluentResults.Result","Fail",[["first","second"]])
dnAssert("several errors",len(oMany.Errors.toList()),2)
dnAssert("the second message",oMany.Errors.toList()[2].Message,"second")

dnAssert("the text of a failed result",substr(oFail.ToString(),"it broke") > 0,1)
dnAssert("an Arabic error message",dnStatic("FluentResults.Result","Fail",["فشل"]).Errors.toList()[1].Message,"فشل")

# the value of a failed result is an error
cError = ""
try
	oBad.Value
catch
	cError = cCatchError
done
dnAssert("the value of a failed result raises an error",len(cError) > 0,1)

dnTestSummary()
