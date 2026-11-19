/*
	DotNetLib - Classes
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

	# Call a method: oObject.callMethod("Append", ["text"])
	func callMethod  cMethod, aParameters
		if not islist(aParameters)
			aParameters = []
		ok
		return dnRequest("call",dnJoin([self,cMethod],aParameters))

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

	# Release the reference kept by the bridge (the object can't be used after this)
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
