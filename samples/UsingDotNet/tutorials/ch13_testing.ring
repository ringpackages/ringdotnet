# testing your programs - small functions, dnAssert, expected errors, a test summary
#   ring ch13_testing.ring            all tests pass
#   ring ch13_testing.ring --break    one test fails on purpose, to show what a failure looks like
load "dotnet.ring"
using {
	"System"
	"System.Text.RegularExpressions"
}

func main
	testFizzBuzz()
	testWordCount()
	testDates()
	testErrors()
	if find(sysargv,"--break") > 0
		testBrokenOnPurpose()
	ok
	nFailed = dnTestSummary()               # prints "TESTS: n passed, m failed" and returns the number of failures

# ---------------------------------------------------------------- the code that is tested (small, with one job each)

func fizzBuzz nNumber
	if nNumber % 15 = 0
		return "FizzBuzz"
	ok
	if nNumber % 3 = 0
		return "Fizz"
	ok
	if nNumber % 5 = 0
		return "Buzz"
	ok
	return "" + nNumber

func wordCount cText
	if trim(cText) = ""
		return 0
	ok
	return new Regex("\s+").Split(trim(cText)).Length

func daysUntil nYear, nMonth, nDay, nFromYear, nFromMonth, nFromDay
	oFrom = new DateTime(nFromYear,nFromMonth,nFromDay)
	oTo = new DateTime(nYear,nMonth,nDay)
	return oTo.Subtract(oFrom).Days

func toNumber cText
	aResult = new Int32().TryParse(cText)
	if not aResult[1]
		raise("Not a number: " + cText)
	ok
	return aResult[2]

# ---------------------------------------------------------------- the tests: dnAssert(name, actual, expected)

func testFizzBuzz
	dnAssert("3 is Fizz",fizzBuzz(3),"Fizz")
	dnAssert("10 is Buzz",fizzBuzz(10),"Buzz")
	dnAssert("30 is FizzBuzz",fizzBuzz(30),"FizzBuzz")
	dnAssert("7 is 7",fizzBuzz(7),"7")

func testWordCount
	dnAssert("empty text",wordCount(""),0)
	dnAssert("spaces only",wordCount("    "),0)
	dnAssert("one word",wordCount("Ring"),1)
	dnAssert("many spaces between words",wordCount("  Ring   and  .NET "),3)

func testDates
	dnAssert("a week",daysUntil(2024,1,8,2024,1,1),7)
	dnAssert("over a leap day",daysUntil(2024,3,1,2024,2,28),2)
	dnAssert("the same day",daysUntil(2024,5,5,2024,5,5),0)

# Test that an error is raised: catch it and remember that it happened
func testErrors
	dnAssert("a number",toNumber("42"),42)
	lRaised = False
	try
		toNumber("abc")
	catch
		lRaised = True
		dnAssert("the message says why",cCatchError,"Not a number: abc")
	done
	dnAssert("an error was raised",lRaised,True)

func testBrokenOnPurpose
	dnAssert("2 + 2 is 5 (wrong on purpose)",2 + 2,5)
