# An object that comes back as an interface (Hashtable.Keys is an ICollection) has the members that the interface inherits from other
# interfaces: GetEnumerator is a member of IEnumerable, and ICollection inherits it.
load "dotnet.ring"

using { "System.Collections" }

func main

	oTable = new Hashtable
	oTable.Add("a",1)
	oKeys = oTable.Keys
	dnAssert("the keys come back as the interface ICollection",classname(oKeys),"icollection")
	dnAssert("a member of ICollection",oKeys.Count,1)
	oEnumerator = oKeys.GetEnumerator()
	dnAssert("a member that ICollection inherits from IEnumerable",oEnumerator.MoveNext(),1)
	dnAssert("the enumerator reads the key",oEnumerator.Current,"a")
	dnTestSummary()
