# Esprima: a JavaScript parser; the source text becomes a tree of nodes (a Script with statements and declarations) that Ring reads by their properties
load "pkg.ring"
pkgUse("esprima",[["Esprima","3.0.6"]],[["Esprima.dll",["Esprima","Esprima.Ast"]]])
pkgImport("esprima","Esprima.dll","Esprima")
pkgImport("esprima","Esprima.dll","Esprima.Ast")

oParser = new JavaScriptParser()
oScript = oParser.ParseScript("var answer = 6 * 7; function add(a, b) { return a + b; }")
dnAssert("a script was parsed",oScript.typeName(),"Esprima.Ast.Script")
dnAssert("two statements at the top",oScript.Body.Count,2)

oVar = oScript.Body.Item(0)
dnAssert("the first statement is a declaration",oVar.Type,"VariableDeclaration")
oDeclarator = oVar.Declarations.Item(0)
dnAssert("the name of the variable",oDeclarator.Id.Name,"answer")
oInit = oDeclarator.getInit()          # a property named Init is read with getInit(): init is the constructor of a generated class
dnAssert("its value is an expression with an operator",oInit.Type,"BinaryExpression")
dnAssert("the operator",oInit.getOperator(),"Times")
dnAssert("the left operand",oInit.Left.Value,6)
dnAssert("the right operand",oInit.Right.Value,7)

oFunction = oScript.Body.Item(1)
dnAssert("the second statement is a function",oFunction.Type,"FunctionDeclaration")
dnAssert("the name of the function",oFunction.Id.Name,"add")
dnAssert("its parameters",oFunction.Params.Count,2)
dnAssert("the name of the second parameter",oFunction.Params.Item(1).Name,"b")
oReturn = oFunction.Body.Body.Item(0)
dnAssert("the body returns a value",oReturn.Type,"ReturnStatement")
dnAssert("the returned expression",oReturn.Argument.getOperator(),"Plus")

# the place of a node in the source
dnAssert("the function starts at its place",oFunction.Location.Start.Column,20)
dnAssert("on the first line",oFunction.Location.Start.Line,1)

# modern syntax: arrow functions, let and const, template texts, classes
oModern = oParser.ParseScript("const f = (x) => `v${x}`; class A { m() { return 1; } }")
dnAssert("a const declaration",oModern.Body.Item(0).Kind,"Const")
dnAssert("an arrow function",oModern.Body.Item(0).Declarations.Item(0).getInit().Type,"ArrowFunctionExpression")
dnAssert("a class",oModern.Body.Item(1).Type,"ClassDeclaration")
dnAssert("the name of the class",oModern.Body.Item(1).Id.Name,"A")

# a module with an import, and the options of the parser
oModule = oParser.ParseModule("import { a } from 'lib'; export const b = a;")
dnAssert("a module has an import",oModule.Body.Item(0).Type,"ImportDeclaration")
dnAssert("and an export",oModule.Body.Item(1).Type,"ExportNamedDeclaration")

# source that is not valid is an error that tells the place
cError = ""
try
	oParser.ParseScript("var = ;")
catch
	cError = cCatchError
done
dnAssert("a syntax error is raised",substr(cError,"ParseErrorException") + substr(cError,"ParserException") > 0,1)
dnAssert("and tells the line",substr(cError,"Line 1") > 0,1)
dnTestSummary()
