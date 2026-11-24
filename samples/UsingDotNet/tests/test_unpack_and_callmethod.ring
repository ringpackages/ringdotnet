# The answers that are lists are read in C (dotnet_unpack, dotnet_unpacklist); callMethod and dnStatic build their request without a list
# and a copy of the object. Anything that C does not read (objects, null, errors) goes the Ring way: the results must be the same.
load "dotnet.ring"

using {
	"System"
	"System.Collections"
	"System.Collections.Generic"
	"System.Text"
}

func main

	# a list of texts, with a text that has a NUL, bytes that are not UTF-8, and the empty text
	oList = new StringList()
	cOdd = "a" + char(0) + "b" + char(195) + char(169)
	oList.Add("one")
	oList.Add("")
	oList.Add(cOdd)
	aItems = oList.toList()
	dnAssert("toList: the number of texts",len(aItems),3)
	dnAssert("toList: a text",aItems[1],"one")
	dnAssert("toList: the empty text",aItems[2],"")
	dnAssert("toList: a binary text",aItems[3],cOdd)

	# a big list, read in C
	oBig = new StringList()
	for i = 1 to 500  oBig.Add("item " + i)  next
	aBig = oBig.toList()
	dnAssert("toList: 500 texts",len(aBig),500)
	dnAssert("toList: the last text",aBig[500],"item 500")

	# a list of numbers, a list of yes/no and a list of lists
	oNumbers = new ArrayList()
	oNumbers.Add(5)
	oNumbers.Add(-7)
	oNumbers.Add(2000000000)
	aNumbers = oNumbers.toList()
	dnAssert("toList: whole numbers",aNumbers[1] + aNumbers[2] + aNumbers[3],2000000000 - 2)
	oDoubles = new ArrayList()
	oDoubles.Add(1.25)
	oDoubles.Add(0.1)
	aDoubles = oDoubles.toList()
	dnAssert("toList: numbers with a fraction",aDoubles[1],1.25)
	dnAssert("toList: 0.1 keeps its value",aDoubles[2] = 0.1,True)
	oFlags = new ArrayList()
	oFlags.Add(True)
	oFlags.Add(False)
	aFlags = oFlags.toList()
	dnAssert("toList: yes",aFlags[1],True)
	dnAssert("toList: no",aFlags[2],False)

	# an answer that has objects in it is read by the Ring loop
	oObjects = new ObjectList()
	oObjects.Add(new StringBuilder("sb"))
	oObjects.Add("text")
	aObjects = oObjects.toList()
	dnAssert("toList: an object and a text, the number of items",len(aObjects),2)
	dnAssert("toList: the object is wrapped",aObjects[1].ToString(),"sb")
	dnAssert("toList: the text",aObjects[2],"text")

	# an empty collection
	dnAssert("toList: nothing",len(new StringList().toList()),0)

	# callMethod: a name that every object has, several arguments, an object as an argument, the answer an object, the null object
	oSB = new StringBuilder("ab")
	oSB.callMethod("Append",["cd"])
	dnAssert("callMethod: a method that changes the object",oSB.ToString(),"abcd")
	dnAssert("callMethod: several arguments",oSB.callMethod("Insert",[0,"X"]).ToString(),"Xabcd")
	oRnd = new Random(42)
	n = oRnd.callMethod("Next",[5,6])
	dnAssert("callMethod: two numbers",n,5)
	oOther = new StringList()
	oOther.Add("q")
	oTarget = new StringList()
	oTarget.callMethod("AddRange",[oOther])
	dnAssert("callMethod: an object as an argument",oTarget.Count,1)
	dnAssert("callMethod: no parameters",oTarget.callMethod("Contains",["q"]),True)
	oNull = dnNull()
	bFailed = False
	try
		oNull.callMethod("ToString",[])
	catch
		bFailed = True
	done
	dnAssert("callMethod: the null object raises an error",bFailed,True)

	# dnStatic: a static method with numbers, with a text, and with a type that was not used before
	dnAssert("dnStatic: Math.Max",dnStatic("System.Math","Max",[3,9]),9)
	dnAssert("dnStatic: a text",dnStatic("System.IO.Path","GetFileName",["c:/work/report.txt"]),"report.txt")
	dnAssert("dnStatic: the same type again",dnStatic("System.IO.Path","GetExtension",["a.txt"]),".txt")
	dnAssert("dnStatic: base 16",dnStatic("System.Convert","ToString",[255,16]),"ff")
	bFailed = False
	try
		dnStatic("System.Math","NoSuchMethod",[1])
	catch
		bFailed = True
	done
	dnAssert("dnStatic: a missing method raises an error",bFailed,True)

	dnTestSummary()
