# an expression calculator - tokens, a recursive-descent parser, precedence and clear errors
load "dotnet.ring"

using {
	"System"
	"System.Text.RegularExpressions"
}

func main

	aTests = ["1 + 2 * 3","(1 + 2) * 3","10 / 4 - 1","2 ^ 3 ^ 2","-(2 + 3) * 4","sqrt(16) + max(3, 9)","2 * (3 + ","4 $ 4","1 / 0"]
	for cText in aTests
		oCalc = new Evaluator()
		? padRight(cText,24) + " = " + oCalc.calculate(cText)
	next

func padRight cText, nWidth

	while len(cText) < nWidth
		cText += " "
	end
	return cText

# Step 1: the text becomes tokens (numbers, names, operators). Step 2: the parser reads the tokens following the grammar:
#   expression = term { (+|-) term }          term = power { (*|/) power }
#   power      = unary [ ^ power ]            unary = - unary | primary
#   primary    = number | ( expression ) | name ( expression { , expression } )
class Evaluator

	aTokens = []
	nPos = 0
	cError = ""

	func init

		return self

	func calculate cText

		cError = ""
		aTokens = tokenize(cText)
		if cError != ""
			return "error: " + cError
		ok
		nPos = 1
		nValue = expression()
		if cError = "" and nPos <= len(aTokens)
			cError = "unexpected '" + aTokens[nPos] + "'"
		ok
		if cError != ""
			return "error: " + cError
		ok
		return nValue

	# Regex.Matches finds every piece; anything that is not a number, a name, an operator or a space is an error
	func tokenize cText

		aList = []
		oMatches = new Regex("\s*(\d+\.?\d*|[A-Za-z]+|[-+*/^(),]|\S)").Matches(cText)
		for nIndex = 0 to oMatches.Count - 1
			cToken = oMatches.Item(nIndex).Groups.Item(1).Value
			if not new Regex("^(\d+\.?\d*|[A-Za-z]+|[-+*/^(),])$").IsMatch(cToken)
				cError = "unknown character '" + cToken + "'"
				return []
			ok
			aList + cToken
		next
		return aList

	func peek

		if nPos <= len(aTokens)
			return aTokens[nPos]
		ok
		return ""

	func expression

		nLeft = term()
		while cError = "" and (peek() = "+" or peek() = "-")
			cOp = peek()
			nPos++
			nRight = term()
			if cOp = "+"
				nLeft += nRight
			else
				nLeft -= nRight
			ok
		end
		return nLeft

	func term

		nLeft = power()
		while cError = "" and (peek() = "*" or peek() = "/")
			cOp = peek()
			nPos++
			nRight = power()
			if cOp = "*"
				nLeft *= nRight
			else
				if nRight = 0
					cError = "division by zero"
					return 0
				ok
				nLeft /= nRight
			ok
		end
		return nLeft

	# ^ goes to the right: 2^3^2 = 2^(3^2)
	func power

		nBase = unary()
		if cError = "" and peek() = "^"
			nPos++
			return pow(nBase,power())
		ok
		return nBase

	func unary

		if peek() = "-"
			nPos++
			return -unary()
		ok
		return primary()

	func primary

		cToken = peek()
		if cToken = ""
			cError = "the expression ends too early"
			return 0
		ok
		nPos++
		if new Regex("^\d").IsMatch(cToken)
			return number(cToken)
		ok
		if cToken = "("
			nValue = expression()
			expect(")")
			return nValue
		ok
		if new Regex("^[A-Za-z]").IsMatch(cToken)
			return callFunction(cToken)
		ok
		cError = "unexpected '" + cToken + "'"
		return 0

	func expect cToken

		if cError != ""
			return
		ok
		if peek() != cToken
			cError = "'" + cToken + "' expected"
			return
		ok
		nPos++

	# name ( arguments ): the functions come from the .NET Math class
	func callFunction cName

		expect("(")
		aArgs = []
		if peek() != ")"
			aArgs + expression()
			while cError = "" and peek() = ","
				nPos++
				aArgs + expression()
			end
		ok
		expect(")")
		if cError != ""
			return 0
		ok
		oMath = new Math()
		switch lower(cName)
		on "sqrt"
			return oMath.Sqrt(aArgs[1])
		on "abs"
			return oMath.Abs(aArgs[1])
		on "max"
			return oMath.Max(aArgs[1],aArgs[2])
		on "min"
			return oMath.Min(aArgs[1],aArgs[2])
		on "round"
			return oMath.Round(aArgs[1])
		off
		cError = "unknown function " + cName
		return 0
