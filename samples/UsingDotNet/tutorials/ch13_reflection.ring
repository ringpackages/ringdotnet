# exploring .NET from Ring - ask a class what it can do
load "dotnet.ring"
using {
	"System"
	"System.Text"
	"System.Reflection"
}

func main
	# Reflection means: a program looks at its own types. Start from a type name.
	oType = new Type().GetType([ :typeName = "System.Text.StringBuilder" ])
	? "Type          : " + oType.FullName
	? "Is a class    : " + oType.IsClass
	? "Base type     : " + oType.BaseType.FullName
	? "Assembly      : " + oType.Assembly.GetName(NULL).Name

	# Its public properties
	? nl + "Properties:"
	for oProperty in oType.GetProperties(NULL).toList()
		? "  " + oProperty.Name + " : " + oProperty.PropertyType.Name + iif(oProperty.CanWrite," (read/write)"," (read only)")
	next

	# Its methods: many names appear several times (overloads), so list each name once
	aNames = []
	for oMethod in oType.GetMethods(NULL).toList()
		if find(aNames,oMethod.Name) = 0
			aNames + oMethod.Name
		ok
	next
	aNames = sort(aNames)
	? nl + "The class has " + len(aNames) + " method names, for example:"
	for nIndex = 1 to 8
		? "  " + aNames[nIndex]
	next

	# The overloads of one method, with their parameters
	aVersions = []
	for oMethod in oType.GetMethods(NULL).toList()
		if oMethod.Name = "Append"
			aParameters = oMethod.GetParameters().toList()
			if len(aParameters) = 1
				aVersions + ("Append(" + aParameters[1].ParameterType.Name + " " + aParameters[1].Name + ")")
			ok
		ok
	next
	? nl + "Append has " + len(aVersions) + " versions with 1 parameter, the first ones are:"
	for nIndex = 1 to 4
		? "  " + aVersions[nIndex]
	next

	# An object knows its own type
	oSB = new StringBuilder("hi")
	? nl + "An object knows its type: " + oSB.GetType().Name

	# An enum: its names are the texts that Ring uses
	oDays = new Type().GetType([ :typeName = "System.DayOfWeek" ])
	? "Values of DayOfWeek: " + joinList(new Enum().GetNames(oDays).toList())

	# Your own tools: dnDescribe returns the public API of a type as lists
	aApi = dnDescribe("System.Math")
	? nl + "dnDescribe('System.Math') returned a list with " + len(aApi) + " parts"

func iif lCondition, xYes, xNo
	if lCondition
		return xYes
	ok
	return xNo

func joinList aList
	cText = ""
	for xItem in aList
		if cText != ""
			cText += ", "
		ok
		cText += xItem
	next
	return cText
