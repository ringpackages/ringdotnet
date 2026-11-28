# C5: generic collection classes: an array list, a hash set, a hash dictionary, a sorted set and a priority queue (an interval heap)
load "pkg.ring"
pkgUse("c5",[["C5","3.0.0-rc"]],[["C5.dll",["C5"]]])
pkgImport("c5","C5.dll","C5")

cInt = "System.Int32"
cText = "System.String"

# an array list
oList = dnNewGeneric("C5.ArrayList",[cInt],[])
for nValue in [30,10,20,10]
	oList.callMethod("Add",[nValue])
next
dnAssert("a list has four items",oList.getProp("Count"),4)
dnAssert("the first item",oList.callMethod("get_Item",[0]),30)
dnAssert("a list contains a value",oList.callMethod("Contains",[20]),True)
dnAssert("a list does not contain a value",oList.callMethod("Contains",[99]),False)
dnAssert("the index of a value",oList.callMethod("IndexOf",[20]),2)
oList.callMethod("Sort",[])
dnAssert("a sorted list: the first",oList.callMethod("get_Item",[0]),10)
dnAssert("a sorted list: the last",oList.callMethod("get_Item",[3]),30)
oList.callMethod("Reverse",[])
dnAssert("a reversed list: the first",oList.callMethod("get_Item",[0]),30)
oList.callMethod("RemoveAt",[0])
dnAssert("an item was removed",oList.getProp("Count"),3)

# a hash set: no repeats
oSet = dnNewGeneric("C5.HashSet",[cText],[])
oSet.callMethod("Add",["a"])
oSet.callMethod("Add",["b"])
dnAssert("a new value is added",oSet.callMethod("Add",["c"]),True)
dnAssert("a repeated value is not added",oSet.callMethod("Add",["a"]),False)
dnAssert("a set has three items",oSet.getProp("Count"),3)

# a hash dictionary
oMap = dnNewGeneric("C5.HashDictionary",[cText,cInt],[])
oMap.callMethod("Add",["one",1])
oMap.callMethod("Add",["two",2])
dnAssert("a dictionary has two items",oMap.getProp("Count"),2)
dnAssert("a value by key",oMap.callMethod("get_Item",["two"]),2)
dnAssert("a key that is there",oMap.callMethod("Contains",["one"]),True)

# a sorted set keeps its items in order
oSorted = dnNewGeneric("C5.TreeSet",[cInt],[])
for nValue in [5,1,9,3,7]
	oSorted.callMethod("Add",[nValue])
next
dnAssert("a sorted set: the smallest",oSorted.callMethod("FindMin",[]),1)
dnAssert("a sorted set: the largest",oSorted.callMethod("FindMax",[]),9)
dnAssert("a sorted set: the count",oSorted.getProp("Count"),5)

# a priority queue
oQueue = dnNewGeneric("C5.IntervalHeap",[cInt],[])
for nValue in [42,7,19,3]
	oQueue.callMethod("Add",[nValue])
next
dnAssert("a queue: the smallest is first",oQueue.callMethod("DeleteMin",[]),3)
dnAssert("a queue: the next smallest",oQueue.callMethod("DeleteMin",[]),7)
dnAssert("a queue: the largest",oQueue.callMethod("DeleteMax",[]),42)
dnAssert("a queue: the count",oQueue.getProp("Count"),1)

dnTestSummary()
