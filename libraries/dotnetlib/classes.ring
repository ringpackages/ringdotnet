/*
	DotNetLib - Classes
*/

# A reference to a .NET object (or to a .NET type when it came from dnType())
class DotNetObject

	nHandle = 0

	func init  nHandle
		this.nHandle = nHandle

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
			dnRequest("release",[nHandle])
			nHandle = 0
		ok

# A Ring function that .NET code can call (pass it where a .NET delegate is expected).
# The function receives ONE parameter: the list of the delegate arguments, and returns the result.
class DotNetCallback

	cFunction = ""

	func init  cFunction
		this.cFunction = cFunction
