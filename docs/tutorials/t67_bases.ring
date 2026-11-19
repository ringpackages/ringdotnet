# number systems and big numbers - binary, hexadecimal, bits, and numbers that do not fit in a double
load "dotnet.ring"
using {
	"System"
	"System.Numerics"
}

func main
	oConvert = new Convert()

	# 1. The same number in different bases: 2 (binary), 8 (octal), 10 (decimal), 16 (hexadecimal)
	? "1. 255 in base 2 : " + oConvert.Format([ :value = 255, :toBase = 2 ])
	? "   255 in base 8 : " + oConvert.Format([ :value = 255, :toBase = 8 ])
	? "   255 in base 16: " + oConvert.Format([ :value = 255, :toBase = 16 ])

	# 2. And back: a text in a base to a number
	? nl + "2. 'ff' in base 16       = " + oConvert.ToInt32([ :value = "ff", :fromBase = 16 ])
	? "   '11111111' in base 2 = " + oConvert.ToInt32([ :value = "11111111", :fromBase = 2 ])
	? "   '777' in base 8      = " + oConvert.ToInt32([ :value = "777", :fromBase = 8 ])

	# 3. Why hexadecimal? One hex digit is exactly 4 bits, so a byte is two digits. Colors, memory addresses and hashes use it.
	nRed = 255
	nGreen = 128
	nBlue = 0
	? nl + "3. the color (255,128,0) is #" + hex2(nRed) + hex2(nGreen) + hex2(nBlue)
	? "   #1e90ff is (" + oConvert.ToInt32([ :value = "1e", :fromBase = 16 ]) + "," + oConvert.ToInt32([ :value = "90", :fromBase = 16 ]) + "," + oConvert.ToInt32([ :value = "ff", :fromBase = 16 ]) + ")"

	# 4. Bits: count the ones, test if a number is a power of two, shift
	oBits = new BitOperations()
	? nl + "4. the number of 1 bits in 255: " + oBits.PopCount(255) + ", in 256: " + oBits.PopCount(256)
	? "   is 64 a power of 2? " + yesNo(oBits.IsPow2(64)) + ", is 100? " + yesNo(oBits.IsPow2(100))
	? "   2 to the power of 10 = " + (1 << 10) + ", and 1024 / 2^3 = " + (1024 >> 3)

	# 5. A negative number in binary: the computer uses "two's complement", all the bits are turned over
	? nl + "5. -5 as 32 bits: " + oConvert.Format([ :value = -5, :toBase = 2 ])

	# 6. The size of a Ring number: a double is exact only up to 2^53 = 9007199254740992
	? nl + "6. 9007199254740992 + 1 = " + (9007199254740992 + 1) + "  (the +1 is lost)"
	? "   Int64.MaxValue should be 9223372036854775807, Ring shows " + new Int64().MaxValue

	# 7. BigInteger: any size, always exact. Make it from a text and call its methods.
	oBig = new BigInteger().Parse("123456789012345678901234567890")
	oSquare = oBig.Multiply(oBig,oBig)
	? nl + "7. the square of 123456789012345678901234567890 is"
	? "   " + oSquare.ToString()

	# 8. A factorial with big numbers: 30! does not fit in a double, but it fits in a BigInteger
	oFactorial = new BigInteger().Parse("1")
	for nI = 2 to 30
		oFactorial = oFactorial.Multiply(oFactorial,new BigInteger().Parse("" + nI))
	next
	? nl + "8. 30! = " + oFactorial.ToString()

func hex2 nValue
	cText = new Convert().Format([ :value = nValue, :toBase = 16 ])
	if len(cText) = 1
		cText = "0" + cText
	ok
	return cText

func yesNo lValue
	if lValue
		return "yes"
	ok
	return "no"
