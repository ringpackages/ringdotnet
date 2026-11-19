# building code while the program runs - expression trees (System.Linq.Expressions): build, show, compile and call
load "dotnet.ring"
using {
	"System"
	"System.Linq.Expressions"
}

func main
	# The expression class of this namespace is called ExpressionsExpression in Ring (the name Expression is used by another namespace).
	oExpression = new ExpressionsExpression()
	oDouble = dnType("System.Double")

	# 1. An expression tree is code as DATA: a tree of objects. Two parameters a and b, and a node that adds them.
	oA = oExpression.Parameter([ :type = oDouble, :name = "a" ])
	oB = oExpression.Parameter([ :type = oDouble, :name = "b" ])
	oSum = oExpression.Add([ :left = oA, :right = oB ])
	? "1. the tree prints as code: " + oSum.ToString() + ", the kind of its top node: " + oSum.NodeType

	# 2. A lambda is a whole function: a body and its parameters. Compile turns the tree into a real function of the runtime.
	oLambda = oExpression.Lambda([ :body = oSum, :parameters = [oA,oB] ])
	oAdd = oLambda.Compile(NULL)
	? nl + "2. the lambda: " + oLambda.ToString() + "; calling it with 2 and 3.5 gives " + oAdd.callMethod("DynamicInvoke",[[2,3.5]])

	# 3. Bigger trees: (a + b) * 10, and a decision: if a > b then a else b
	oTimes = oExpression.Multiply([ :left = oSum, :right = oExpression.Constant(10.0) ])
	oScaled = oExpression.Lambda([ :body = oTimes, :parameters = [oA,oB] ])
	? nl + "3. " + oScaled.ToString() + " with 1 and 2 gives " + oScaled.Compile(NULL).callMethod("DynamicInvoke",[[1,2]])
	oTest = oExpression.GreaterThan([ :left = oA, :right = oB ])
	oChoice = oExpression.Condition([ :test = oTest, :ifTrue = oA, :ifFalse = oB ])
	oMax = oExpression.Lambda([ :body = oChoice, :parameters = [oA,oB] ])
	oMaxFunction = oMax.Compile(NULL)
	? "   " + oMax.ToString() + ": max of 7 and 3 is " + oMaxFunction.callMethod("DynamicInvoke",[[7,3]]) + ", of 2 and 9 is " + oMaxFunction.callMethod("DynamicInvoke",[[2,9]])

	# 4. A call of a .NET method inside the tree: Math.Sqrt(a * a + b * b), the length of the hypotenuse
	oSqrt = new Type().GetType("System.Math").GetMethod("Sqrt")
	oSquares = oExpression.Add([ :left = oExpression.Multiply([ :left = oA, :right = oA ]), :right = oExpression.Multiply([ :left = oB, :right = oB ]) ])
	oHypotenuse = oExpression.Call_([ :instance = dnNull(), :method = oSqrt, :arguments = [oSquares] ])
	oLength = oExpression.Lambda([ :body = oHypotenuse, :parameters = [oA,oB] ])
	? nl + "4. " + oLength.ToString() + " with 3 and 4 gives " + oLength.Compile(NULL).callMethod("DynamicInvoke",[[3,4]])

	# 5. Why? The tree is data: a program can BUILD it from something the user wrote (a formula, a rule, a filter), look at it, and run it as fast
	#    compiled code. Here a small helper builds "a OP b" from the name of an operator.
	? nl + "5. one helper, four functions (compiled from a tree built for each operator):"
	for cOperator in ["+","-","*","/"]
		oFunction = binaryFunction(oExpression,oA,oB,cOperator)
		? "   a " + cOperator + " b with 12 and 4: " + oFunction.callMethod("DynamicInvoke",[[12,4]])
	next

# the compiled function of "a OP b" for an operator written as text
func binaryFunction oExpression, oA, oB, cOperator
	switch cOperator
	on "+"
		oBody = oExpression.Add([ :left = oA, :right = oB ])
	on "-"
		oBody = oExpression.Subtract([ :left = oA, :right = oB ])
	on "*"
		oBody = oExpression.Multiply([ :left = oA, :right = oB ])
	on "/"
		oBody = oExpression.Divide([ :left = oA, :right = oB ])
	off
	return oExpression.Lambda([ :body = oBody, :parameters = [oA,oB] ]).Compile(NULL)
