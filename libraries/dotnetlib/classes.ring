/*
	DotNetLib - Classes

	A .NET object stays in .NET. Ring holds a number (a handle) in a DotNetObject, and the managed bridge keeps the object in a table.
	The generated classes (generated/) derive from DotNetObject and add the methods and properties of the .NET class.
*/

# A reference to a .NET object (or to a .NET type when it came from dnType())
class DotNetObject

	nHandle = 0
	oDotNetGuard = ""          # a managed pointer: when the last copy of the object is gone, the handle is released (see dotnet_guard)

	# (the parameter has another name: "this.nHandle = ..." would run Ring's property setter machinery,
	# which breaks an outer assignment like oForm.Text = new Path().GetFileName(...))
	func init  pHandle
		nHandle = pHandle

	# The default object of a class (used by the class body of the generated classes, for "new X" without parentheses)
	func dnDefaultObject  cTypeName
		nHandle = dnCreate(cTypeName,[])
		oDotNetGuard = dotnet_guard(nHandle)

	# True for the null reference
	func isNull
		return nHandle = 0

	# Call a method by its name: oObject.callMethod("Append", ["text"]). It works for every .NET object, also when no class was generated.
	func callMethod  cMethod, aParameters
		if not islist(aParameters)
			aParameters = []
		ok
		return dnRequest("call",dnJoin([self,cMethod],aParameters))

	# Call a generic method whose type argument only its result shows (JsonConvert.DeserializeObject<T>(json)): the type arguments are a list of
	# type names, then the arguments: oType.callGeneric("DeserializeObject",["System.Collections.Generic.List`1[[System.String]]"],[cJson])
	func callGeneric  cMethod, aTypeArguments, aParameters
		if not islist(aParameters)
			aParameters = []
		ok
		return dnRequest("callgeneric",dnJoin([self,cMethod,aTypeArguments],aParameters))

	# The conversion of the object to a .NET type with the operators op_Implicit / op_Explicit (the cast of C#): oToken.convertTo("System.String")
	func convertTo  cType
		return dnRequest("convert",[self,cType])

	# Read a property or a field
	func getProp  cMember
		return dnRequest("get",[self,cMember])

	# Write a property or a field
	func setProp  cMember, xValue
		dnRequest("set",[self,cMember,xValue])
		return self

	# ToString() of the object
	func toString
		return dnRequest("tostring",[self])

	# Full name of the .NET type
	func typeName
		return dnRequest("typename",[self])

	# Copy the items of an array or collection to a Ring list
	func toList
		return dnRequest("tolist",[self])

	# An IAsyncEnumerable (a method that returns one has no await foreach in Ring): toList() reads all the items. One item at a time:
	#   oEnum = oStream.asyncEnumerator()    while oEnum.asyncNext()  ? oEnum.Current  end    oEnum.asyncDispose()
	func asyncEnumerator
		return dnRequest("asyncenumerator",[self])

	# Wait for the next item of an async enumerator: true when there is one (it is Current), false at the end
	func asyncNext
		return dnRequest("asyncnext",[self]) = 1

	# End an async enumerator (toList does it by itself)
	func asyncDispose
		dnRequest("asyncdispose",[self])
		return self

	# Release the reference kept by the bridge now (the object is not used after this). Ring releases it by itself when the last
	# variable that holds the object is gone (see oDotNetGuard); this is only needed to let go of a big object at once.
	func release
		if nHandle != 0
			dotnet_unguard(oDotNetGuard)
			dnRequest("release",[nHandle])
			nHandle = 0
		ok

# An object that came from .NET and has no generated class: it owns its handle (a plain DotNetObject, as in new DotNetObject(nHandle),
# is a reference that does not own it). The guard is made inside init: Ring does not free a guard that is assigned from outside the object.
class DotNetOwned from DotNetObject

	func init  pHandle
		nHandle = pHandle
		if pHandle != 0
			oDotNetGuard = dotnet_guard(pHandle)
		ok

# Ring code that .NET can run (pass it where a .NET delegate is expected).
# cCode is Ring code (as in RingQt events) that can read aDotNetArgs (the delegate arguments)
# and set xDotNetResult, or just the name of a function that receives the argument list and returns the result.
class DotNetCallback

	cCode = ""

	func init  pCode
		cCode = pCode
