# Tutorial 101: number types - the limits of Byte, Int16, Int32, Int64 and Int128, overflow, checked conversion, Half and Single
load "dotnet.ring"
using {
	"System"
}

func main
	# A Ring number is always a double. .NET has many number types with different sizes and limits. When a number goes to .NET,
	# the bridge uses the type the method asks for, and a value that does not fit raises an error: it does not wrap around.
	oByte = new Byte()
	oShort = new Int16()
	oInt = new Int32()
	oLong = new Int64()

	# 1. The limits of each type (MinValue and MaxValue are static fields)
	? "1. the limits:"
	? "   Byte   0 .. " + oByte.MaxValue
	? "   Int16  " + oShort.MinValue + " .. " + oShort.MaxValue
	? "   Int32  " + oInt.MinValue + " .. " + oInt.MaxValue
	? "   Int64  " + oLong.MinValue + " .. " + oLong.MaxValue
	? "   (a Ring number is exact only up to 9007199254740992: the Int64 limit is shown rounded)"

	# 2. Converting a number that does not fit: Convert.ToByte checks the range and raises an error
	oConvert = new Convert()
	? nl + "2. 200 as a Byte: " + oConvert.ToByte(200)
	? "   300 as a Byte: " + try300(oConvert)
	? "   -1 as a Byte: " + tryMinus1(oConvert)

	# 3. TryParse says yes or no (and gives the number): the right way to read a number that a user typed
	? nl + "3. TryParse of Int32:"
	for cText in ["42","-7","3000000000","12abc","","  15  "]
		aResult = oInt.TryParse(cText)
		if aResult[1]
			? "   '" + cText + "' -> " + aResult[2]
		else
			? "   '" + cText + "' is not an Int32 (wrong text or too big)"
		ok
	next

	# 4. Integer division and the remainder: Math.DivRem gives both; negative numbers round toward zero
	oMath = new Math()
	aDiv = oMath.DivRem(17,5)
	? nl + "4. 17 divided by 5: quotient " + aDiv[1] + ", remainder " + aDiv[2]
	aDiv = oMath.DivRem(-17,5)
	? "   -17 divided by 5: quotient " + aDiv[1] + ", remainder " + aDiv[2] + "   (the remainder has the sign of the first number)"

	# 5. Int128 and UInt128: numbers of 128 bits (39 digits), made from a text
	oBig = new Int128()
	nBig = oBig.Parse("170141183460469231731687303715884105727")
	? nl + "5. the largest Int128: " + nBig.ToString()
	? "   the largest UInt128: " + new UInt128().MaxValue.ToString()

	# 6. Single (float) has about 7 digits, Double about 15: the same number is exact in one and not in the other
	? nl + "6. Single: 16777216 + 1 = " + singleSum() + "   (a Single cannot count past 16777216)"
	? "   Double: 16777216 + 1 = " + (16777216 + 1)
	? "   0.1 + 0.2 = " + (0.1 + 0.2) + ", equal to 0.3: " + (0.1 + 0.2 = 0.3) + ", close to 0.3: " + (fabs(0.1 + 0.2 - 0.3) < 0.0000001)

func try300 oConvert
	try
		return oConvert.ToByte(300)
	catch
		return "error (too big for a Byte)"
	done

func tryMinus1 oConvert
	try
		return oConvert.ToByte(-1)
	catch
		return "error (below zero)"
	done

func singleSum
	oConvert = new Convert()
	nA = oConvert.ToSingle(16777216)
	return oConvert.ToSingle(nA + 1)
