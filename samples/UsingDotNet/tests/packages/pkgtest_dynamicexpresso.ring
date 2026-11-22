# DynamicExpresso: C# expressions evaluated at run time (Eval has several forms: the named list picks the one with the text and the parameters); variables from Ring, types made known, parsed once and called with parameters
load "pkg.ring"
pkgUse("dynamicexpresso",[["DynamicExpresso.Core","2.19.6"]],[["DynamicExpresso.Core.dll",["DynamicExpresso"]]])
pkgImport("dynamicexpresso","DynamicExpresso.Core.dll","DynamicExpresso")
dnImport("System")

oInterpreter = new Interpreter()
dnAssert("an expression",evalText(oInterpreter,"2 + 3 * 4"),14)
dnAssert("a text expression",evalText(oInterpreter,'"ab".ToUpper() + "c"'),"ABc")

oInterpreter.SetVariable([ :name = "x", :value = 5 ])
oInterpreter.SetVariable([ :name = "name", :value = "Ring" ])
dnAssert("a variable from Ring",evalText(oInterpreter,"x * x"),25)
dnAssert("a text variable",evalText(oInterpreter,"name.Length"),4)
dnAssert("a condition",evalText(oInterpreter,'x > 3 ? "big" : "small"'),"big")

# a type is made known by name
oInterpreter.Reference(dnType("System.Math"))
dnAssert("a type of the framework",evalText(oInterpreter,"Math.Max(x, 9)"),9)
dnAssert("a static method",evalText(oInterpreter,"Math.Pow(2, 10)"),1024)

# the result type: the generic Eval<T>
dnAssert("a typed result",oInterpreter.callGeneric("Eval",["System.Int32"],["x + 1"]),6)

# an expression that is parsed once and called with parameters (Ring numbers are doubles: the parameters are doubles)
oFn = oInterpreter.Parse([ :expressionText = "a * b + 1", :parameters = [ dnNew("DynamicExpresso.Parameter",["a",dnType("System.Double")]), dnNew("DynamicExpresso.Parameter",["b",dnType("System.Double")]) ] ])
dnAssert("a parsed expression",oFn.Invoke([6,7]),43)
dnAssert("a parsed expression again",oFn.Invoke([2,3]),7)

# an error in the expression
try
	evalText(oInterpreter,"x +")
	dnAssert("a bad expression is an error",1,0)
catch
	dnAssert("a bad expression is an error",substr(cCatchError,"ParseException") > 0,1)
done
try
	evalText(oInterpreter,"unknownName + 1")
	dnAssert("an unknown name is an error",1,0)
catch
	dnAssert("an unknown name is an error",substr(cCatchError,"UnknownIdentifier") > 0 or substr(cCatchError,"unknownName") > 0,1)
done

dnTestSummary()

func evalText oInterpreter, cText
	return oInterpreter.Eval([ :expressionText = cText, :parameters = [] ])
