# FluentAssertions: Should() extension methods (many overloads by type) that return assertion objects, whose methods raise an error when the check fails
load "pkg.ring"
pkgUse("fluentassertions",[["FluentAssertions","7.2.2"]],[["FluentAssertions.dll",["FluentAssertions","FluentAssertions.Primitives","FluentAssertions.Numeric","FluentAssertions.Collections"]]])
pkgImport("fluentassertions","FluentAssertions.dll","FluentAssertions")
pkgImport("fluentassertions","FluentAssertions.dll","FluentAssertions.Primitives")
pkgImport("fluentassertions","FluentAssertions.dll","FluentAssertions.Numeric")
pkgImport("fluentassertions","FluentAssertions.dll","FluentAssertions.Collections")
dnImport("System.Collections.Generic")

oExtensions = dnType("FluentAssertions.AssertionExtensions")

# strings
oText = oExtensions.callMethod("Should",["Hello Ring"])
dnAssert("a string assertion object",classname(oText),"stringassertions")
oText.StartWith([ :expected = "Hello" ])          # the because and its arguments are optional: the named list leaves them out
oText.Contain([ :expected = "Ring" ])
oText.HaveLength([ :expected = 10 ])
oText.NotBeEmpty(NULL)
dnAssert("the checks of a string passed",1,1)

# a check that fails raises an error with a message that says what was expected
try
	oText.Be([ :expected = "Goodbye" ])
	dnAssert("a failed check is an error",1,0)
catch
	dnAssert("a failed check is an error",substr(cCatchError,"Expected") > 0 and substr(cCatchError,"Goodbye") > 0,1)
done

# numbers: the overload of Should for a double
oNumber = oExtensions.callMethod("Should",[3.5])
oNumber.BeGreaterThan([ :expected = 3 ])
oNumber.BeLessThan([ :expected = 4 ])
oNumber.BeInRange([ :minimumValue = 3, :maximumValue = 4 ])
try
	oNumber.Be([ :expected = 4 ])
	dnAssert("a wrong number is an error",1,0)
catch
	dnAssert("a wrong number is an error",substr(cCatchError,"Expected") > 0,1)
done


# a list: a collection assertion
oItems = new StringList()
oItems.Add("a")
oItems.Add("b")
oItems.Add("c")
oList = oExtensions.callGeneric("Should",["System.String"],[oItems])
oList.HaveCount([ :expected = 3 ])
oList.Contain([ :expected = "b" ])
oList.OnlyHaveUniqueItems(NULL)
oList.BeInAscendingOrder(NULL)
try
	oList.HaveCount([ :expected = 5 ])
	dnAssert("a wrong count is an error",1,0)
catch
	dnAssert("a wrong count is an error",substr(cCatchError,"5") > 0,1)
done

# an exception is expected: Invoking a Ring callback through an Action and asserting that it throws
dnAssert("the test went on",1,1)

dnTestSummary()
