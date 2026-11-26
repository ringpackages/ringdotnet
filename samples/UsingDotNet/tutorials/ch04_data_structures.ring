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
	oTasks = new PriorityQueue([ :typeArguments = [cText,cInt] ])
	oTasks.Enqueue("write the report",3)
	oTasks.Enqueue("fix the server",1)
	oTasks.Enqueue("answer the mail",5)
	oTasks.Enqueue("call the customer",2)
	? "1. " + oTasks.Count + " tasks, most urgent first:"
	while oTasks.Count > 0
		? "   " + oTasks.Dequeue()
	end

	# 2. SortedSet: no duplicates, always sorted. Add answers false for a value that is already there. Min and Max are ready.
	oSet = new SortedSet([ :typeArguments = [cInt] ])
	for n in [42,7,19,7,3,42,100]
		oSet.Add(n)
	next
	? nl + "2. sorted set of 7 numbers with duplicates: " + oSet.Count + " kept, from " + oSet.Min + " to " + oSet.Max
	? "   in order: " + list2str2(oSet.toList())
	? "   Contains(19): " + oSet.Contains(19) + ", Contains(20): " + oSet.Contains(20)

	# 3. SortedDictionary: keys stay in order, so a loop over it is alphabetical
	oDict = new SortedDictionary([ :typeArguments = [cText,cInt] ])
	for cName in ["pear","apple","fig","banana"]
		oDict.Add(cName,len(cName))
	next
	cKeys = ""
	aKeys = oDict.Keys.toList()
	for cKey in aKeys
		cKeys += cKey + " "
	next
	? nl + "3. sorted dictionary, keys in order: " + cKeys

	# 4. LinkedList: items are linked to their neighbors. Adding or removing at either end, or next to a known node, is quick.
	oList = new LinkedList([ :typeArguments = [cText] ])
	oList.AddLast("b")
	oList.AddLast("c")
	oList.AddFirst("a")
	oNodeB = oList.First.@Next
	oList.AddAfter(oNodeB,"b2")
	? nl + "4. linked list: " + list2str2(oList.toList()) + " (first = " + oList.First.Value + ", last = " + oList.Last.Value + ")"
	oList.Remove("b")
	? "   after Remove(b): " + list2str2(oList.toList())

	# 5. BitArray: one bit for each item, so a million yes/no values take 125 KB. Set, Get and the logic methods And, Or, Xor, Not.
	#    (Get, And and Or are Ring words, so their names start with @. And and Or change the array they are called on.)
	oBits = new BitArray(10)
	oBits.Set(1,True)
	oBits.Set(3,True)
	oBits.Set(4,True)
	oOther = new BitArray(10)
	oOther.Set(3,True)
	oOther.Set(9,True)
	? nl + "5. bits:  " + bitText(oBits)
	? "   other: " + bitText(oOther)
	? "   AND:   " + bitText(copyBits(oBits).@And(oOther))
	? "   OR:    " + bitText(copyBits(oBits).@Or(oOther))

func copyBits oBits

	return new BitArray(oBits)

func bitText oBits

	cText = ""
	for i = 0 to oBits.Length - 1
		if oBits.@Get(i) cText += "1" else cText += "0" ok
	next
	return cText

func list2str2 aList

	cText = ""
	for item in aList
		cText += "" + item + " "
	next
	return cText
