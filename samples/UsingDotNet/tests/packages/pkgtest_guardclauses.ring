# Ardalis.GuardClauses: checks of arguments (Guard.Against.Null, NullOrEmpty, OutOfRange...) that raise errors with the name and the message; the checks are
# extension methods of the interface IGuardClause, and Guard.Against is a static property
load "pkg.ring"
pkgUse("guardclauses",[["Ardalis.GuardClauses","5.0.0"]],[["Ardalis.GuardClauses.dll",["Ardalis.GuardClauses"]]])
pkgImport("guardclauses","Ardalis.GuardClauses.dll","Ardalis.GuardClauses")

oGuard = dnType("Ardalis.GuardClauses.Guard").getProp("Against")
dnAssert("Against is an IGuardClause",classname(oGuard) != "",1)

# a value that passes is returned
dnAssert("a text that is not empty passes",oGuard.NullOrEmpty([ :input = "ring", :parameterName = "name" ]),"ring")
dnAssert("a number in range passes",oGuard.OutOfRange([ :input = 5, :parameterName = "n", :rangeFrom = 1, :rangeTo = 10 ]),5)

# a value that fails is an error with the name of the parameter
try
	oGuard.NullOrEmpty([ :input = "", :parameterName = "name" ])
	dnAssert("an empty text is an error",1,0)
catch
	dnAssert("an empty text is an error",substr(cCatchError,"name") > 0 and substr(cCatchError,"ArgumentException") > 0,1)
done
try
	oGuard.OutOfRange([ :input = 50, :parameterName = "n", :rangeFrom = 1, :rangeTo = 10 ])
	dnAssert("a number out of range is an error",1,0)
catch
	dnAssert("a number out of range is an error",substr(cCatchError,"ArgumentOutOfRangeException") > 0,1)
done
try
	oGuard.Negative([ :input = -3, :parameterName = "count" ])
	dnAssert("a negative number is an error",1,0)
catch
	dnAssert("a negative number is an error",substr(cCatchError,"count") > 0,1)
done
try
	oGuard.NegativeOrZero([ :input = 0, :parameterName = "size" ])
	dnAssert("zero is an error",1,0)
catch
	dnAssert("zero is an error",substr(cCatchError,"size") > 0,1)
done
try
	oGuard.InvalidFormat([ :input = "abc", :parameterName = "code", :regexPattern = "^[0-9]+$" ])
	dnAssert("a text that does not match is an error",1,0)
catch
	dnAssert("a text that does not match is an error",substr(cCatchError,"code") > 0,1)
done
dnAssert("a text that matches passes",oGuard.InvalidFormat([ :input = "123", :parameterName = "code", :regexPattern = "^[0-9]+$" ]),"123")

dnTestSummary()
