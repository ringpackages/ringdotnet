# Nito.Collections.Deque: a double ended queue (add and remove at both ends, by index, insert, reverse), with a closed generic type
load "pkg.ring"
pkgUse("deque",[["Nito.Collections.Deque","1.2.1"]],[["Nito.Collections.Deque.dll",["Nito.Collections"]]])
pkgImport("deque","Nito.Collections.Deque.dll","Nito.Collections")

oDeque = dnNewGeneric("Nito.Collections.Deque",["System.Int32"],[])
dnAssert("a new deque is empty",oDeque.getProp("Count"),0)
oDeque.callMethod("AddToBack",[2])
oDeque.callMethod("AddToBack",[3])
oDeque.callMethod("AddToFront",[1])
oDeque.callMethod("AddToFront",[0])
dnAssert("four items",oDeque.getProp("Count"),4)
dnAssert("the first item",oDeque.callMethod("get_Item",[0]),0)
dnAssert("the last item",oDeque.callMethod("get_Item",[3]),3)
dnAssert("the items in order",list2str(oDeque.toList()),"0" + nl + "1" + nl + "2" + nl + "3")

dnAssert("remove from the front",oDeque.callMethod("RemoveFromFront",[]),0)
dnAssert("remove from the back",oDeque.callMethod("RemoveFromBack",[]),3)
dnAssert("two items are left",oDeque.getProp("Count"),2)

oDeque.callMethod("Insert",[1,99])
dnAssert("an item inserted in the middle",list2str(oDeque.toList()),"1" + nl + "99" + nl + "2")
oDeque.callMethod("RemoveAt",[1])
dnAssert("an item removed from the middle",list2str(oDeque.toList()),"1" + nl + "2")
dnAssert("a value is found",oDeque.callMethod("Contains",[2]),True)
dnAssert("the index of a value",oDeque.callMethod("IndexOf",[2]),1)
oDeque.callMethod("Clear",[])
dnAssert("a cleared deque is empty",oDeque.getProp("Count"),0)

# a deque of text used as a queue and as a stack
oText = dnNewGeneric("Nito.Collections.Deque",["System.String"],[])
for cWord in ["one","two","three"]
	oText.callMethod("AddToBack",[cWord])
next
dnAssert("a queue gives the oldest first",oText.callMethod("RemoveFromFront",[]),"one")
dnAssert("a stack gives the newest first",oText.callMethod("RemoveFromBack",[]),"three")

# removing from an empty deque is an error
oEmpty = dnNewGeneric("Nito.Collections.Deque",["System.Int32"],[])
lError = 0
try
	oEmpty.callMethod("RemoveFromFront",[])
catch
	lError = 1
done
dnAssert("removing from an empty deque raises an error",lError,1)

# an index that is out of range is an error
lError = 0
try
	oEmpty.callMethod("get_Item",[5])
catch
	lError = 1
done
dnAssert("an index out of range raises an error",lError,1)

dnTestSummary()
