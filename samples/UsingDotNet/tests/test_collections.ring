# Batch: System.Collections, System.Collections.Specialized, System.Collections.Generic (closed types), ObjectModel
load "dotnet.ring"
dnImport("System.Collections")
dnImport("System.Collections.Specialized")
dnImport("System.Collections.Generic")
dnImport("System.Collections.ObjectModel")
dnImport("System.Text")

# Non-generic collections
oArr = new ArrayList()
oArr.Add("pear")  oArr.Add("apple")  oArr.Add("fig")
oArr.Sort(NULL)
dnAssert("ArrayList sorted",oArr.Item(0),"apple")
dnAssert("ArrayList.Count",oArr.Count,3)
dnAssert("ArrayList.IndexOf",oArr.IndexOf("fig"),1)
dnAssert("ArrayList.Contains",oArr.Contains("pear"),1)
oArr.RemoveAt(0)
dnAssert("ArrayList.RemoveAt",oArr.Count,2)

oHash = new Hashtable()
oHash.Add("one",1)
oHash.SetItem("two",2)
dnAssert("Hashtable.Count",oHash.Count,2)
dnAssert("Hashtable.Item",oHash.Item("two"),2)
dnAssert("Hashtable.ContainsKey",oHash.ContainsKey("one"),1)
dnAssert("Hashtable.Keys",oHash.Keys.getProp("Count"),2)

oBits = new BitArray(8)
oBits.SetItem(3,1)
dnAssert("BitArray.Item",oBits.Item(3),1)
dnAssert("BitArray.Length",oBits.Length,8)

oQ = new Queue()
oQ.Enqueue("a")  oQ.Enqueue("b")
dnAssert("Queue.Dequeue",oQ.Dequeue(),"a")

# Specialized
oNames = new NameValueCollection()
oNames.Add([ :name = "color", :value = "red" ])
oNames.Add([ :name = "color", :value = "blue" ])
oNames.Add([ :name = "size", :value = "L" ])
dnAssert("NameValueCollection.Count",oNames.Count,2)
dnAssert("NameValueCollection.Item",oNames.Item("color"),"red,blue")
dnAssert("NameValueCollection.GetValues",len(oNames.GetValues("color").toList()),2)
oOrdered = new OrderedDictionary()
oOrdered.Add("z",1)  oOrdered.Add("a",2)
dnAssert("OrderedDictionary first key",oOrdered.Keys.toList()[1],"z")
oStrs = new StringCollection()
oStrs.Add("x")
dnAssert("StringCollection",oStrs.Count,1)

# Generic closed types
oInts = new IntList()
for nLoop = 1 to 5 oInts.Add(nLoop * 10) next
dnAssert("IntList.Count",oInts.Count,5)
dnAssert("IntList.Item",oInts.Item(2),30)
dnAssert("IntList.Contains",oInts.Contains(50),1)
oInts.Reverse(NULL)
dnAssert("IntList.Reverse",oInts.Item(0),50)
dnAssert("IntList.IndexOf",oInts.IndexOf(10),4)

oSorted = new SortedStringDictionary()
oSorted.Add("b","2")  oSorted.Add("a","1")
dnAssert("SortedDictionary order",oSorted.Keys.toList()[1],"a")

oSet = new SortedNumberSet()
oSet.Add(5)  oSet.Add(1)  oSet.Add(3)  oSet.Add(3)
dnAssert("SortedSet.Count",oSet.Count,3)
dnAssert("SortedSet.Min",oSet.Min,1)
dnAssert("SortedSet.Max",oSet.Max,5)

oPQ = new StringPriorityQueue()
oPQ.Enqueue("low",9)  oPQ.Enqueue("high",1)  oPQ.Enqueue("mid",5)
dnAssert("PriorityQueue.Dequeue",oPQ.Dequeue(),"high")
dnAssert("PriorityQueue.Count",oPQ.Count,2)

oLinked = new StringLinkedList()
oLinked.AddLast("b")  oLinked.AddFirst("a")  oLinked.AddLast("c")
dnAssert("LinkedList.Count",oLinked.Count,3)
dnAssert("LinkedList.First.Value",oLinked.First.getProp("Value"),"a")
dnAssert("LinkedList.Last.Value",oLinked.Last.getProp("Value"),"c")

# List<object> is the one closed type that the bridge also uses for its own lists: an object that a program makes must stay an object
oAny = new ObjectList()
oAny.Add(1)  oAny.Add("two")  oAny.Add(new StringBuilder("three"))
dnAssert("ObjectList is an object",isobject(oAny),1)
dnAssert("ObjectList.Count",oAny.Count,3)
dnAssert("ObjectList.Item",oAny.Item(1),"two")
dnAssert("ObjectList keeps an object",oAny.Item(2).ToString(),"three")

oStack = new ObjectStack()
oStack.Push(1)  oStack.Push("two")
dnAssert("Stack.Pop",oStack.Pop(),"two")
dnAssert("Stack.Peek",oStack.Peek(),1)

# Dictionary entries are wrapped KeyValuePair classes
oDict = new NumberDictionary()
oDict.Add("pi",3.14)
aPairs = oDict.toList()
dnAssert("pair class",classname(aPairs[1]),"numberpair")
dnAssert("pair key",aPairs[1].Key,"pi")
dnAssert("pair value",aPairs[1].Value,3.14)
aGot = oDict.TryGetValue("pi")
dnAssert("TryGetValue",aGot[2],3.14)

# Object model
oObs = new ObservableObjectList()
nAdded = 0
oObs.setCollectionChangedEvent("nAdded++")
oObs.Add(1)  oObs.Add("two")
dnAssert("ObservableCollection events",nAdded,2)
dnAssert("ObservableCollection.Count",oObs.Count,2)

# generic collections made with :typeArguments: the methods of a type parameter are called without a request text when the real type takes them (a text, a number, a yes/no),
# and by the general request for any other type, with the same answers
oTexts = new List([ :typeArguments = ["System.String"] ])
oTexts.Add("pear")  oTexts.Add("apple")  oTexts.Insert(1,"fig")
dnAssert("List<string>.Item",oTexts.Item(1),"fig")
dnAssert("List<string>.Contains",oTexts.Contains("apple"),True)
dnAssert("List<string>.Contains, a text that is not there",oTexts.Contains("kiwi"),False)
dnAssert("List<string>.IndexOf",oTexts.IndexOf("apple"),2)
dnAssert("List<string>.Remove",oTexts.Remove("fig"),True)
oTexts.SetItem(0,"plum")
dnAssert("List<string>.SetItem",oTexts.Item(0),"plum")
dnAssert("List<string>.Count",oTexts.Count,2)
oInts = new List([ :typeArguments = ["System.Int32"] ])
oInts.Add(30)  oInts.Add(10)  oInts.Add(20)
dnAssert("List<int>.Item",oInts.Item(2),20)
dnAssert("List<int>.Contains",oInts.Contains(10),True)
dnAssert("List<int>.IndexOf",oInts.IndexOf(20),2)
lRefused = False
try
	oInts.Add("not a number")
catch
	lRefused = True
done
dnAssert("List<int>.Add with a text is refused by .NET",lRefused,True)
oDoubles = new List([ :typeArguments = ["System.Double"] ])
oDoubles.Add(2.5)
dnAssert("List<double>.Item",oDoubles.Item(0),2.5)
oObjects = new List([ :typeArguments = ["System.Object"] ])
oObjects.Add("text")  oObjects.Add(42)  oObjects.Add(new Uri("http://example.com/a"))
dnAssert("List<object>.Item, a text",oObjects.Item(0),"text")
dnAssert("List<object>.Item, a number",oObjects.Item(1),42)
dnAssert("List<object>.Item, an object keeps its class",oObjects.Item(2).Host,"example.com")
dnAssert("List<object>.Contains",oObjects.Contains(42),True)
oAges = new Dictionary([ :typeArguments = ["System.String","System.Int32"] ])
oAges.Add("ann",31)  oAges.Add("bob",25)
dnAssert("Dictionary<string,int>.Item",oAges.Item("bob"),25)
dnAssert("Dictionary<string,int>.ContainsKey",oAges.ContainsKey("ann"),True)
oAges.SetItem("ann",32)
dnAssert("Dictionary<string,int>.SetItem",oAges.Item("ann"),32)
dnAssert("Dictionary<string,int>.Remove",oAges.Remove("bob"),True)
dnAssert("Dictionary<string,int>.Count",oAges.Count,1)
oQueue = new Queue1([ :typeArguments = ["System.String"] ])
oQueue.Enqueue("first")  oQueue.Enqueue("second")
dnAssert("Queue<string>.Peek",oQueue.Peek(),"first")
dnAssert("Queue<string>.Dequeue",oQueue.Dequeue(),"first")
oStack = new Stack1([ :typeArguments = ["System.Int32"] ])
oStack.Push(7)  oStack.Push(8)
dnAssert("Stack<int>.Pop",oStack.Pop(),8)
dnAssert("Stack<int>.Peek",oStack.Peek(),7)

# the event arguments are an object of their own class: the action and the items
cActions = ""
oAction = new ObservableObjectList()
oAction.setCollectionChangedEvent("cActions += aDotNetArgs[2].Action + ' ' + aDotNetArgs[2].NewItems.Count + ';'")
oAction.Add("a")
dnAssert("the event arguments have their class",cActions,"Add 1;")

nFail = dnTestSummary()
