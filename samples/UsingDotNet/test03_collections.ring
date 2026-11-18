load "dotnet.ring"
using { "System.Collections.Generic" }

# List<string>
oList = new StringList() {
	Add("banana")
	Add("apple")
	Add("cherry")
}
oList.Sort(NULL)
? "Count = " + oList.getCount()
? "First = " + oList.Item(0)
oList.SetItem(0,"avocado")
? "Contains(apple) = " + oList.Contains("apple")
for cItem in oList.toList()
	? "  " + cItem
next

# List<double>
oNums = new NumberList()
for nLoop = 1 to 5
	oNums.Add(nLoop * nLoop)
next
? "Numbers : " + list2str(oNums.toList())

# Dictionary<string,string>
oDict = new StringDictionary()
oDict.Add("one","1")
oDict.SetItem("two","2")
? "Dict count = " + oDict.getCount()
? "two = " + oDict.Item("two")
? "has one = " + oDict.ContainsKey("one")
? "keys = " + list2str(oDict.getKeys().toList())

# Dictionary<string,object> (numbers and strings)
oObj = new ObjectDictionary()
oObj.SetItem("pi",3.14159)
oObj.SetItem("name","Ring")
? string(oObj.Item("pi")) + " " + oObj.Item("name")

# Set, Queue, Stack
oSet = new StringSet()
oSet.Add("a") oSet.Add("b") oSet.Add("a")
? "Set count = " + oSet.getCount()
oQ = new StringQueue()
oQ.Enqueue("first") oQ.Enqueue("second")
? "Dequeue = " + oQ.Dequeue()
oS = new StringStack()
oS.Push("bottom") oS.Push("top")
? "Pop = " + oS.Pop()
