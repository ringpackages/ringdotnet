# identifiers and versions - Guid, Version, and sorting version numbers by number and not as text
load "dotnet.ring"

using {
	"System"
	"System.Collections.Generic"
}

func main

	oGuid = new Guid()

	# 1. A Guid is a 128-bit number that is unique for practical purposes: two programs on two computers can make one each and
	#    never meet the same value. It is shown as 32 hex digits in 5 groups. NewGuid is random: only its shape is the same.
	cNew = oGuid.NewGuid().ToString()
	? "1. a new Guid has " + len(cNew) + " characters, with dashes at 9, 14, 19 and 24: " + (cNew[9] = "-" and cNew[14] = "-" and cNew[19] = "-" and cNew[24] = "-")
	? "   two new Guids are different: " + (oGuid.NewGuid().ToString() != oGuid.NewGuid().ToString())

	# 2. Parse and compare. A Guid can be read from text in several layouts; Format("N") has no dashes, "B" has braces.
	oFixed = oGuid.Parse("0f8fad5b-d9cb-469f-a165-70867728950e")
	? nl + "2. parsed: " + oFixed.ToString()
	? "   format N: " + oFixed.Format("N")
	? "   format B: " + oFixed.Format("B")
	? "   Empty is all zeros: " + oGuid.Empty.ToString()
	? "   TryParse of 'hello': success = " + oGuid.TryParse("hello")[1]

	# 3. Version: major.minor.build.revision, compared by NUMBER. As text, "1.10" comes before "1.9"; as Version it is later.
	oVer = dnNew("Version",[ :major = 0, :minor = 0 ])      # any Version works as a handle for the static methods
	oV9 = oVer.Parse("1.9.0")
	oV10 = oVer.Parse("1.10.0")
	? nl + "3. as text, '1.10.0' < '1.9.0' is " + (strcmp("1.10.0","1.9.0") < 0)
	? "   as Version, 1.10.0 is later than 1.9.0: " + (oV10.CompareTo(oV9) > 0)
	? "   parts of 1.10.0: major " + oV10.Major + ", minor " + oV10.Minor + ", build " + oV10.Build

	# 4. Sorting versions: a sorted list of Version objects. Sort() uses CompareTo of every Version.
	oList = dnNewGeneric("System.Collections.Generic.List",["System.Version"],[])
	for cText in ["2.0.1","1.10.0","1.2.0","1.9.0","10.0.0"]
		oList.callMethod("Add",[oVer.Parse(cText)])
	next
	oList.callMethod("Sort",[])
	cSorted = ""
	for oItem in oList.toList()
		cSorted += oItem.ToString() + " "
	next
	? nl + "4. sorted versions: " + cSorted

	# 5. The version of the running .NET and of an assembly
	? nl + "5. the runtime version is 6 or later: " + (new Environment().Version.Major >= 6)
