# Tutorial 90: numbers that do not fit - BigInteger for exact big whole numbers, Complex numbers and the limits of Ring numbers
load "dotnet.ring"
using {
	"System"
	"System.Numerics"
}

func main
	# 1. A Ring number is a double: whole numbers are exact up to 9007199254740992 (2^53). After that, the last digits are lost.
	? "1. Ring: 9007199254740992 + 1 = " + (9007199254740992 + 1) + "   (the +1 is lost)"

	# 2. BigInteger keeps every digit. It is made from a text, and its result is shown as a text.
	oBig = new BigInteger()
	nA = oBig.Parse("9007199254740992")
	nB = oBig.Add(nA,oBig.One)
	? nl + "2. BigInteger: 9007199254740992 + 1 = " + nB.ToString()

	# 3. Factorials grow fast: 30! has 33 digits. The loop multiplies with BigInteger.Multiply
	oFact = oBig.One
	for n = 2 to 30
		oFact = oBig.Multiply(oFact,oBig.Parse("" + n))
	next
	? nl + "3. 30! = " + oFact.ToString()

	# 4. Power, remainder and the greatest common divisor. Pow takes the number and an exponent; ModPow does number^e mod m without
	#    ever building the huge number (this is the base of public-key cryptography).
	oTwo = oBig.Parse("2")
	? nl + "4. 2^100 = " + oBig.Pow(oTwo,100).ToString()
	? "   2^100 mod 1000007 = " + oBig.Remainder(oBig.Pow(oTwo,100),oBig.Parse("1000007")).ToString()
	? "   ModPow(2, 100, 1000007) = " + oBig.ModPow(oTwo,oBig.Parse("100"),oBig.Parse("1000007")).ToString()
	? "   GCD(1071, 462) = " + oBig.GreatestCommonDivisor(oBig.Parse("1071"),oBig.Parse("462")).ToString()

	# 5. Fibonacci with exact digits: fib(100) is 354224848179261915075
	a = oBig.Zero
	b = oBig.One
	for i = 1 to 100
		c = oBig.Add(a,b)
		a = b
		b = c
	next
	? nl + "5. fib(100) = " + a.ToString()
	? "   its digits: " + len(a.ToString())

	# 6. Comparing: Compare answers -1, 0 or 1 (a text compare of digits would be wrong: "9" > "10" as text)
	? nl + "6. Compare(2^100, 10^30) = " + oBig.Compare(oBig.Pow(oTwo,100),oBig.Pow(oBig.Parse("10"),30)) + "   (1: the first is larger; -1 would mean smaller)"

	# 7. Complex numbers: a real part and an imaginary part. Math with them is done by the static methods of Complex.
	oC = new Complex()
	oI = dnNew("Complex",[ :real = 0, :imaginary = 1 ])        # i
	oMinusOne = oC.Multiply(oI,oI)
	? nl + "7. i * i = " + oMinusOne.Real + " (real part), " + oMinusOne.Imaginary + " (imaginary part)"
	oZ = dnNew("Complex",[ :real = 3, :imaginary = 4 ])
	? "   |3 + 4i| = " + oZ.Magnitude + ",  3+4i squared = " + oC.Multiply(oZ,oZ).ToString()
