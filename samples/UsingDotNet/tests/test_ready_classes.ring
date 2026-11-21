# The ready classes of the closed generic types (StringList, NumberDictionary, ObjectList ...): each one can be made with and without
# parentheses, and the result is a real .NET object (a handle), not an empty Ring list or a null.
load "dotnet.ring"
using {
	"System"
	"System.Collections.Generic"
	"System.Collections.Concurrent"
	"System.Collections.ObjectModel"
}

func main
	aNames = ["BlockingObjectCollection","ConcurrentObjectBag","ConcurrentObjectDictionary","ConcurrentObjectQueue","ConcurrentObjectStack",
		"ConcurrentStringDictionary","ConcurrentStringQueue","IntList","NumberDictionary","NumberKeyDictionary","NumberList","NumberSet",
		"ObjectDictionary","ObjectLinkedList","ObjectList","ObjectQueue","ObjectStack","ObservableObjectList","ObservableStringList",
		"SortedNumberSet","SortedObjectDictionary","SortedObjectList","SortedStringDictionary","SortedStringSet","StringCollectionList",
		"StringDictionary","StringLinkedList","StringList","StringPriorityQueue","StringQueue","StringSet","StringStack"]
	for cName in aNames
		eval("oPlain = new " + cName)
		dnAssert(cName + " without parentheses is an object",isobject(oPlain) and oPlain.nHandle > 0,True)
		eval("oParens = new " + cName + "()")
		dnAssert(cName + " with parentheses is an object",isobject(oParens) and oParens.nHandle > 0,True)
	next

	# a few of them used: the object keeps what is put into it
	oObjects = new ObjectList()
	oObjects.Add(1)
	oObjects.Add("two")
	dnAssert("ObjectList.Count",oObjects.Count,2)
	oMap = new ObjectDictionary()
	oMap.SetItem("k",5)
	dnAssert("ObjectDictionary.Item",oMap.Item("k"),5)
	oQueue = new ObjectQueue()
	oQueue.Enqueue("a")
	dnAssert("ObjectQueue.Dequeue",oQueue.Dequeue(),"a")
	dnTestSummary()
