# Foundation: dnImport, generated classes, properties, out/ref parameters, enums, generics, callbacks, events
load "dotnetlib.ring"

dnImport("System")
dnImport("System.Text")
dnImport("System.Collections.Generic")
dnImport("System.Collections.ObjectModel")

# dnImport twice is harmless; unknown namespaces are errors
dnImport("System.Text")
try
	dnImport("No.Such.Namespace")
	dnAssert("unknown namespace raises",1,0)
catch
	dnAssert("unknown namespace raises",1,1)
done

# Classes of a namespace generated with :all (System.Text)
oUtf8 = new Encoding().UTF8
dnAssert("Encoding.UTF8 name",oUtf8.WebName,"utf-8")
dnAssert("GetBytes length",len(oUtf8.GetBytes("abc")),3)
oSB = new StringBuilder("ab")
oSB.Append("cd").Append("e")
dnAssert("StringBuilder chain",oSB.ToString(),"abcde")
oSB.Length = 2
dnAssert("property write",oSB.ToString(),"ab")

# Methods return the generated class when it is imported
oDate = new DateTime(2024,2,29)
dnAssert("DateTime.Year",oDate.Year,2024)
dnAssert("AddDays wraps DateTime",oDate.AddDays(1).Day,1)

# Enums are strings
dnAssert("enum as string",oDate.DayOfWeek,"Thursday")
dnAssert("enum name list",len(dnRequest("enumnames",["System.DayOfWeek"])),7)

# out / ref parameters: the method returns a list [result, out values...]
oDict = new StringDictionary()
oDict.Add("k","v")
aFound = oDict.TryGetValue("k")
dnAssert("TryGetValue found",aFound[1],1)
dnAssert("TryGetValue value",aFound[2],"v")
aMissing = oDict.TryGetValue("nope")
dnAssert("TryGetValue missing",aMissing[1],0)
aParsed = dnType("System.Int32").callMethod("TryParse",["42"])
dnAssert("Int32.TryParse ok",aParsed[1],1)
dnAssert("Int32.TryParse value",aParsed[2],42)

# Generic types without a generated class
oList = dnNewGeneric("System.Collections.Generic.List",["System.Int32"],[])
oList.callMethod("Add",[5])
oList.callMethod("Add",[7])
dnAssert("generic list count",oList.getProp("Count"),2)
dnAssert("generic name",dnGenericName("A.B",["X","Y"]),"A.B`2[[X],[Y]]")

# Callbacks (any Ring code) and events
oNames = new StringList()
oNames.Add("bb")  oNames.Add("a")  oNames.Add("ccc")
oNames.Sort_1(dnCallback("xDotNetResult = len(aDotNetArgs[1]) - len(aDotNetArgs[2])"))
dnAssert("callback sort",oNames.Item(0),"a")
nEvents = 0
oObs = new ObservableStringList()
oObs.setCollectionChangedEvent("nEvents++")
oObs.Add("x")  oObs.Add("y")
dnAssert("events",nEvents,2)

# The library must not change user globals that have common names
cData = "mine"  aItems = [1,2]  nPos = 5  x = 9  xResult = "keep"
new StringBuilder("q").Append("r").ToString()
dnAssert("user globals untouched",cData + aItems[2] + nPos + x + xResult,"mine259keep")

nFail = dnTestSummary()
