# Mono.Cecil: reads the metadata of an assembly file (UserLib.dll of the tests): modules, types, methods, parameters, attributes as nested collections
load "pkg.ring"
pkgUse("cecil",[["Mono.Cecil","0.11.6"]],[["Mono.Cecil.dll",["Mono.Cecil"]]])
pkgImport("cecil","Mono.Cecil.dll","Mono.Cecil")

cLib = cPkgHere + "/../UserLib/bin/UserLib.dll"
oAssembly = dnStatic("Mono.Cecil.AssemblyDefinition","ReadAssembly",[cLib])
dnAssert("the name of the assembly",oAssembly.Name.Name,"UserLib")
dnAssert("a module",oAssembly.MainModule.Types.Count > 5,1)

oCircle = ""
aTypes = oAssembly.MainModule.Types.toList()
for oType in aTypes
	if oType.Name = "Circle"
		oCircle = oType
	ok
next
dnAssert("a type by name",oCircle.FullName,"MyCompany.Tools.Circle")
dnAssert("it is a class",oCircle.IsClass,1)
dnAssert("it is public",oCircle.IsPublic,1)
dnAssert("it implements an interface",oCircle.Interfaces.Count,1)
dnAssert("the name of the interface",oCircle.Interfaces.toList()[1].InterfaceType.Name,"IShape")

aNames = []
aTypes = oAssembly.MainModule.Types.toList()
for oType in aTypes
	aNames + oType.Name
next
dnAssert("an interface of the library is a type",find(aNames,"IShape") > 0,1)
dnAssert("a delegate of the library is a type",find(aNames,"Transform") > 0,1)

# the methods of a static class and their parameters
aTypes = oAssembly.MainModule.Types.toList()
for oType in aTypes
	if oType.Name = "ParamsTools"
		aMethods = oType.Methods.toList()
		for oMethod in aMethods
			if oMethod.Name = "CountShapes"
				dnAssert("a method of a type",oMethod.IsStatic,1)
				dnAssert("its parameters",oMethod.Parameters.Count,2)
				dnAssert("the name of a parameter",oMethod.Parameters.toList()[1].Name,"label")
				dnAssert("the type of a parameter",oMethod.Parameters.toList()[2].ParameterType.Name,"IShape[]")
				dnAssert("its return type",oMethod.ReturnType.Name,"Int32")
			ok
		next
	ok
next

oAssembly.Dispose()
dnTestSummary()
