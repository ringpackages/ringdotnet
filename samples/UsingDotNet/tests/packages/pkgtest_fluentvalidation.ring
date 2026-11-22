# FluentValidation: the rules are in a validator class written in .NET (a helper project: Ring cannot derive from AbstractValidator<T>); the class derives from
# the Ring class of AbstractValidator, so it has its methods, also ValidateAndThrow (an extension method of the interface IValidator<T>). Ring makes the
# objects, runs the validator and reads the errors; the rules of a second validator come from Ring callbacks
load "pkg.ring"
pkgUseProject("fluentvalidation","helpers/PkgHelpers",[["FluentValidation.dll",["FluentValidation","FluentValidation.Results"]],["PkgHelpers.dll",["PkgHelpers"]]])
pkgImport("fluentvalidation","PkgHelpers.dll","PkgHelpers")          # the classes of PkgHelpers derive from the ones of FluentValidation (wrapped first, into the same folder)
pkgImport("fluentvalidation","FluentValidation.dll","FluentValidation")
pkgImport("fluentvalidation","FluentValidation.dll","FluentValidation.Results")

oValidator = new PersonValidator()

# a valid person
oAnn = new Person()
oAnn.FirstName = "Ann"
oAnn.Age = 31
oAnn.Email = "ann@example.org"
oResult = oValidator.Validate(oAnn)
dnAssert("a valid person",oResult.IsValid,1)
dnAssert("a valid person has no errors",oResult.Errors.Count,0)

# an invalid one: three rules fail
oBad = new Person()
oBad.Age = 200
oBad.Email = "not an email"
oResult = oValidator.Validate(oBad)
dnAssert("an invalid person",oResult.IsValid,0)
dnAssert("three errors",oResult.Errors.Count,3)
aNames = []
for i = 0 to oResult.Errors.Count - 1
	add(aNames,oResult.Errors.Item(i).PropertyName)
next
dnAssert("the properties that failed",find(aNames,"FirstName") > 0 and find(aNames,"Age") > 0 and find(aNames,"Email") > 0,1)
dnAssert("the message of a rule",oResult.Errors.Item(0).ErrorMessage,"First name is required")
dnAssert("ToString lists the errors",substr(oResult.ToString(),"Age must be between 0 and 150") > 0,1)

# the email rule only runs when there is an email
oNoMail = new Person()
oNoMail.FirstName = "Bo"
oNoMail.Age = 5
dnAssert("a missing email is fine",oValidator.Validate(oNoMail).IsValid,1)

# the rules from Ring: a callback is the check
oRules = new RingRules()
oRules.Rule("Age",dnCallback("isAdult"),"must be an adult")
oRules.Rule("FirstName",dnCallback("startsWithCapital"),"must start with a capital")
oChild = new Person()
oChild.FirstName = "ann"
oChild.Age = 12
oResult = oRules.Validate(oChild)
dnAssert("two rules of Ring fail",oResult.Errors.Count,2)
dnAssert("the message of a rule of Ring",oResult.Errors.Item(0).ErrorMessage,"must be an adult")
dnAssert("the property of a rule of Ring",oResult.Errors.Item(1).PropertyName,"FirstName")
oAdult = new Person()
oAdult.FirstName = "Cy"
oAdult.Age = 40
dnAssert("the rules of Ring pass",oRules.Validate(oAdult).IsValid,1)

# a validator that throws: ValidateAndThrow
try
	oValidator.ValidateAndThrow(oBad)
	dnAssert("ValidateAndThrow raises an error",1,0)
catch
	dnAssert("ValidateAndThrow raises an error",substr(cCatchError,"Validation failed") > 0,1)
done

dnTestSummary()

func isAdult aArgs
	return aArgs[1] >= 18

func startsWithCapital aArgs
	cName = aArgs[1]
	return len(cName) > 0 and cName[1] = upper(cName[1]) and cName[1] != lower(cName[1])
