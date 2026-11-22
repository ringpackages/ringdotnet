# Roslyn (Microsoft.CodeAnalysis.CSharp): parse C# text into a syntax tree, walk the nodes (enums, extension methods, immutable collections), compile in memory, load the assembly and call it
load "pkg.ring"
pkgUse("roslyn",[["Microsoft.CodeAnalysis.CSharp","4.14.0"]],[["Microsoft.CodeAnalysis.dll",["Microsoft.CodeAnalysis","Microsoft.CodeAnalysis.Emit"]],["Microsoft.CodeAnalysis.CSharp.dll",["Microsoft.CodeAnalysis.CSharp","Microsoft.CodeAnalysis.CSharp.Syntax"]]])
pkgImport("roslyn","Microsoft.CodeAnalysis.dll","Microsoft.CodeAnalysis")
pkgImport("roslyn","Microsoft.CodeAnalysis.dll","Microsoft.CodeAnalysis.Emit")
pkgImport("roslyn","Microsoft.CodeAnalysis.CSharp.dll","Microsoft.CodeAnalysis.CSharp")
pkgImport("roslyn","Microsoft.CodeAnalysis.CSharp.dll","Microsoft.CodeAnalysis.CSharp.Syntax")
dnImport("System")
dnImport("System.IO")

cCode = "namespace Demo { public class Calc { public int Add(int a, int b) { return a + b; } public static int Twice(int x) { return Add2(x) * 2; } static int Add2(int x) { return x + 2; } } }"

# parse: a syntax tree with a root node
oTree = dnStatic("Microsoft.CodeAnalysis.CSharp.CSharpSyntaxTree","ParseText",[cCode])
oRoot = oTree.GetRoot(NULL)
dnAssert("the kind of the root",dnStatic("Microsoft.CodeAnalysis.CSharp.CSharpExtensions","Kind",[oRoot]),"CompilationUnit")
dnAssert("the tree has no errors",len(oTree.GetDiagnostics(NULL).toList()),0)
dnAssert("the text of the tree",oTree.ToString(),cCode)

# walk the nodes: the methods of the class
aMethods = []
for oNode in oRoot.DescendantNodes(NULL).toList()
	if dnStatic("Microsoft.CodeAnalysis.CSharp.CSharpExtensions","Kind",[oNode]) = "MethodDeclaration"
		add(aMethods,oNode.Identifier.Text)
	ok
next
dnAssert("three methods",len(aMethods),3)
dnAssert("their names",aMethods[1] + "," + aMethods[2] + "," + aMethods[3],"Add,Twice,Add2")

# a syntax error is reported with a message and a position
oBad = dnStatic("Microsoft.CodeAnalysis.CSharp.CSharpSyntaxTree","ParseText",["class A { void M( { } }"])
aErrors = oBad.GetDiagnostics(NULL).toList()
dnAssert("a broken text has errors",len(aErrors) > 0,1)
dnAssert("an error has an id",left(aErrors[1].Id,2),"CS")

# compile in memory: references are the runtime assemblies
cRuntime = dnStatic("System.Runtime.InteropServices.RuntimeEnvironment","GetRuntimeDirectory",[])
oRefA = dnStatic("Microsoft.CodeAnalysis.MetadataReference","CreateFromFile",[cRuntime + "System.Private.CoreLib.dll"])
oRefB = dnStatic("Microsoft.CodeAnalysis.MetadataReference","CreateFromFile",[cRuntime + "System.Runtime.dll"])
oOptions = dnNew("Microsoft.CodeAnalysis.CSharp.CSharpCompilationOptions",[ dnStatic("Microsoft.CodeAnalysis.OutputKind","DynamicallyLinkedLibrary",[]) ])
oCompilation = dnStatic("Microsoft.CodeAnalysis.CSharp.CSharpCompilation","Create",["DemoAssembly",[oTree],[oRefA,oRefB],oOptions])
oStream = new MemoryStream()
oEmit = oCompilation.Emit(oStream)
dnAssert("the code compiles",oEmit.Success,1)
dnAssert("the assembly has bytes",oStream.Length > 500,1)

# load the assembly and call the method
oStream.Position = 0
oAssembly = dnStatic("System.Reflection.Assembly","Load",[oStream.ToArray()])
oType = oAssembly.GetType("Demo.Calc")
dnAssert("the type is in the assembly",oType.Name,"Calc")
dnAssert("a static method of the compiled code, called by reflection (the int parameter gets the number of Ring)",oType.callMethod("GetMethod",["Twice"]).callMethod("Invoke",[dnNull(),[5]]),14)

# the compilation of broken code fails with diagnostics
oBrokenTree = dnStatic("Microsoft.CodeAnalysis.CSharp.CSharpSyntaxTree","ParseText",["class B { int M() { return undefinedName; } }"])
oBrokenCompilation = dnStatic("Microsoft.CodeAnalysis.CSharp.CSharpCompilation","Create",["Broken",[oBrokenTree],[oRefA,oRefB],oOptions])
oBrokenEmit = oBrokenCompilation.Emit(new MemoryStream())
dnAssert("code with an unknown name does not compile",oBrokenEmit.Success,0)
dnAssert("and the diagnostic says what is wrong",substr(oBrokenEmit.Diagnostics.toList()[1].GetMessage(NULL),"undefinedName") > 0,1)

dnTestSummary()
