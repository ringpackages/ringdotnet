# Collections of the .NET class library: dictionaries and the specialized and generic collections
load "dotnet.ring"
using {
	"System.Collections"
	"System.Collections.Specialized"
	"System.Collections.Generic"
}

# Word frequency with Dictionary<string,double> (entries are wrapped KeyValuePair objects)
oCount = new NumberDictionary()
for cWord in split("the quick brown fox jumps over the lazy dog the end"," ")
	aGot = oCount.TryGetValue(cWord)
	nOld = 0
	if aGot[1] nOld = aGot[2] ok
	oCount.SetItem(cWord,nOld + 1)
next
? "Distinct words : " + oCount.Count
? "'the' appears  : " + oCount.Item("the") + " times"
for oPair in oCount.toList()
	if oPair.Value > 1 ? "  " + oPair.Key + " = " + oPair.Value ok
next

# Sorted collections and a priority queue
oSet = new SortedStringSet()
for cName in ["pear","apple","fig","apple","banana"] oSet.Add(cName) next
? "Sorted set     : " + list2str(oSet.toList()) 
oTasks = new StringPriorityQueue()
oTasks.Enqueue("write docs",3)  oTasks.Enqueue("fix bug",1)  oTasks.Enqueue("release",2)
? "Next task      : " + oTasks.Dequeue()
? "Then           : " + oTasks.Dequeue()

# Non-generic and specialized collections
oList = new ArrayList()
oList.Add(3)  oList.Add(1)  oList.Add(2)
oList.Sort(NULL)
? "ArrayList      : " + oList.Item(0) + oList.Item(1) + oList.Item(2)
oQuery = new NameValueCollection()
oQuery.Add([ :name = "tag", :value = "ring" ])  oQuery.Add([ :name = "tag", :value = "dotnet" ])  oQuery.Add([ :name = "page", :value = "2" ])
? "Query values   : " + oQuery.Item("tag") + " | " + oQuery.Item("page")

func split cText, cSep
	return str2list(substr(cText,cSep,nl))
