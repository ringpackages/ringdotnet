# more data structures - PriorityQueue, SortedSet, SortedDictionary, LinkedList and BitArray
load "dotnet.ring"
using {
	"System"
	"System.Collections"
	"System.Collections.Generic"
}

func main
	cInt = "System.Int32"
	cText = "System.String"

	# 1. PriorityQueue<element, priority>: Dequeue always gives the element with the SMALLEST priority, whatever the order of Enqueue.
	oTasks = dnNewGeneric("System.Collections.Generic.PriorityQueue",[cText,cInt],[])
	oTasks.callMethod("Enqueue",["write the report",3])
	oTasks.callMethod("Enqueue",["fix the server",1])
	oTasks.callMethod("Enqueue",["answer the mail",5])
	oTasks.callMethod("Enqueue",["call the customer",2])
	? "1. " + oTasks.getProp("Count") + " tasks, most urgent first:"
	while oTasks.getProp("Count") > 0
		? "   " + oTasks.callMethod("Dequeue",[])
	end

	# 2. SortedSet: no duplicates, always sorted. Add answers false for a value that is already there. Min and Max are ready.
	oSet = dnNewGeneric("System.Collections.Generic.SortedSet",[cInt],[])
	for n in [42,7,19,7,3,42,100]
		oSet.callMethod("Add",[n])
	next
	? nl + "2. sorted set of 7 numbers with duplicates: " + oSet.getProp("Count") + " kept, from " + oSet.getProp("Min") + " to " + oSet.getProp("Max")
	? "   in order: " + list2str2(oSet.toList())
	? "   Contains(19): " + oSet.callMethod("Contains",[19]) + ", Contains(20): " + oSet.callMethod("Contains",[20])

	# 3. SortedDictionary: keys stay in order, so a loop over it is alphabetical
	oDict = dnNewGeneric("System.Collections.Generic.SortedDictionary",[cText,cInt],[])
	for cName in ["pear","apple","fig","banana"]
		oDict.callMethod("Add",[cName,len(cName)])
	next
	cKeys = ""
	for cKey in oDict.getProp("Keys").toList()
		cKeys += cKey + " "
	next
	? nl + "3. sorted dictionary, keys in order: " + cKeys

	# 4. LinkedList: items are linked to their neighbours. Adding or removing at either end, or next to a known node, is quick.
	oList = dnNewGeneric("System.Collections.Generic.LinkedList",[cText],[])
	oList.AddLast("b")
	oList.AddLast("c")
	oList.AddFirst("a")
	oNodeB = oList.First.getProp("Next")
	oList.AddAfter(oNodeB,"b2")
	? nl + "4. linked list: " + list2str2(oList.toList()) + " (first = " + oList.First.getProp("Value") + ", last = " + oList.Last.getProp("Value") + ")"
	oList.Remove("b")
	? "   after Remove(b): " + list2str2(oList.toList())

	# 5. BitArray: one bit for each item, so a million yes/no values take 125 KB. Set, Get and the logic methods And, Or, Xor, Not.
	#    (Get, And and Or are reserved words after a dot, so they are called with callMethod. And and Or change the array they are called on.)
	oBits = new BitArray(10)
	oBits.Set(1,True)
	oBits.Set(3,True)
	oBits.Set(4,True)
	oOther = new BitArray(10)
	oOther.Set(3,True)
	oOther.Set(9,True)
	? nl + "5. bits:  " + bitText(oBits)
	? "   other: " + bitText(oOther)
	? "   AND:   " + bitText(dnCopyBits(oBits).callMethod("And",[oOther]))
	? "   OR:    " + bitText(dnCopyBits(oBits).callMethod("Or",[oOther]))

func dnCopyBits oBits
	return new BitArray(oBits)

func bitText oBits
	cText = ""
	for i = 0 to oBits.Length - 1
		if oBits.callMethod("Get",[i]) cText += "1" else cText += "0" ok
	next
	return cText

func list2str2 aList
	cText = ""
	for item in aList
		cText += "" + item + " "
	next
	return cText
