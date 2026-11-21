# vectors and matrices - Vector3 (length, dot and cross product, distance), Vector2 and a rotation with Matrix3x2
load "dotnet.ring"
using {
	"System"
	"System.Numerics"
}

func main
	# 1. A Vector3 holds three numbers (X, Y, Z): a point or a direction in space (Vector2 has two numbers, Vector4 four).
	#    The numbers are single-precision floats, so results are shown rounded.
	oA = new Vector3().@New([ :x = 3, :y = 4, :z = 0 ])
	oB = new Vector3().@New([ :x = 1, :y = 2, :z = 3 ])
	? "1. a = " + show3(oA) + ", length of a = " + oA.Length() + ", squared length = " + oA.LengthSquared()

	# 2. The operations are static methods: Add, Subtract, Multiply (by a number), Negate
	oVector = new Vector3()
	? nl + "2. a + b = " + show3(oVector.Add(oA,oB))
	? "   a - b = " + show3(oVector.Subtract(oA,oB))
	? "   a * 2 = " + show3(oVector.Multiply(oA,2))
	? "   -a    = " + show3(oVector.Negate(oA))

	# 3. Dot product: a number that is 0 when two directions are at a right angle. Cross product: a vector at a right angle to both.
	oX = new Vector3().@New([ :x = 1, :y = 0, :z = 0 ])
	oY = new Vector3().@New([ :x = 0, :y = 1, :z = 0 ])
	? nl + "3. x . y = " + oVector.Dot(oX,oY) + " (a right angle), a . b = " + oVector.Dot(oA,oB)
	? "   x cross y = " + show3(oVector.Cross(oX,oY)) + " (the z axis)"

	# 4. Distance between two points, and the unit vector (length 1) of a direction
	? nl + "4. distance from a to b = " + oVector.Distance(oA,oB)
	? "   a with length 1 = " + show3(oVector.Normalize(oA))

	# 5. Lerp: the point between two points. 0 is the first one, 1 the second one, 0.5 the middle
	? nl + "5. the middle of a and b = " + show3(oVector.Lerp(oA,oB,0.5))

	# 6. A rotation of a 2D point with a matrix. Matrix3x2 does move, scale and rotate in the plane; the angle is in radians.
	oPoint = new Vector2().@New([ :x = 1, :y = 0 ])
	oMatrix = new Matrix3x2().CreateRotation(3.14159265358979 / 2)       # a quarter of a turn
	oRotated = new Vector2().Transform(oPoint,oMatrix)
	? nl + "6. the point (1, 0) turned by 90 degrees is (" + roundNumber(oRotated.X) + ", " + roundNumber(oRotated.Y) + ")"
	oMove = new Matrix3x2().CreateTranslation([ :xPosition = 10, :yPosition = 5 ])
	oMoved = new Vector2().Transform(oPoint,oMove)
	? "   moved by (10, 5): (" + oMoved.X + ", " + oMoved.Y + ")"
	oBoth = new Matrix3x2().Multiply(oMatrix,oMove)           # first turn, then move
	oResult = new Vector2().Transform(oPoint,oBoth)
	? "   turned and then moved: (" + roundNumber(oResult.X) + ", " + roundNumber(oResult.Y) + ")"

func show3 oVector
	return "(" + roundNumber(oVector.X) + ", " + roundNumber(oVector.Y) + ", " + roundNumber(oVector.Z) + ")"

# a number rounded to 3 decimals (a float has about 7 digits, so 1E-8 is "zero")
func roundNumber nValue
	nRounded = floor(nValue * 1000 + 0.5) / 1000
	if nRounded = 0
		nRounded = 0
	ok
	return nRounded
