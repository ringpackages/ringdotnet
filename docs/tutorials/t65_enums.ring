# enums and flags - named choices from .NET as text, checking and parsing them, and combining options with bits
load "dotnet.ring"
using {
	"System"
	"System.IO"
}

C_READ = 1                 # the options of the permission bits in step 5
C_WRITE = 2
C_RUN = 4

func main
	oEnum = new Enum()
	oDays = dnType("System.DayOfWeek")

	# 1. An enum is a fixed list of names. In Ring an enum value is a TEXT with the name: there is no number to remember.
	oDate = new DateTime(2024,5,17)
	? "1. 2024-05-17 is a " + oDate.DayOfWeek + ". Is it a Friday? " + yesNo(oDate.DayOfWeek = "Friday")

	# 2. All the names of an enum
	? nl + "2. the days: " + joinWith(oEnum.GetNames(oDays).toList(),", ")

	# 3. Is a text one of the names? Parse turns a text into an enum value, and raises an error if there is no such name.
	? nl + "3. is 'Friday' a day? " + yesNo(oEnum.IsDefined([ :enumType = oDays, :value = "Friday" ])) + ". Is 'Funday'? " + yesNo(oEnum.IsDefined([ :enumType = oDays, :value = "Funday" ]))
	cDay = oEnum.Parse([ :enumType = oDays, :value = "Friday" ])
	? "   Parse('Friday') gives " + cDay
	try
		oEnum.Parse([ :enumType = oDays, :value = "Funday" ])
	catch
		? "   Parse('Funday') raised: " + substr(left(cCatchError,70),nl," ")
	done

	# 4. A method that takes an enum takes the name as a text: a file can be hidden and read only at the same time
	cFile = new Path().Combine([new Path().GetTempPath(),"tutorial65.txt"])
	new File().WriteAllText([ :path = cFile, :contents = "x" ])
	? nl + "4. attributes of a new file: " + new File().GetAttributes(cFile)
	new File().SetAttributes(cFile,"ReadOnly, Hidden")                       # several flags: names separated by commas
	cAttributes = new File().GetAttributes(cFile)
	? "   after SetAttributes: " + cAttributes
	? "   is it hidden? " + yesNo(substr(cAttributes,"Hidden") > 0) + ", is it a directory? " + yesNo(substr(cAttributes,"Directory") > 0)
	new File().SetAttributes(cFile,"Normal")
	new File().Delete(cFile)

	# 5. Your own flags: each option is a power of two, so that every combination is one number. The operators are & | ~
	? nl + "5. options as bits:"
	nPermissions = C_READ | C_WRITE                                          # read and write
	? "   permissions = " + nPermissions + " -> " + describe(nPermissions)
	nPermissions = nPermissions | C_RUN                                      # add an option
	? "   after adding run: " + nPermissions + " -> " + describe(nPermissions)
	nPermissions = nPermissions & ~C_WRITE                                   # remove an option
	? "   after removing write: " + nPermissions + " -> " + describe(nPermissions)
	? "   can it read? " + yesNo((nPermissions & C_READ) != 0) + ", can it write? " + yesNo((nPermissions & C_WRITE) != 0)

func describe nPermissions
	aNames = []
	if (nPermissions & C_READ) != 0
		aNames + "read"
	ok
	if (nPermissions & C_WRITE) != 0
		aNames + "write"
	ok
	if (nPermissions & C_RUN) != 0
		aNames + "run"
	ok
	if len(aNames) = 0
		return "nothing"
	ok
	return joinWith(aNames," + ")

func joinWith aList, cSeparator
	cText = ""
	for cItem in aList
		if cText != ""
			cText += cSeparator
		ok
		cText += cItem
	next
	return cText

func yesNo lValue
	if lValue
		return "yes"
	ok
	return "no"
