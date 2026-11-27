# NUnit: the assertion library (Assert.That with the constraints Is, Has, Does, Contains), and the message of a failed assertion as an error
load "pkg.ring"
pkgUse("nunit",[["NUnit","5.0.0"]],[["nunit.framework.dll",["NUnit.Framework","NUnit.Framework.Constraints"]]])
pkgImport("nunit","nunit.framework.dll","NUnit.Framework")
pkgImport("nunit","nunit.framework.dll","NUnit.Framework.Constraints")

oIs = new Is()
oEqual = oIs.EqualTo(5)
dnAssert("a constraint is an object",classname(oEqual),"equalnumericconstraint")

oAssert = new Assert()
oAssert.That([ :actual = 5, :expression = oEqual ])
oAssert.That([ :actual = "ring", :expression = oIs.EqualTo("ring") ])
oAssert.That([ :actual = 7, :expression = oIs.GreaterThan(3) ])
oAssert.That([ :actual = 2, :expression = oIs.LessThanOrEqualTo(2) ])
oNot = oIs.@Not
oAssert.That([ :actual = "hello world", :expression = oNot.EqualTo("hello") ])
dnAssert("assertions that hold do not raise errors",1,1)

# strings and ranges
oDoes = new Does()
oAssert.That([ :actual = "hello world", :expression = oDoes.StartWith("hello") ])
oAssert.That([ :actual = "hello world", :expression = oDoes.Contain("o w") ])
oAssert.That([ :actual = 5, :expression = oIs.InRange(1,10) ])
oAssert.That([ :actual = 3.14, :expression = oIs.EqualTo(3.1).Within(0.1) ])

# a failed assertion is an error, and its message says what was expected and what the value was
lFailed = 0
cMessage = ""
try
	oAssert.That([ :actual = 5, :expression = oIs.EqualTo(6) ])
catch
	lFailed = 1
	cMessage = cCatchError
done
dnAssert("a failed assertion is an error",lFailed,1)
dnAssert("the message tells what was expected",substr(cMessage,"Expected: 6") > 0,1)
dnAssert("the message tells the value",substr(cMessage,"But was:  5") > 0,1)

dnTestSummary()
