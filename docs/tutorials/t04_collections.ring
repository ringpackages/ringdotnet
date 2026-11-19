# collections and LINQ - lists, dictionaries, sets, queues, sorting and querying
load "dotnet.ring"
using {
	"System.Collections.Generic"
	"System.Linq"
}

func main
	# A list keeps items in order
	oFruit = new StringList()
	oFruit.Add("banana")
	oFruit.Add("apple")
	oFruit.Add("cherry")
	? "Count             : " + oFruit.Count
	? "Second item       : " + oFruit.Item(1)
	oFruit.Sort(NULL)
	? "After Sort        : " + list2str(oFruit.toList())
	? "Contains apple    : " + oFruit.Contains("apple")
	? "Index of cherry   : " + oFruit.IndexOf("cherry")

	# A dictionary maps keys to values
	oAges = new NumberDictionary()
	oAges.SetItem("Ann",31)
	oAges.SetItem("Bob",17)
	? "Ann is            : " + oAges.Item("Ann")
	aFound = oAges.TryGetValue("Cy")
	? "Is Cy known?      : " + aFound[1]
	? "Keys              : " + oAges.Count + " keys"

	# A set holds each value once
	oSet = new StringSet()
	oSet.Add("red") oSet.Add("green") oSet.Add("red")
	? "Set size          : " + oSet.Count + " (red was added twice)"

	# A queue is first-in first-out, a stack is last-in first-out
	oQueue = new StringQueue()
	oQueue.Enqueue("first") oQueue.Enqueue("second")
	? "Queue gives       : " + oQueue.Dequeue()
	oStack = new StringStack()
	oStack.Push("first") oStack.Push("second")
	? "Stack gives       : " + oStack.Pop()

	# LINQ asks questions about a collection: the code of each question is Ring code
	aSales = [120, 45, 300, 15, 210, 99, 81]
	aBig = dnQuery(aSales).Where("xDotNetResult = aDotNetArgs[1] >= 100").OrderByDescending("xDotNetResult = aDotNetArgs[1]").ToList()
	? "Sales >= 100      : " + joinList(aBig)
	? "Count, sum, max   : " + dnQuery(aSales).Count() + ", " + dnQuery(aSales).Sum("") + ", " + dnQuery(aSales).Max("")
	? "Any over 250?     : " + dnQuery(aSales).Any("xDotNetResult = aDotNetArgs[1] > 250")
	? "Average           : " + dnQuery(aSales).Average("")

# the items of a Ring list on one line
func joinList aList
	cText = ""
	for xItem in aList
		if cText != ""
			cText += ", "
		ok
		cText += xItem
	next
	return cText
