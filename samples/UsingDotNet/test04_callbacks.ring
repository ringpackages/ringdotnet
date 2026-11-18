load "dotnet.ring"
using { "System.Collections.Generic" }

oList = new StringList()
oList.Add("pear")  oList.Add("apple")  oList.Add("fig")  oList.Add("avocado")

? "ForEach (Action<string>):"
oList.ForEach_(dnCallback("printItem"))

? "Sort by length (Comparison<string>):"
oList.Sort([ :comparison = dnCallback("compareLength") ])
for cItem in oList.toList() ? "  " + cItem next

? "FindAll starting with a (Predicate<string>):"
oFound = oList.FindAll(dnCallback("startsWithA"))
for cItem in oFound.toList() ? "  " + cItem next
? "Exists(startsWithA) = " + oList.Exists(dnCallback("startsWithA"))

# Callbacks can be any Ring code (as in RingQt events): aDotNetArgs holds the arguments, xDotNetResult the result
nTotal = 0
oList.ForEach_(dnCallback("nTotal += len(aDotNetArgs[1])"))
? "Total letters (inline code): " + nTotal
oList.Sort([ :comparison = dnCallback("xDotNetResult = len(aDotNetArgs[2]) - len(aDotNetArgs[1])") ])
? "Longest first: " + oList.Item(0)
oNums = new NumberList()
for nLoop = 1 to 6 oNums.Add(nLoop) next
? "Even numbers: " + list2str(oNums.FindAll(dnCallback("xDotNetResult = (aDotNetArgs[1] % 2 = 0)")).toList())

# Errors in the callback reach the caller
try
	oList.ForEach_(dnCallback("broken"))
catch
	? "Caught: " + cCatchError
done

# A callback receives ONE parameter: the list of the .NET arguments, and returns the result

func printItem aArgs
	? "  item: " + aArgs[1]

func compareLength aArgs
	return len(aArgs[1]) - len(aArgs[2])

func startsWithA aArgs
	return left(aArgs[1],1) = "a"

func broken aArgs
	raise("callback failed on purpose")
