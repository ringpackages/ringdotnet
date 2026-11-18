# Tutorial 19: callbacks and events - giving Ring code to .NET
load "../../libraries/dotnetlib/dotnetlib.ring"
using {
	"System.Collections.Generic"
	"System.Collections.ObjectModel"
}

# Callback code can only see global variables
nLetters = 0
nChanges = 0

func main
	oWords = new StringList()
	oWords.Add("pear")  oWords.Add("apple")  oWords.Add("fig")  oWords.Add("avocado")

	# 1. A callback that is the NAME of a function. .NET calls it once for each item.
	? "1. ForEach calls showItem for every word:"
	oWords.ForEach_(dnCallback("showItem"))

	# 2. A callback that decides: sort with your own comparison
	oWords.Sort([ :comparison = dnCallback("compareLength") ])
	? nl + "2. Sorted by length: " + joinList(oWords.toList())

	# 3. A callback that answers yes or no: find the words that start with a
	oFound = oWords.FindAll(dnCallback("startsWithA"))
	? "3. Words starting with a: " + joinList(oFound.toList())
	? "   Does 'fig' exist?   : " + oWords.Exists(dnCallback("isFig"))

	# 4. A callback that is a piece of CODE in a text. aDotNetArgs holds the arguments, xDotNetResult is the answer
	oWords.ForEach_(dnCallback("nLetters += len(aDotNetArgs[1])"))
	? "4. Total letters: " + nLetters
	oWords.Sort([ :comparison = dnCallback("xDotNetResult = len(aDotNetArgs[2]) - len(aDotNetArgs[1])") ])
	? "   Longest word : " + oWords.Item(0)

	# 5. An EVENT: .NET calls your code when something happens
	oList = new ObservableStringList()
	oList.setCollectionChangedEvent("nChanges++ ? '   event ' + nChanges + ': ' + aDotNetArgs[2].getProp('Action')")
	? nl + "5. Changing an observable list:"
	oList.Add("one")
	oList.Add("two")
	oList.RemoveAt(0)
	? "   events received: " + nChanges
	oList.clearCollectionChangedEvent()
	oList.Add("three")
	? "   after clearing the handler, still " + nChanges

	# 6. An error inside a callback comes out of the .NET method that called it
	try
		oWords.ForEach_(dnCallback("broken"))
	catch
		? nl + "6. Caught: " + cCatchError
	done

# A callback written as a function receives ONE parameter: the list of the .NET arguments. It returns the answer.
func showItem aArgs
	? "   item: " + aArgs[1]

func compareLength aArgs
	return len(aArgs[1]) - len(aArgs[2])

func startsWithA aArgs
	return left(aArgs[1],1) = "a"

func isFig aArgs
	return aArgs[1] = "fig"

func broken aArgs
	raise("the callback failed on purpose")

func joinList aList
	cText = ""
	for xItem in aList
		if cText != ""
			cText += ", "
		ok
		cText += xItem
	next
	return cText
