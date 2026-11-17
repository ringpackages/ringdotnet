# Batch: System.Collections, System.Collections.Specialized, System.Collections.Generic (closed types), ObjectModel
load "../libraries/dotnetlib/dotnetlib.ring"
dnImport("System.Collections")
dnImport("System.Collections.Specialized")
dnImport("System.Collections.Generic")
dnImport("System.Collections.ObjectModel")

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
oNames.Add("color","red")
oNames.Add("color","blue")
oNames.Add("size","L")
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

nFail = dnTestSummary()
