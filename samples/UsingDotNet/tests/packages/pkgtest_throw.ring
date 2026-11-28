# Throw: argument checks written as value.Throw().IfNegative(): the extension methods are called through their static classes; a check that fails raises the .NET exception
load "pkg.ring"
pkgUse("throw",[["Throw","1.4.0"]],[["Throw.dll",["Throw"]]])
pkgImport("throw","Throw.dll","Throw")

# a check that passes gives back the value to go on with, a check that fails raises an error
dnAssert("a value that is not negative",fails("IfNegative",5,[]),False)
dnAssert("a negative value",fails("IfNegative",-5,[]),True)
dnAssert("a value that is above zero",fails("IfNegativeOrZero",3,[]),False)
dnAssert("a zero is not above zero",fails("IfNegativeOrZero",0,[]),True)
dnAssert("a value that is positive",fails("IfPositive",2,[]),True)
dnAssert("a value that is not positive",fails("IfPositive",-2,[]),False)

# text
dnAssert("a text that is not empty",fails("IfEmpty","ring",[]),False)
dnAssert("an empty text",fails("IfEmpty","",[]),True)
dnAssert("a text of spaces",fails("IfWhiteSpace","   ",[]),True)
dnAssert("a text that is not spaces",fails("IfWhiteSpace","a b",[]),False)
dnAssert("a text with a part",fails("IfContains","hello world",["world"]),True)
dnAssert("a text without the part",fails("IfContains","hello",["world"]),False)
dnAssert("a long text",fails("IfLongerThan","abcdef",[3]),True)
dnAssert("a short text",fails("IfLongerThan","ab",[3]),False)
dnAssert("a text that starts with a part",fails("IfStartsWith","hello",["he"]),True)
dnAssert("a text that does not",fails("IfStartsWith","hello",["xx"]),False)
dnAssert("a text that is too short",fails("IfShorterThan","ab",[3]),True)

# comparisons with limits
dnAssert("a value below a limit",fails("IfLessThan",3,[5]),True)
dnAssert("a value above a limit",fails("IfLessThan",7,[5]),False)
dnAssert("a value above the maximum",fails("IfGreaterThan",9,[5]),True)
dnAssert("a value in a range",fails("IfOutOfRange",5,[1,10]),False)
dnAssert("a value out of a range",fails("IfOutOfRange",11,[1,10]),True)
dnAssert("a value that equals another",fails("IfEquals",4,[4]),True)
dnAssert("a value that differs",fails("IfEquals",4,[5]),False)

# the message tells what is wrong
cMessage = message("IfNegative",-5,[])
dnAssert("the message says what is wrong",substr(cMessage,"should not be less than 0") > 0,True)
dnAssert("the message has the value",substr(cMessage,"-5") > 0,True)
dnAssert("an empty text message",substr(message("IfEmpty","",[]),"should not be empty") > 0,True)

dnTestSummary()

func check cMethod, xValue, aArgs

	oThrow = dnStatic("Throw.ValidatableCreationExtensions","Throw",[xValue])
	aParameters = [oThrow]
	for xArgument in aArgs
		aParameters + xArgument
	next
	return dnStatic("Throw.ValidatableExtensions",cMethod,aParameters)

func fails cMethod, xValue, aArgs

	try
		check(cMethod,xValue,aArgs)
	catch
		if substr(cCatchError,"MissingMethodException") > 0
			dnAssert("the method " + cMethod + " exists",0,1)
		ok
		return True
	done
	return False

func message cMethod, xValue, aArgs

	try
		check(cMethod,xValue,aArgs)
	catch
		return cCatchError
	done
	return ""
