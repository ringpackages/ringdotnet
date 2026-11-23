# rounding and the Math class - Round with its modes, Floor, Ceiling, Truncate, DivRem, Clamp, Sign and the rounding of money
load "dotnet.ring"

using {
	"System"
}

func main

	oMath = new Math()

	# 1. Round has a MODE for the numbers that are exactly in the middle (x.5). "ToEven" (the default of .NET, called banker's rounding) goes to
	#    the even neighbor, so that rounding many numbers does not push the total up; "AwayFromZero" is the rule taught at school.
	? "1. Round of x.5 with the two modes:"
	? "   " + padRight("value",8) + padRight("ToEven",9) + "AwayFromZero"
	for nValue in [ 0.5, 1.5, 2.5, 3.5, -0.5, -1.5, -2.5 ]
		nEven = oMath.Round([ :value = nValue, :mode = "ToEven" ])
		nAway = oMath.Round([ :value = nValue, :mode = "AwayFromZero" ])
		? "   " + padRight("" + nValue,8) + padRight("" + nEven,9) + nAway
	next

	# 2. Digits after the point: Round(value, digits). The modes work for the middle of the digit too: 0.125 is in the middle between 0.12 and 0.13.
	#    ToEven chooses 0.12 (the last digit 2 is even) and AwayFromZero chooses 0.13; 0.135 is in the middle between 0.13 and 0.14: ToEven
	#    chooses 0.14 (4 is even).
	? nl + "2. Round with digits:"
	decimals(3)                                         # Ring shows two decimals by default: show three for this step
	? "   Round(3.14159, 2)             = " + oMath.Round([ :value = 3.14159, :digits = 2 ])
	for nValue in [ 0.125, 0.135 ]
		nEven = oMath.Round([ :value = nValue, :digits = 2, :mode = "ToEven" ])
		nAway = oMath.Round([ :value = nValue, :digits = 2, :mode = "AwayFromZero" ])
		? "   Round(" + nValue + ", 2): ToEven " + nEven + ", AwayFromZero " + nAway
	next
	decimals(2)

	# 3. Floor, Ceiling and Truncate: three other ways to a whole number. They differ only for negative numbers.
	? nl + "3. Floor, Ceiling, Truncate:"
	? "   " + padRight("value",8) + padRight("Floor",7) + padRight("Ceiling",9) + "Truncate"
	for nValue in [ 2.7, 2.2, -2.2, -2.7 ]
		? "   " + padRight("" + nValue,8) + padRight("" + oMath.Floor(nValue),7) + padRight("" + oMath.Ceiling(nValue),9) + oMath.Truncate(nValue)
	next
	? "   Floor goes down, Ceiling goes up, Truncate cuts the decimals (toward zero)."

	# 4. Division with a remainder. Ring has the operator % for the remainder; the sign of the remainder follows the sign of the first number.
	? nl + "4. division with a remainder:"
	? "   17 / 5 = " + floor(17 / 5) + " remainder " + (17 % 5)
	? "   -17 / 5 = " + oMath.Truncate(-17 / 5) + " remainder " + (-17 % 5) + "  (the remainder has the sign of -17)"

	# 5. Limits: Clamp keeps a number between a minimum and a maximum, Sign gives -1, 0 or 1, Abs the size without the sign
	? nl + "5. Clamp, Sign, Abs:"
	for nValue in [ -5, 40, 250 ]
		? "   Clamp(" + padRight("" + nValue,4) + ", 0, 100) = " + oMath.Clamp(nValue,0,100)
	next
	? "   Sign(-8) = " + oMath.Sign(-8) + ", Sign(0) = " + oMath.Sign(0) + ", Sign(8) = " + oMath.Sign(8) + ", Abs(-8) = " + oMath.Abs(-8)

	# 6. Powers and roots: Pow, Sqrt, Cbrt, Log, Log10, Exp and the constants PI and E
	? nl + "6. powers and logarithms:"
	? "   Pow(2, 10) = " + oMath.Pow(2,10) + ", Sqrt(144) = " + oMath.Sqrt(144) + ", Cbrt(27) = " + oMath.Cbrt(27)
	? "   Log10(1000) = " + oMath.Log10(1000) + ", Log2(1024) = " + oMath.Log2(1024) + ", Log(E) = " + oMath.Log(2.718281828459045)

	# 7. Rounding money: the total of many prices should not be wrong by a cent. The same prices rounded in two ways give two totals.
	? nl + "7. ten items of 0.125 each (one eighth of a unit):"
	nEvenTotal = 0
	nAwayTotal = 0
	for i = 1 to 10
		nEvenTotal += oMath.Round([ :value = 0.125, :digits = 2, :mode = "ToEven" ])
		nAwayTotal += oMath.Round([ :value = 0.125, :digits = 2, :mode = "AwayFromZero" ])
	next
	? "   rounded to cents with ToEven:       " + nEvenTotal + "   (the exact total is 1.25)"
	? "   rounded to cents with AwayFromZero: " + nAwayTotal
	? "   A shop uses ONE rule everywhere and rounds only the final amount, or the amount of each line, as the law of the country says."

func padRight cText,nWidth

	return cText + copy(" ",nWidth - len(cText))
