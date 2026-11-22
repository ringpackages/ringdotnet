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

# an IAsyncEnumerable result: toList() reads it all, asyncNext() one item at a time
oStream = dnStatic("MyCompany.Tools.Spans","CountAsync",[4])
aItems = oStream.toList()
dnAssert("IAsyncEnumerable, toList",len(aItems),4)
dnAssert("IAsyncEnumerable, the last item",aItems[4],40)
oEnum = dnStatic("MyCompany.Tools.Spans","CountAsync",[3]).asyncEnumerator()
nSum = 0
nSteps = 0
while oEnum.asyncNext()
	nSum += oEnum.Current
	nSteps++
end
oEnum.asyncDispose()
dnAssert("IAsyncEnumerable, one item at a time",nSteps,3)
dnAssert("IAsyncEnumerable, the items",nSum,60)

# properties of a Span, a ref struct and a ref type
oHolder = new Holder()
dnAssert("a ReadOnlySpan<byte> property",len(oHolder.View),3)
dnAssert("a ReadOnlySpan<char> property is a text",oHolder.Name,"abc")
dnAssert("a ref struct property with a text method",oHolder.Tag,"[tag]")
dnAssert("a ref property is its value",oHolder.Slot,7)
oMemory = dnStatic("System.MemoryExtensions","AsMemory",["hello"])
dnAssert("the Span of a Memory",oMemory.Span,"hello")

# methods that return by reference: the value
oSlots = new Slots()
dnAssert("a ref int return is the number",oSlots.Number(1),6)
dnAssert("a ref string return is the text",oSlots.Text(1),"y")
dnAssert("a ref readonly struct return is the object",oSlots.Day().Year,2024)

# a ref struct that only holds values: its properties as [name, value] pairs, and it is disposed
aLease = dnStatic("MyCompany.Tools.Spans","Take",[])
dnAssert("a ref struct answered as its properties",aLease["Length"],3)
dnAssert("a property that is a text",aLease["Name"],"lease")
dnAssert("a property that is a ReadOnlySpan<byte>",ascii(aLease["Data"][1]),9)
dnAssert("the struct was disposed after it was read",dnType("MyCompany.Tools.Spans").getProp("Disposed"),1)

# a ref return of a method that has a Span parameter
aElement = dnStatic("MyCompany.Tools.Spans","ElementAt",[ [4,5,6], 1 ])
dnAssert("a ref return through a Span parameter",aElement[1],5)

# constructors with a Span or a ref struct; a ref struct that has only a static factory (FromString)
oMessage = dnNew("MyCompany.Tools.Message",["hello",3])
dnAssert("a constructor with a ReadOnlySpan<char>",oMessage.Text,"hello")
dnAssert("a constructor with a ReadOnlySpan<char>, the other parameter",oMessage.Copies,3)
dnAssert("a ref struct made by a static factory",dnStatic("MyCompany.Tools.Spans","TokenSize",["four"]),4)
dnAssert("a constructor with a ref struct",dnNew("MyCompany.Tools.Message",[ :token = "abcde" ]).Copies,5)

dnTestSummary()
