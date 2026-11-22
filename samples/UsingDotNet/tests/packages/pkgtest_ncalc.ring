# NCalc: expression evaluation; parameters, functions, comparison, and an expression that is wrong
load "pkg.ring"
pkgUse("ncalc",[["NCalcSync","7.4.0"]],[["NCalc.Core.dll",["NCalc"]],["NCalc.Domain.dll",[]],["NCalc.Parser.dll",[]],["NCalc.Sync.dll",[]]])
pkgImport("ncalc","NCalc.Core.dll","NCalc")

oExpression = new Expression("2 + 3 * 4")
dnAssert("precedence",oExpression.Evaluate(NULL),14)

oParams = new Expression("[x] * 2 + Max(1, 7)")
oParams.Parameters.SetItem("x",5)
dnAssert("a parameter and a function",oParams.Evaluate(NULL),17)

dnAssert("a comparison",new Expression("3 > 2 and 1 = 1").Evaluate(NULL),1)
dnAssert("a text",new Expression("'a' + 'b'").Evaluate(NULL),"ab")
dnAssert("a math function",new Expression("Abs(-3) + Round(2.6, 0)").Evaluate(NULL),6)
dnAssert("if",new Expression("if(2 > 1, 'yes', 'no')").Evaluate(NULL),"yes")

cError = ""
try
	new Expression("2 +").Evaluate(NULL)
catch
	cError = cCatchError
done
dnAssert("a wrong expression raises an error",len(cError) > 0,1)

dnTestSummary()
