# Ring in 15 minutes, part 2: lists (the only collection), pairs, nested lists

# 1. A list holds anything. Indexes start at 1. "+" adds an item at the end.
aNames = ["Ann","Bob","Cy"]
aNames + "Dee"
? len(aNames)
? aNames[1] + " " + aNames[len(aNames)]
aNames[2] = "Rob"             # change an item
? aNames

# 2. Walk a list with for ... in. The item is a copy: change the list by index.
for cName in aNames
	? "hello " + cName
next
for nIndex = 1 to len(aNames)
	aNames[nIndex] = upper(aNames[nIndex])
next
? aNames

# 3. Search, insert, delete, sort
? find(aNames,"CY")           # the position (0: not found)
insert(aNames,0,"First")      # insert after position 0 = at the start
del(aNames,2)                 # delete the item at position 2
? aNames
aNumbers = [30,5,12,8]
? sort(aNumbers)              # sort() gives a NEW sorted list; aNumbers itself does not change
? aNumbers[1]
? sort(["pear","apple","fig"])

# 4. A list of [name, value] pairs is Ring's dictionary: a text key reads the value. :name is the text "name".
aPerson = [ :name = "Ann", :age = 31, :city = "Cairo" ]
? aPerson[:name]
? aPerson[:age] + 1
aPerson[:age] = 32
aPerson[:email] = "ann@example.com"    # a new key is added
? len(aPerson)
for aPair in aPerson
	? aPair[1] + " = " + aPair[2]
next
? aPerson[:phone]             # a key that is not there reads as "" (it does not raise an error)

# 5. Lists inside lists: a table. aTable[row][column]
aTable = [ ["Ann",31], ["Bob",25], ["Cy",40] ]
? aTable[2][1] + " is " + aTable[2][2]
aTable + ["Dee",19]
nTotal = 0
for aRow in aTable
	nTotal += aRow[2]
next
? "total age: " + nTotal

# 6. A list assigned to another variable is COPIED. A list passed to a function is the same list: the function changes the original.
aCopy = aNumbers
aCopy[1] = 999
? aNumbers[1]                 # still 30
addOne(aNumbers)
? aNumbers[1]                 # 31: the function worked on the original

func addOne aList
	aList[1] = aList[1] + 1
