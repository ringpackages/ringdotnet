# the Windows Registry - keys and values in HKEY_CURRENT_USER, value types, listing, a settings class, and deleting what you made
# (Windows only: anywhere else the program says so and stops)
load "dotnet.ring"
using {
	"System"
	"Microsoft.Win32"
}

C_PATH = "Software\RingDotNetTutorial118"

func main
	if not iswindows()
		? "The Registry exists only on Windows."
		return
	ok

	# The Registry is a tree of KEYS (like folders) that hold VALUES (a name and data with a type). Windows and many programs keep their
	# settings in it. The part HKEY_CURRENT_USER (HKCU) belongs to the user who is logged in and needs no special rights; the part
	# HKEY_LOCAL_MACHINE is for all users and needs an administrator for writing. This lesson writes only in its own key under HKCU
	# and deletes it at the end.
	oUser = dnType("Microsoft.Win32.Registry").getProp("CurrentUser")
	oUser.callMethod("DeleteSubKeyTree",[C_PATH,False])           # a key from an earlier run goes away (False: no error when it is missing)

	# 1. CreateSubKey makes a key (or opens it when it exists) and gives it ready for writing
	oKey = oUser.CreateSubKey(C_PATH)
	? "1. the key HKEY_CURRENT_USER\" + C_PATH + " was made: " + (not oKey.isNull())

	# 2. SetValue(name, data, kind). The kind says how Windows stores the data: String, DWord (a 32-bit number), QWord (64 bits),
	#    MultiString (a list of texts), ExpandString (a text with %NAME% variables that Windows replaces) and Binary (bytes).
	oKey.callMethod("SetValue",["UserName","Ann","String"])
	oKey.callMethod("SetValue",["WindowWidth",1280,"DWord"])
	oKey.callMethod("SetValue",["LastFiles",stringArray(["a.txt","b.txt","c.txt"]),"MultiString"])          # MultiString needs a string[]: a List<string> and ToArray()
	oKey.callMethod("SetValue",["DataFolder","%USERPROFILE%\Data","ExpandString"])
	oKey.callMethod("SetValue",["BigNumber",5000000000,"QWord"])          # a number above 2147483647 needs 64 bits
	# Binary needs a real byte[] object. A Ring text would be written as a String, so the bytes are put into a byte buffer (dnBuffer) first:
	# the buffer is a .NET object that holds a byte[], and a parameter of type object receives that array.
	oKey.callMethod("SetValue",["Signature",dnBuffer(char(1) + char(2) + char(0) + char(254) + char(255)),"Binary"])
	? nl + "2. values written: " + oKey.ValueCount

	# 3. Reading: GetValue(name, default) gives the data in the form that fits its kind, or the default when the name is missing
	? nl + "3. UserName    = " + oKey.callMethod("GetValue",["UserName","(none)"])
	? "   WindowWidth = " + oKey.callMethod("GetValue",["WindowWidth",800]) + "   (a number, so " + (oKey.callMethod("GetValue",["WindowWidth",800]) + 20) + " after + 20)"
	? "   Missing     = " + oKey.callMethod("GetValue",["Missing","(default)"])
	? "   LastFiles   = " + listText(oKey.GetValue("LastFiles").toList())
	cFolder = oKey.GetValue("DataFolder")
	? "   DataFolder  = ends with \Data: " + (right(cFolder,5) = "\Data") + ", still has a % sign: " + (substr(cFolder,"%") > 0) + "   (Windows replaced %USERPROFILE%; the path is not printed because it holds your user name)"
	? "   BigNumber   = " + oKey.GetValue("BigNumber") + "   (a 64-bit number)"
	cSignature = oKey.GetValue("Signature")                 # a byte[] comes back as a Ring text of bytes
	? "   Signature   = " + len(cSignature) + " bytes, in hexadecimal " + new Convert().ToHexString(cSignature) + "   (Binary)"

	# 4. The kind of a value, and a list of all values. GetValueKind tells how it is stored.
	? nl + "4. all the values with their kinds:"
	aNames = sort(oKey.GetValueNames().toList())
	for cName in aNames
		? "   " + padRight(cName,12) + oKey.GetValueKind(cName)
	next

	# 5. Sub-keys: a key can hold other keys, like folders. GetSubKeyNames lists them.
	oChild = oKey.CreateSubKey("Window1")
	oChild.callMethod("SetValue",["Left",100,"DWord"])
	oChild.callMethod("SetValue",["Top",50,"DWord"])
	oChild.Close()
	oKey.CreateSubKey("Window2").Close()
	? nl + "5. sub-keys: " + listText(sort(oKey.GetSubKeyNames().toList()))
	oRead = oKey.OpenSubKey("Window1")
	? "   Window1 has Left = " + oRead.GetValue("Left") + ", Top = " + oRead.GetValue("Top")
	oRead.Close()

	# 6. Delete one value, and the whole tree at the end. Always clean up what a test or a sample wrote.
	oKey.DeleteValue("BigNumber")
	? nl + "6. after DeleteValue(BigNumber): " + oKey.ValueCount + " values"
	oKey.Close()
	oUser.DeleteSubKeyTree(C_PATH)
	? "   the key was deleted: " + oUser.OpenSubKey(C_PATH).isNull()

func listText aList
	cText = ""
	for item in aList
		if cText != ""
			cText += ", "
		ok
		cText += "" + item
	next
	return cText

func padRight cText,nWidth
	return cText + copy(" ",nWidth - len(cText))

# a string[] from a Ring list (the registry wants the exact type)
func stringArray aList
	oList = dnNewGeneric("System.Collections.Generic.List",["System.String"],[])
	for cItem in aList
		oList.Add(cItem)
	next
	return oList.ToArray()
