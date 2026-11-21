# Methods with a ref struct: a Span result is an array, a span passed by reference is read and answered, a ref struct of a library is made for the call
load "dotnet.ring"

cHere = currentdir()
cLib = cHere + "/UserLib/bin/UserLib.dll"
if not fexists(cLib)
	system("dotnet build UserLib -c Release -o UserLib/bin -nologo -v q")
ok
cOut = cHere + "/UserLib/generated"
chdir("../../../tools/dotnettools")
system(exefilename() + " wrapassembly.ring " + cLib + " " + cOut + " > nul")
chdir(cHere)
dnLoad(cLib)
dnImportFrom(cOut + "/","MyCompany.Tools")

# a ReadOnlySpan<char> result is a text, a Span<byte> result is a byte string
dnAssert("a ReadOnlySpan<char> result",dnStatic("MyCompany.Tools.Spans","Middle",["abcde"]),"bcd")
cHead = dnStatic("MyCompany.Tools.Spans","Head",["xyz"])
dnAssert("a Span<byte> result",cHead,"xy")

# a span passed by reference: the answer is the result, then the span
aSplit = dnStatic("MyCompany.Tools.Spans","TrySplit",["one,two,three"])
dnAssert("TrySplit, result",aSplit[1],1)
dnAssert("TrySplit, the span that came out",aSplit[2],"two,three")
aSplit = dnStatic("MyCompany.Tools.Spans","TrySplit",["one"])
dnAssert("TrySplit, nothing to split",aSplit[1],0)
dnAssert("TrySplit, an empty span",aSplit[2],"")
aSkip = dnStatic("MyCompany.Tools.Spans","Skip",["abcdef",2])
dnAssert("a span that is read and written",aSkip[1],"cdef")

# a ref struct of the library, made from a text
dnAssert("a ref struct parameter",dnStatic("MyCompany.Tools.Spans","CursorLength",["hello"]),5)
dnAssert("a ref struct passed by reference",dnStatic("MyCompany.Tools.Spans","CountOf",["banana","a"]),3)

# a ref struct that a method returns: an enumerator is a list of its items, a struct with a text method is the text
aWords = dnStatic("MyCompany.Tools.Spans","Words",["  one two  three "])
dnAssert("a ref struct enumerator, the number of items",len(aWords),3)
dnAssert("a ref struct enumerator, an item (a ReadOnlySpan<char> is a text)",aWords[2],"two")
dnAssert("a ref struct with a text method",dnStatic("MyCompany.Tools.Spans","MakeLabel",["total"]),"[total]")
aLines = dnStatic("System.MemoryExtensions","EnumerateLines",["a" + nl + "bb" + nl + "ccc"])
dnAssert("EnumerateLines of the library",len(aLines),3)
dnAssert("EnumerateLines, an item",aLines[3],"ccc")

dnTestSummary()
